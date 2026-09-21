import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:watch_my_wallet/local_database/encrypted_database_spike.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('encrypted database survives the offline transaction lifecycle', (
    tester,
  ) async {
    const key = 'spike-only-test-key';
    await EncryptedDatabaseSpike.deleteDatabase();

    final firstOpen = await EncryptedDatabaseSpike.open(key: key);
    final now = DateTime.now().toUtc().toIso8601String();

    await firstOpen.transaction((transaction) async {
      await transaction.insert('accounts', {
        'id': 'account-1',
        'name': 'Cash',
        'created_at': now,
        'updated_at': now,
      });
      await transaction.insert('categories', {
        'id': 'category-1',
        'name': 'Food',
        'created_at': now,
        'updated_at': now,
      });
      await transaction.insert('transactions', {
        'id': 'transaction-1',
        'account_id': 'account-1',
        'category_id': 'category-1',
        'amount': 250.50,
        'type': 'expense',
        'note': 'Offline lunch',
        'transaction_date': '2026-09-21',
        'created_at': now,
        'updated_at': now,
      });
      await transaction.insert('sync_operations', {
        'entity_type': 'transaction',
        'entity_id': 'transaction-1',
        'operation': 'create',
        'created_at': now,
      });
    });
    await firstOpen.close();

    await expectLater(
      EncryptedDatabaseSpike.open(key: 'wrong-test-key'),
      throwsA(anything),
    );

    final afterRestart = await EncryptedDatabaseSpike.open(key: key);
    final persisted = await afterRestart.query(
      'transactions',
      where: 'id = ?',
      whereArgs: ['transaction-1'],
    );
    expect(persisted, hasLength(1));
    expect(persisted.single['note'], 'Offline lunch');

    final updated = DateTime.now().toUtc().toIso8601String();
    await afterRestart.update(
      'transactions',
      {'note': 'Updated lunch', 'updated_at': updated},
      where: 'id = ?',
      whereArgs: ['transaction-1'],
    );
    await afterRestart.insert('sync_operations', {
      'entity_type': 'transaction',
      'entity_id': 'transaction-1',
      'operation': 'update',
      'created_at': updated,
    });

    await afterRestart.update(
      'transactions',
      {'deleted_at': updated, 'updated_at': updated},
      where: 'id = ?',
      whereArgs: ['transaction-1'],
    );
    await afterRestart.insert('sync_operations', {
      'entity_type': 'transaction',
      'entity_id': 'transaction-1',
      'operation': 'delete',
      'created_at': updated,
    });

    final deleted = await afterRestart.query(
      'transactions',
      where: 'id = ? AND deleted_at IS NOT NULL',
      whereArgs: ['transaction-1'],
    );
    final operations = await afterRestart.query('sync_operations');

    expect(deleted, hasLength(1));
    expect(operations, hasLength(3));
    await afterRestart.close();
  });
}
