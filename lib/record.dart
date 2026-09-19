import 'package:watch_my_wallet/auth/auth_service.dart';

class Record {
  int? id;
  String? uid;
  String description;
  String labelText;
  double amount;
  String type;
  DateTime date; // Added to track specific transaction date

  Record({
    this.id,
    this.uid,
    required this.description,
    required this.amount,
    required this.labelText,
    required this.type,
    required this.date,
  });

  factory Record.fromMap(Map<String, dynamic> map) {
    return Record(
      id: map["id"],
      uid: map["uuid"],
      description: map["description"] ?? '',
      amount: (map["amount"] as num).toDouble(),
      labelText: map["label"] ?? '',
      type: map["type"] ?? '',
      date: map["date"] != null ? DateTime.parse(map["date"]) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final userId = AuthService().getCurrentUserUid();

    return {
      "description": description,
      "label": labelText,
      "amount": amount,
      "type": type,
      "uuid": userId,
      "date": date.toIso8601String(),
    };
  }
}
