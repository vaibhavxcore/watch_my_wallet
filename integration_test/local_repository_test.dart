import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:watch_my_wallet/data/local/local_database.dart';
import 'package:watch_my_wallet/data/models/local_entities.dart';
import 'package:watch_my_wallet/data/repositories/transaction_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('local repository supports seeded offline transaction CRUD', (
    tester,
  ) async {
    await LocalDatabase.deleteDatabase();
    final database = await LocalDatabase.open(key: 'milestone-one-test-key');
    final repository = TransactionRepository(database);

    final accounts = await database.database.query('accounts');
    final categories = await database.database.query('categories');
    expect(accounts.map((row) => row['name']), contains('Cash'));
    expect(accounts.map((row) => row['name']), contains('Savings Account'));
    expect(categories, hasLength(18));

    final created = await repository.create(
      userId: 'guest',
      accountId: 'account_cash',
      categoryId: 'category_expense_food',
      amount: 250.50,
      type: LocalTransactionType.expense,
      note: 'Offline lunch',
      date: DateTime(2026, 9, 21),
    );
    expect(created.syncStatus, SyncStatus.pendingCreate);

    final visible = await repository.getAll();
    expect(visible, hasLength(1));
    expect(visible.single.note, 'Offline lunch');

    final updated = await repository.update(
      LocalTransaction(
        id: created.id,
        userId: created.userId,
        accountId: created.accountId,
        categoryId: created.categoryId,
        amount: created.amount,
        type: created.type,
        note: 'Updated lunch',
        date: created.date,
        createdAt: created.createdAt,
        updatedAt: created.updatedAt,
        syncStatus: created.syncStatus,
      ),
    );
    expect(updated.syncStatus, SyncStatus.pendingUpdate);

    final deleted = await repository.softDelete(updated);
    expect(deleted.syncStatus, SyncStatus.pendingDelete);
    expect(await repository.getAll(), isEmpty);

    final operations = await database.database.query('sync_operations');
    expect(operations, hasLength(3));
    expect(
      operations.map((operation) => operation['operation']),
      containsAll(<String>['create', 'update', 'delete']),
    );
    await database.close();
  });

  testWidgets('local database survives a close and reopen', (tester) async {
    final database = await LocalDatabase.open(key: 'milestone-one-test-key');
    final repository = TransactionRepository(database);
    final records = await repository.getAll();
    expect(records, isEmpty);
    final deletedRows = await database.database.query(
      'transactions',
      where: 'deleted_at IS NOT NULL',
    );
    expect(deletedRows, hasLength(1));
    await database.close();

    final reopened = await LocalDatabase.open(key: 'milestone-one-test-key');
    final persistedOperations = await reopened.database.query(
      'sync_operations',
    );
    expect(persistedOperations, hasLength(3));
    await reopened.close();
    await LocalDatabase.deleteDatabase();
  });

  testWidgets('local finance settings and recurring records persist', (
    tester,
  ) async {
    await LocalDatabase.deleteDatabase();
    final database = await LocalDatabase.open(key: 'milestone-one-test-key');
    final repository = TransactionRepository(database);

    final customCategory = await repository.createCategory(
      name: 'Pet care',
      type: LocalTransactionType.expense,
    );
    expect(
      (await repository.getCategories(
        type: LocalTransactionType.expense,
      )).map((category) => category.name),
      contains('Pet care'),
    );

    await repository.saveBudget(5000);
    await repository.saveCategoryBudget(
      categoryId: customCategory.id,
      amount: 750,
    );
    expect((await repository.getBudget())!.amount, 5000);
    expect((await repository.getCategoryBudgets()).single.amount, 750);

    final goal = await repository.saveSavingsGoal(
      name: 'Emergency fund',
      targetAmount: 10000,
      targetDate: DateTime(2027, 1, 1),
    );
    await repository.updateSavingsGoalAmount(goal: goal, currentAmount: 1200);
    expect((await repository.getSavingsGoals()).single.currentAmount, 1200);

    await repository.saveSetting('theme_mode', 'dark');
    expect(await repository.getSetting('theme_mode'), 'dark');

    final newAccount = await repository.createAccount(
      name: 'Travel fund',
      openingBalance: 250,
    );
    final updatedAccount = await repository.updateAccount(
      account: newAccount,
      name: 'Holiday fund',
      openingBalance: 300,
    );
    expect(
      (await repository.getAccounts()).map((account) => account.name),
      contains('Holiday fund'),
    );
    expect((await repository.getAccountBalances())[updatedAccount.id], 300);

    final now = DateTime.now().toUtc();
    await repository.create(
      userId: 'guest',
      accountId: 'account_cash',
      categoryId: 'category_income_salary',
      amount: 1000,
      type: LocalTransactionType.income,
      note: 'Payday',
      date: now,
    );
    await repository.create(
      userId: 'guest',
      accountId: 'account_cash',
      categoryId: customCategory.id,
      amount: 400,
      type: LocalTransactionType.expense,
      note: 'Vet visit',
      date: now,
    );
    await repository.create(
      userId: 'guest',
      accountId: 'account_cash',
      categoryId: customCategory.id,
      amount: 50,
      type: LocalTransactionType.expense,
      note: 'Weekly pet supplies',
      date: now.subtract(const Duration(days: 8)),
      isRecurring: true,
      frequency: 'weekly',
    );
    await repository.processRecurringTransactions();

    expect((await repository.getAccountBalances())['account_cash'], 500);
    expect(await repository.getAll(), hasLength(4));
    final recurringRows = await database.database.query(
      'recurring_transactions',
    );
    expect(recurringRows, hasLength(1));
    expect(
      DateTime.parse(
        recurringRows.single['next_occurrence']! as String,
      ).isAfter(now),
      isTrue,
    );

    await repository.archiveAccount(updatedAccount);
    expect(
      (await repository.getAccounts()).map((account) => account.id),
      isNot(contains(updatedAccount.id)),
    );

    await database.close();
    await LocalDatabase.deleteDatabase();
  });
}
