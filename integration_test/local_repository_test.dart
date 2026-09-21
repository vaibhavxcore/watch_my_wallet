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
}
