import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:watch_my_wallet/data/local/local_database.dart';
import 'package:watch_my_wallet/data/models/local_entities.dart';
import 'package:watch_my_wallet/data/repositories/supabase_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
class SyncService extends ChangeNotifier {
  final LocalDatabase _localDb;
  final SupabaseRepository _remoteRepo;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  String? _lastError;
  String? get lastError => _lastError;

  DateTime? _lastSyncAt;
  DateTime? get lastSyncAt => _lastSyncAt;

  StreamSubscription? _connectivitySubscription;
  bool _isDisposed = false;

  SyncService(this._localDb, this._remoteRepo);

  void initialize() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      if (result.any((element) => element != ConnectivityResult.none)) {
        sync();
      }
    });
    _loadLastSyncAt();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  Future<void> _loadLastSyncAt() async {
    _lastSyncAt = await _getLastSyncAt();
    notifyListeners();
  }

  Future<void> sync() async {
    if (_isSyncing || _isDisposed) return;

    final userId = _remoteRepo.currentUserId;
    if (userId == null) return;

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      // 1. Push local changes to cloud
      await _pushLocalChanges(userId);

      // 2. Pull remote changes to local
      await _pullRemoteChanges(userId);

      _lastSyncAt = DateTime.now();
      await _updateLastSyncAt(_lastSyncAt!);
      _lastError = null;
    } catch (e) {
      debugPrint('Sync error details: $e');
      _lastError = _formatSyncError(e);
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  String _formatSyncError(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('network') ||
        msg.contains('connection') ||
        msg.contains('failed host lookup')) {
      return "Network error: Could not connect to cloud.";
    }
    if (msg.contains('security policy') || msg.contains('row level security')) {
      return "Permission error: Check cloud access policies.";
    }
    if (msg.contains('401') || msg.contains('unauthorized')) {
      return "Auth error: Please sign in again.";
    }
    return "Sync failed: $e";
  }

  Future<void> _pushLocalChanges(String userId) async {
    const tables = [
      'accounts',
      'categories',
      'transactions',
      'budgets',
      'category_budgets',
      'recurring_transactions',
      'savings_goals',
    ];

    for (final table in tables) {
      if (_isDisposed) return;

      final pending = await _localDb.database.query(
        table,
        where: 'sync_status != ? AND user_id = ?',
        whereArgs: [SyncStatus.synced.name, userId],
      );

      if (pending.isEmpty) continue;

      final toUpsert = pending
          .where((row) => row['sync_status'] != SyncStatus.pendingDelete.name)
          .map((row) {
            final map = Map<String, dynamic>.from(row);
            map.remove('sync_status');
            return map;
          })
          .toList();

      if (toUpsert.isNotEmpty) {
        await _remoteRepo.upsertRecords(table, toUpsert);
      }

      final toDelete = pending
          .where((row) => row['sync_status'] == SyncStatus.pendingDelete.name)
          .toList();

      for (final row in toDelete) {
        await _remoteRepo.deleteRecord(table, row['id'] as String);
        await _localDb.database.delete(
          table,
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }

      await _localDb.database.update(
        table,
        {'sync_status': SyncStatus.synced.name},
        where: 'sync_status != ? AND user_id = ?',
        whereArgs: [SyncStatus.pendingDelete.name, userId],
      );
    }
  }

  Future<void> _pullRemoteChanges(String userId) async {
    final lastSync = await _getLastSyncAt();
    const tables = [
      'accounts',
      'categories',
      'transactions',
      'budgets',
      'category_budgets',
      'recurring_transactions',
      'savings_goals',
    ];

    for (final table in tables) {
      if (_isDisposed) return;
      final updates = await _remoteRepo.fetchUpdates(table, userId, lastSync);

      for (final remoteRecord in updates) {
        if (_isDisposed) return;
        final record = Map<String, dynamic>.from(remoteRecord);
        record['sync_status'] = SyncStatus.synced.name;
        await _localDb.database.insert(
          table,
          record,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  Future<DateTime> _getLastSyncAt() async {
    try {
      final result = await _localDb.database.query(
        'sync_metadata',
        where: 'key = ?',
        whereArgs: ['last_sync_at'],
        limit: 1,
      );
      if (result.isNotEmpty && (result.first['value'] as String).isNotEmpty) {
        return DateTime.parse(result.first['value'] as String);
      }
    } catch (e) {
      debugPrint('Error getting last sync time: $e');
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _updateLastSyncAt(DateTime time) async {
    await _localDb.database.insert('sync_metadata', {
      'key': 'last_sync_at',
      'value': time.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
