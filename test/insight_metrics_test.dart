import 'package:flutter_test/flutter_test.dart';
import 'package:watch_my_wallet/core/utils/insight_metrics.dart';
import 'package:watch_my_wallet/data/models/local_entities.dart';

LocalTransaction transaction({
  required String id,
  required DateTime date,
  required LocalTransactionType type,
  required double amount,
  String categoryId = 'groceries',
  DateTime? deletedAt,
}) => LocalTransaction(
  id: id,
  userId: 'guest',
  accountId: 'cash',
  categoryId: categoryId,
  amount: amount,
  type: type,
  note: '',
  date: date,
  createdAt: date,
  updatedAt: date,
  deletedAt: deletedAt,
  syncStatus: SyncStatus.synced,
);

void main() {
  final now = DateTime(2026, 9, 22, 10);

  test('range filtering returns no transactions for an empty dataset', () {
    expect(InsightMetrics.forRange([], InsightRange.month, now: now), isEmpty);
  });

  test('range filtering includes only current-month, non-deleted records', () {
    final records = [
      transaction(
        id: 'included',
        date: DateTime(2026, 9, 10),
        type: LocalTransactionType.expense,
        amount: 25,
      ),
      transaction(
        id: 'old',
        date: DateTime(2026, 8, 31),
        type: LocalTransactionType.expense,
        amount: 10,
      ),
      transaction(
        id: 'deleted',
        date: DateTime(2026, 9, 12),
        type: LocalTransactionType.expense,
        amount: 50,
        deletedAt: now,
      ),
    ];
    expect(
      InsightMetrics.forRange(
        records,
        InsightRange.month,
        now: now,
      ).map((item) => item.id),
      ['included'],
    );
  });

  test('category and trend calculations use local transaction values', () {
    final records = [
      transaction(
        id: 'expense-a',
        date: DateTime(2026, 9, 22),
        type: LocalTransactionType.expense,
        amount: 40,
      ),
      transaction(
        id: 'expense-b',
        date: DateTime(2026, 9, 22),
        type: LocalTransactionType.expense,
        amount: 25,
        categoryId: 'fuel',
      ),
      transaction(
        id: 'income',
        date: DateTime(2026, 9, 22),
        type: LocalTransactionType.income,
        amount: 100,
      ),
    ];
    final totals = InsightMetrics.expenseByCategory(
      records,
      (id) => id == 'fuel' ? 'Fuel' : 'Grocery',
    );
    expect(totals, {'Grocery': 40, 'Fuel': 25});
    final point = InsightMetrics.trendPoints(
      InsightRange.week,
      now: now,
    )[now.weekday - 1];
    expect(
      InsightMetrics.totalFor(records, point, LocalTransactionType.income),
      100,
    );
    expect(
      InsightMetrics.totalFor(records, point, LocalTransactionType.expense),
      65,
    );
  });
}
