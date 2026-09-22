import 'dart:convert';

import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:watch_my_wallet/data/local/local_database.dart';
import 'package:watch_my_wallet/data/models/local_entities.dart';

class TransactionRepository {
  final LocalDatabase _localDatabase;

  const TransactionRepository(this._localDatabase);

  Future<List<LocalAccount>> getAccounts() async {
    final rows = await _localDatabase.database.query(
      'accounts',
      where: 'deleted_at IS NULL',
      orderBy: 'name ASC',
    );
    return rows.map(LocalAccount.fromMap).toList();
  }

  Future<List<LocalCategory>> getCategories({
    required LocalTransactionType type,
  }) async {
    final rows = await _localDatabase.database.query(
      'categories',
      where: 'type = ? AND deleted_at IS NULL',
      whereArgs: [type.name],
      orderBy: 'name ASC',
    );
    return rows.map(LocalCategory.fromMap).toList();
  }

  Future<LocalCategory> createCategory({
    required String name,
    required LocalTransactionType type,
  }) async {
    final now = DateTime.now().toUtc();
    final category = LocalCategory(
      id: 'category_custom_${now.microsecondsSinceEpoch}',
      name: name.trim(),
      type: type,
      isDefault: false,
      createdAt: now,
      updatedAt: now,
    );
    await _localDatabase.database.insert('categories', {
      'id': category.id,
      'name': category.name,
      'type': category.type.name,
      'is_default': 0,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
    return category;
  }

  String _monthKey([DateTime? date]) {
    final value = date ?? DateTime.now();
    return '${value.year}-${value.month.toString().padLeft(2, '0')}';
  }

  Future<LocalBudget?> getBudget({
    String userId = 'guest',
    DateTime? month,
  }) async {
    final rows = await _localDatabase.database.query(
      'budgets',
      where: 'user_id = ? AND month = ? AND deleted_at IS NULL',
      whereArgs: [userId, _monthKey(month)],
      limit: 1,
    );
    return rows.isEmpty ? null : LocalBudget.fromMap(rows.first);
  }

  Future<LocalBudget> saveBudget(
    double amount, {
    String userId = 'guest',
  }) async {
    final now = DateTime.now().toUtc();
    final month = _monthKey();
    final existing = await getBudget(userId: userId);
    final id = existing?.id ?? 'budget_${userId}_$month';
    await _localDatabase.database.insert('budgets', {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'month': month,
      'created_at': existing == null
          ? now.toIso8601String()
          : now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'sync_status': SyncStatus.pendingUpdate.name,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return LocalBudget(id: id, userId: userId, amount: amount, month: month);
  }

  Future<List<LocalCategoryBudget>> getCategoryBudgets({
    String userId = 'guest',
  }) async {
    final rows = await _localDatabase.database.query(
      'category_budgets',
      where: 'user_id = ? AND month = ? AND deleted_at IS NULL',
      whereArgs: [userId, _monthKey()],
    );
    return rows.map(LocalCategoryBudget.fromMap).toList();
  }

  Future<LocalCategoryBudget> saveCategoryBudget({
    required String categoryId,
    required double amount,
    String userId = 'guest',
  }) async {
    final now = DateTime.now().toUtc();
    final month = _monthKey();
    final id = 'category_budget_${userId}_${categoryId}_$month';
    await _localDatabase.database.insert('category_budgets', {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'month': month,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'sync_status': SyncStatus.pendingUpdate.name,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return LocalCategoryBudget(
      id: id,
      categoryId: categoryId,
      amount: amount,
      month: month,
    );
  }

  Future<Map<String, double>> getAccountBalances({
    String userId = 'guest',
  }) async {
    final rows = await _localDatabase.database.rawQuery(
      '''
      SELECT a.id, a.opening_balance + COALESCE(SUM(
        CASE WHEN t.type = 'income' THEN t.amount ELSE -t.amount END
      ), 0) AS balance
      FROM accounts a
      LEFT JOIN transactions t ON t.account_id = a.id
        AND t.deleted_at IS NULL AND t.user_id = ?
      WHERE a.deleted_at IS NULL
      GROUP BY a.id
    ''',
      [userId],
    );
    return {
      for (final row in rows)
        row['id']! as String: (row['balance']! as num).toDouble(),
    };
  }

  Future<List<LocalSavingsGoal>> getSavingsGoals({
    String userId = 'guest',
  }) async {
    final rows = await _localDatabase.database.query(
      'savings_goals',
      where: 'user_id = ? AND deleted_at IS NULL',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map(LocalSavingsGoal.fromMap).toList();
  }

  Future<LocalSavingsGoal> saveSavingsGoal({
    required String name,
    required double targetAmount,
    double currentAmount = 0,
    DateTime? targetDate,
    String userId = 'guest',
  }) async {
    final now = DateTime.now().toUtc();
    final id = 'goal_${now.microsecondsSinceEpoch}';
    await _localDatabase.database.insert('savings_goals', {
      'id': id,
      'user_id': userId,
      'name': name.trim(),
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate?.toUtc().toIso8601String(),
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
    return LocalSavingsGoal(
      id: id,
      name: name.trim(),
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      targetDate: targetDate,
    );
  }

  Future<LocalSavingsGoal> updateSavingsGoalAmount({
    required LocalSavingsGoal goal,
    required double currentAmount,
  }) async {
    await _localDatabase.database.update(
      'savings_goals',
      {
        'current_amount': currentAmount,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [goal.id],
    );
    return LocalSavingsGoal(
      id: goal.id,
      name: goal.name,
      targetAmount: goal.targetAmount,
      currentAmount: currentAmount,
      targetDate: goal.targetDate,
    );
  }

  Future<String?> getSetting(String key) async {
    final rows = await _localDatabase.database.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> saveSetting(String key, String value) async {
    await _localDatabase.database.insert('app_settings', {
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> processRecurringTransactions({String userId = 'guest'}) async {
    final now = DateTime.now().toUtc();
    final rows = await _localDatabase.database.query(
      'recurring_transactions',
      where: 'user_id = ? AND deleted_at IS NULL AND next_occurrence <= ?',
      whereArgs: [userId, now.toIso8601String()],
    );
    for (final row in rows) {
      final recurring = LocalRecurringTransaction.fromMap(row);
      final source = await getById(recurring.transactionId);
      if (source == null) continue;
      var nextDate = recurring.nextOccurrence;
      while (!nextDate.isAfter(now)) {
        await create(
          userId: source.userId,
          accountId: source.accountId,
          categoryId: source.categoryId,
          amount: source.amount,
          type: source.type,
          note: source.note,
          date: nextDate,
          time: source.time,
          attachmentPath: source.attachmentPath,
        );
        nextDate = recurring.frequency == 'weekly'
            ? nextDate.add(const Duration(days: 7))
            : DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
      }
      await _localDatabase.database.update(
        'recurring_transactions',
        {'next_occurrence': nextDate.toIso8601String()},
        where: 'id = ?',
        whereArgs: [recurring.id],
      );
    }
  }

  Future<List<LocalTransaction>> getAll({String userId = 'guest'}) async {
    final rows = await _localDatabase.database.query(
      'transactions',
      where: 'user_id = ? AND deleted_at IS NULL',
      whereArgs: [userId],
      orderBy: 'transaction_date DESC, created_at DESC',
    );
    return rows.map(LocalTransaction.fromMap).toList();
  }

  Future<LocalTransaction?> getById(String id) async {
    final rows = await _localDatabase.database.query(
      'transactions',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : LocalTransaction.fromMap(rows.first);
  }

  Future<LocalTransaction> create({
    required String userId,
    required String accountId,
    required String categoryId,
    required double amount,
    required LocalTransactionType type,
    required String note,
    required DateTime date,
    String? time,
    String? attachmentPath,
    bool isRecurring = false,
    String frequency = 'monthly',
  }) async {
    final now = DateTime.now().toUtc();
    final transaction = LocalTransaction(
      id: 'transaction_${now.microsecondsSinceEpoch}',
      userId: userId,
      accountId: accountId,
      categoryId: categoryId,
      amount: amount,
      type: type,
      note: note,
      date: date,
      time: time,
      attachmentPath: attachmentPath,
      isRecurring: isRecurring,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pendingCreate,
    );

    await _localDatabase.database.transaction((database) async {
      await database.insert('transactions', transaction.toMap());
      await _queueOperation(database, transaction, 'create');
      if (isRecurring) {
        final nextOccurrence = frequency == 'weekly'
            ? date.toUtc().add(const Duration(days: 7))
            : DateTime.utc(date.year, date.month + 1, date.day);
        await database.insert('recurring_transactions', {
          'id': 'recurring_${transaction.id}',
          'user_id': userId,
          'transaction_id': transaction.id,
          'frequency': frequency,
          'next_occurrence': nextOccurrence.toIso8601String(),
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });
      }
    });
    return transaction;
  }

  Future<LocalTransaction> update(LocalTransaction transaction) async {
    final updated = LocalTransaction(
      id: transaction.id,
      userId: transaction.userId,
      accountId: transaction.accountId,
      categoryId: transaction.categoryId,
      amount: transaction.amount,
      type: transaction.type,
      note: transaction.note,
      date: transaction.date,
      time: transaction.time,
      attachmentPath: transaction.attachmentPath,
      isRecurring: transaction.isRecurring,
      createdAt: transaction.createdAt,
      updatedAt: DateTime.now().toUtc(),
      deletedAt: transaction.deletedAt,
      syncStatus: SyncStatus.pendingUpdate,
    );
    await _localDatabase.database.transaction((database) async {
      await database.update(
        'transactions',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [updated.id],
      );
      await _queueOperation(database, updated, 'update');
    });
    return updated;
  }

  Future<LocalTransaction> softDelete(LocalTransaction transaction) async {
    final now = DateTime.now().toUtc();
    final deleted = LocalTransaction(
      id: transaction.id,
      userId: transaction.userId,
      accountId: transaction.accountId,
      categoryId: transaction.categoryId,
      amount: transaction.amount,
      type: transaction.type,
      note: transaction.note,
      date: transaction.date,
      time: transaction.time,
      attachmentPath: transaction.attachmentPath,
      isRecurring: transaction.isRecurring,
      createdAt: transaction.createdAt,
      updatedAt: now,
      deletedAt: now,
      syncStatus: SyncStatus.pendingDelete,
    );
    await _localDatabase.database.transaction((database) async {
      await database.update(
        'transactions',
        deleted.toMap(),
        where: 'id = ?',
        whereArgs: [deleted.id],
      );
      await _queueOperation(database, deleted, 'delete');
    });
    return deleted;
  }

  Future<void> _queueOperation(
    DatabaseExecutor database,
    LocalTransaction transaction,
    String operation,
  ) async {
    await database.insert('sync_operations', {
      'entity_type': 'transaction',
      'entity_id': transaction.id,
      'operation': operation,
      'payload': jsonEncode(transaction.toMap()),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
