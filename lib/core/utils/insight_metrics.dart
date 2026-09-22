import '../../data/models/local_entities.dart';

enum InsightRange { week, month, threeMonths, year }

class InsightTrendPoint {
  const InsightTrendPoint({
    required this.start,
    required this.end,
    required this.label,
  });

  final DateTime start;
  final DateTime end;
  final String label;
}

/// Local, deterministic calculations used by the Insights screen.
class InsightMetrics {
  const InsightMetrics._();

  static List<LocalTransaction> forRange(
    Iterable<LocalTransaction> transactions,
    InsightRange range, {
    DateTime? now,
  }) {
    final interval = dateRange(range, now: now);
    return transactions
        .where(
          (transaction) =>
              transaction.deletedAt == null &&
              !transaction.date.isBefore(interval.$1) &&
              transaction.date.isBefore(interval.$2),
        )
        .toList();
  }

  static (DateTime, DateTime) dateRange(InsightRange range, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final day = DateTime(reference.year, reference.month, reference.day);
    switch (range) {
      case InsightRange.week:
        return (
          day.subtract(Duration(days: day.weekday - 1)),
          day.add(const Duration(days: 1)),
        );
      case InsightRange.month:
        return (
          DateTime(day.year, day.month),
          DateTime(day.year, day.month + 1),
        );
      case InsightRange.threeMonths:
        return (
          DateTime(day.year, day.month - 2),
          DateTime(day.year, day.month + 1),
        );
      case InsightRange.year:
        return (DateTime(day.year, 1), DateTime(day.year + 1, 1));
    }
  }

  static Map<String, double> expenseByCategory(
    Iterable<LocalTransaction> transactions,
    String Function(String categoryId) categoryName,
  ) {
    final totals = <String, double>{};
    for (final transaction in transactions) {
      if (transaction.type == LocalTransactionType.expense) {
        final name = categoryName(transaction.categoryId);
        totals[name] = (totals[name] ?? 0) + transaction.amount;
      }
    }
    final orderedEntries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(orderedEntries);
  }

  static List<InsightTrendPoint> trendPoints(
    InsightRange range, {
    DateTime? now,
  }) {
    final interval = dateRange(range, now: now);
    switch (range) {
      case InsightRange.week:
        return List.generate(7, (index) {
          final start = interval.$1.add(Duration(days: index));
          return InsightTrendPoint(
            start: start,
            end: start.add(const Duration(days: 1)),
            label: _weekdayLabel(start.weekday),
          );
        });
      case InsightRange.month:
        final days = interval.$2.difference(interval.$1).inDays;
        return List.generate(days, (index) {
          final start = interval.$1.add(Duration(days: index));
          return InsightTrendPoint(
            start: start,
            end: start.add(const Duration(days: 1)),
            label: '${start.day}',
          );
        });
      case InsightRange.threeMonths:
      case InsightRange.year:
        final months = range == InsightRange.threeMonths ? 3 : 12;
        return List.generate(months, (index) {
          final start = DateTime(interval.$1.year, interval.$1.month + index);
          return InsightTrendPoint(
            start: start,
            end: DateTime(start.year, start.month + 1),
            label: _monthLabel(start.month),
          );
        });
    }
  }

  static double totalFor(
    Iterable<LocalTransaction> transactions,
    InsightTrendPoint point,
    LocalTransactionType type,
  ) => transactions
      .where(
        (transaction) =>
            transaction.type == type &&
            !transaction.date.isBefore(point.start) &&
            transaction.date.isBefore(point.end),
      )
      .fold(0, (total, transaction) => total + transaction.amount);

  static String _weekdayLabel(int weekday) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];
  static String _monthLabel(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}
