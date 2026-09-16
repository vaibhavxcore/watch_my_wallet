import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watch_my_wallet/record.dart';

class RecordDatabase {
  final _client = Supabase.instance.client;
  final database = Supabase.instance.client.from("records");

  // --- Record Methods ---

  Future createRecord(Record record) async {
    await database.insert(record.toMap());
  }

  // Stream for all records
  final stream = Supabase.instance.client
      .from("records")
      .stream(primaryKey: ['id'])
      .map(
        (data) => data.map((recordMap) => Record.fromMap(recordMap)).toList(),
      );

  Stream<List<Record>> getRecordsByDateStream(DateTime date) {
    return _client
        .from("records")
        .stream(primaryKey: ['id'])
        .map(
          (data) => data
              .map((map) => Record.fromMap(map))
              .where(
                (record) =>
                    record.date.year == date.year &&
                    record.date.month == date.month &&
                    record.date.day == date.day,
              )
              .toList(),
        );
  }

  // --- Budget & Savings Methods ---

  Stream<Map<String, double>> get budgetDataStream {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value({'budget': 0.0, 'extra_income': 0.0});
    }

    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .asyncMap((data) async {
          if (data.isEmpty)
            return {'budget': 0.0, 'extra_income': 0.0, 'default_budget': 0.0};

          final profile = data.first;
          double currentBudget = (profile['budget'] as num?)?.toDouble() ?? 0.0;
          double defaultBudget =
              (profile['default_budget'] as num?)?.toDouble() ?? 0.0;
          double extraIncome =
              (profile['extra_income'] as num?)?.toDouble() ?? 0.0;
          int lastResetMonth = profile['last_reset_month'] as int? ?? 0;
          int lastResetYear = (profile['last_reset_year'] as int?) ?? 0;

          final now = DateTime.now();

          // Reset logic: If it's a new month OR a new year, reset budget to default_budget
          if (lastResetMonth != now.month || lastResetYear != now.year) {
            currentBudget = defaultBudget;
            await _client
                .from('profiles')
                .update({
                  'budget': currentBudget,
                  'last_reset_month': now.month,
                  'last_reset_year': now.year,
                })
                .eq('id', userId);
          }

          return {
            'budget': currentBudget,
            'extra_income': extraIncome,
            'default_budget': defaultBudget,
          };
        });
  }

  Future<void> updateDefaultBudget(double amount) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('profiles').upsert({
      'id': userId,
      'default_budget': amount,
      'budget': amount,
      'last_reset_month': DateTime.now().month,
      'last_reset_year': DateTime.now().year,
    });
  }

  Future<void> addIncomeToBudget(double amount) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final response = await _client
        .from('profiles')
        .select('budget')
        .eq('id', userId)
        .maybeSingle();
    double currentBudget = (response?['budget'] as num?)?.toDouble() ?? 0.0;

    await _client.from('profiles').upsert({
      'id': userId,
      'budget': currentBudget + amount,
    });
  }

  Future<void> addIncomeToSavings(double amount) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final response = await _client
        .from('profiles')
        .select('extra_income')
        .eq('id', userId)
        .maybeSingle();
    double currentSavings =
        (response?['extra_income'] as num?)?.toDouble() ?? 0.0;

    await _client.from('profiles').upsert({
      'id': userId,
      'extra_income': currentSavings + amount,
    });
  }
}
