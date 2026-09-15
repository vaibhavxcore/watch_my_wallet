import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watch_my_wallet/record.dart';

class RecordDatabase {
  final database = Supabase.instance.client.from("records");

  //create
  Future createRecord(Record record) async {
    await database.insert(record.toMap());
  }

  //Read
  final stream = Supabase.instance.client
      .from("records")
      .stream(primaryKey: ['id'])
      .map(
        (data) => data.map((recordMap) => Record.fromMap(recordMap)).toList(),
      );
}
