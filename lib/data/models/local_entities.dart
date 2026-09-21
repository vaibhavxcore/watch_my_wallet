enum LocalTransactionType { income, expense }

enum SyncStatus { synced, pendingCreate, pendingUpdate, pendingDelete, failed }

class LocalAccount {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const LocalAccount({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory LocalAccount.fromMap(Map<String, Object?> map) {
    return LocalAccount(
      id: map['id']! as String,
      name: map['name']! as String,
      createdAt: DateTime.parse(map['created_at']! as String),
      updatedAt: DateTime.parse(map['updated_at']! as String),
      deletedAt: _dateOrNull(map['deleted_at']),
    );
  }
}

class LocalCategory {
  final String id;
  final String name;
  final LocalTransactionType type;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const LocalCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory LocalCategory.fromMap(Map<String, Object?> map) {
    return LocalCategory(
      id: map['id']! as String,
      name: map['name']! as String,
      type: _transactionType(map['type']! as String),
      isDefault: (map['is_default']! as int) == 1,
      createdAt: DateTime.parse(map['created_at']! as String),
      updatedAt: DateTime.parse(map['updated_at']! as String),
      deletedAt: _dateOrNull(map['deleted_at']),
    );
  }
}

class LocalTransaction {
  final String id;
  final String userId;
  final String accountId;
  final String categoryId;
  final double amount;
  final LocalTransactionType type;
  final String note;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;

  const LocalTransaction({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.type,
    required this.note,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.deletedAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'account_id': accountId,
      'category_id': categoryId,
      'amount': amount,
      'type': type.name,
      'note': note,
      'transaction_date': date.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'sync_status': syncStatus.name,
    };
  }

  factory LocalTransaction.fromMap(Map<String, Object?> map) {
    return LocalTransaction(
      id: map['id']! as String,
      userId: map['user_id']! as String,
      accountId: map['account_id']! as String,
      categoryId: map['category_id']! as String,
      amount: (map['amount']! as num).toDouble(),
      type: _transactionType(map['type']! as String),
      note: map['note']! as String,
      date: DateTime.parse(map['transaction_date']! as String),
      createdAt: DateTime.parse(map['created_at']! as String),
      updatedAt: DateTime.parse(map['updated_at']! as String),
      deletedAt: _dateOrNull(map['deleted_at']),
      syncStatus: _syncStatus(map['sync_status']! as String),
    );
  }
}

DateTime? _dateOrNull(Object? value) {
  return value == null ? null : DateTime.parse(value as String);
}

LocalTransactionType _transactionType(String value) {
  return LocalTransactionType.values.byName(value);
}

SyncStatus _syncStatus(String value) {
  return SyncStatus.values.byName(value);
}
