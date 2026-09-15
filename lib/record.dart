import 'package:watch_my_wallet/auth/auth_service.dart';

class Record {
  int? id;
  int? uid;
  String details;
  String description;
  String labelText;
  double amount;
  String type;

  Record({
    this.id,
    this.uid,
    required this.details,
    required this.description,
    required this.amount,
    required this.labelText,
    required this.type,
  });

  factory Record.fromMap(Map<String, dynamic> map) {
    return Record(
      details: map["type"] as String,
      description: map["description"] as String,
      amount: map["amount"] as double,
      labelText: map["labelText"] as String,
      type: map["type"] as String,
    );
  }
  final userId = AuthService().getCurrentUserUid();

  Map<String, dynamic> toMap() {
    return {
      "description": description,
      "label": labelText,
      "details": details,
      "amount": amount,
      "type": type,
      "uid": userId,
    };
  }
}
