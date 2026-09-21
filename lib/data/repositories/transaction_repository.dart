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

  Future<List<LocalTransaction>> getAll({String userId = 'guest'}) async {
    final rows = await _localDatabase.database.query(
      'transactions',
      where: 'user_id = ? AND deleted_at IS NULL',
      whereArgs: [userId],
      orderBy: 'transaction_date DESC, created_at DESC',
    );
    return rows.map(LocalTransaction.fromMap).toList();
  }

  Future<LocalTransaction> create({
    required String userId,
    required String accountId,
    required String categoryId,
    required double amount,
    required LocalTransactionType type,
    required String note,
    required DateTime date,
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
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pendingCreate,
    );

    await _localDatabase.database.transaction((database) async {
      await database.insert('transactions', transaction.toMap());
      await _queueOperation(database, transaction, 'create');
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
