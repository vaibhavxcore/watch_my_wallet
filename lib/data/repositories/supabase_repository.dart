import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRepository {
  final _client = Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  // Generic method to upsert data to any table
  Future<void> upsertRecords(
    String table,
    List<Map<String, dynamic>> records,
  ) async {
    if (records.isEmpty) return;
    await _client.from(table).upsert(records);
  }

  // Generic method to fetch changes since last sync
  Future<List<Map<String, dynamic>>> fetchUpdates(
    String table,
    String userId,
    DateTime lastSync,
  ) async {
    final response = await _client
        .from(table)
        .select()
        .eq('user_id', userId)
        .gt('updated_at', lastSync.toUtc().toIso8601String());
    return List<Map<String, dynamic>>.from(response);
  }

  // Deletion handling
  Future<void> deleteRecord(String table, String id) async {
    await _client.from(table).delete().eq('id', id);
  }
}
