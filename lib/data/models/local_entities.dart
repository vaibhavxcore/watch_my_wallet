enum LocalTransactionType { income, expense, transfer }

enum SyncStatus { synced, pendingCreate, pendingUpdate, pendingDelete, failed }

class LocalAccount {
  final String id;
  final String? userId;
  final String name;
  final String currency;
  final double openingBalance;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;

  const LocalAccount({
    required this.id,
    this.userId,
    required this.name,
    this.currency = 'INR',
    required this.openingBalance,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.synced,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'currency': currency,
      'opening_balance': openingBalance,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'sync_status': syncStatus.name,
    };
  }

  factory LocalAccount.fromMap(Map<String, Object?> map) {
    return LocalAccount(
      id: map['id']! as String,
      userId: map['user_id'] as String?,
      name: map['name']! as String,
      currency: map['currency'] as String? ?? 'INR',
      openingBalance: (map['opening_balance'] as num? ?? 0).toDouble(),
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
      deletedAt: _dateOrNull(map['deleted_at']),
      syncStatus: _syncStatus(map['sync_status'] as String? ?? 'synced'),
    );
  }
}

class LocalCategory {
  final String id;
  final String? userId;
  final String name;
  final LocalTransactionType type;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;

  const LocalCategory({
    required this.id,
    this.userId,
    required this.name,
    required this.type,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.synced,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type.name,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'sync_status': syncStatus.name,
    };
  }

  factory LocalCategory.fromMap(Map<String, Object?> map) {
    return LocalCategory(
      id: map['id']! as String,
      userId: map['user_id'] as String?,
      name: map['name']! as String,
      type: _transactionType(map['type']! as String),
      isDefault: (map['is_default']! as int) == 1,
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
      deletedAt: _dateOrNull(map['deleted_at']),
      syncStatus: _syncStatus(map['sync_status'] as String? ?? 'synced'),
    );
  }
}

class LocalTransaction {
  final String id;
  final String userId;
  final String accountId;
  final String? toAccountId;
  final String categoryId;
  final double amount;
  final LocalTransactionType type;
  final String note;
  final DateTime date;
  final String? time;
  final String? attachmentPath;
  final bool isRecurring;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;

  const LocalTransaction({
    required this.id,
    required this.userId,
    required this.accountId,
    this.toAccountId,
    required this.categoryId,
    required this.amount,
    required this.type,
    required this.note,
    required this.date,
    this.time,
    this.attachmentPath,
    this.isRecurring = false,
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
      'to_account_id': toAccountId,
      'category_id': categoryId,
      'amount': amount,
      'type': type.name,
      'note': note,
      'transaction_date': date.toUtc().toIso8601String(),
      'time': time,
      'attachment_path': attachmentPath,
      'is_recurring': isRecurring ? 1 : 0,
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
      toAccountId: map['to_account_id'] as String?,
      categoryId: map['category_id']! as String,
      amount: (map['amount']! as num).toDouble(),
      type: _transactionType(map['type']! as String),
      note: map['note']! as String,
      date: _parseDate(map['transaction_date']),
      time: map['time'] as String?,
      attachmentPath: map['attachment_path'] as String?,
      isRecurring: (map['is_recurring'] as int? ?? 0) == 1,
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
      deletedAt: _dateOrNull(map['deleted_at']),
      syncStatus: _syncStatus(map['sync_status']! as String),
    );
  }

  LocalTransaction copyWith({
    String? id,
    String? userId,
    String? accountId,
    String? toAccountId,
    String? categoryId,
    double? amount,
    LocalTransactionType? type,
    String? note,
    DateTime? date,
    String? time,
    String? attachmentPath,
    bool? isRecurring,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    SyncStatus? syncStatus,
  }) {
    return LocalTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      note: note ?? this.note,
      date: date ?? this.date,
      time: time ?? this.time,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

class LocalBudget {
  final String id;
  final String userId;
  final double amount;
  final String month;
  // final DateTime createdAt;
  // final DateTime updatedAt;
  // final DateTime? deletedAt;
  // final SyncStatus syncStatus;

  const LocalBudget({
    required this.id,
    required this.userId,
    required this.amount,
    required this.month,
    // required this.createdAt,
    // required this.updatedAt,
    // this.deletedAt,
    // this.syncStatus = SyncStatus.synced,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'month': month,
      // 'created_at': createdAt.toUtc().toIso8601String(),
      // 'updated_at': updatedAt.toUtc().toIso8601String(),
      // 'deleted_at': deletedAt?.toUtc().toIso8601String(),
      // 'sync_status': syncStatus.name,
    };
  }

  factory LocalBudget.fromMap(Map<String, Object?> map) {
    return LocalBudget(
      id: map['id']! as String,
      userId: map['user_id']! as String,
      amount: (map['amount']! as num).toDouble(),
      month: map['month']! as String,
      // createdAt: DateTime.parse(map['created_at']! as String),
      // updatedAt: DateTime.parse(map['updated_at']! as String),
      // deletedAt: _dateOrNull(map['deleted_at']),
      // syncStatus: _syncStatus(map['sync_status'] as String? ?? 'synced'),
    );
  }
}

class LocalCategoryBudget {
  final String id;
  final String userId;
  final String categoryId;
  final double amount;
  final String month;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;

  const LocalCategoryBudget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.month,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.synced,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'month': month,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'sync_status': syncStatus.name,
    };
  }

  factory LocalCategoryBudget.fromMap(Map<String, Object?> map) {
    return LocalCategoryBudget(
      id: map['id']! as String,
      userId: map['user_id']! as String,
      categoryId: map['category_id']! as String,
      amount: (map['amount']! as num).toDouble(),
      month: map['month']! as String,
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
      deletedAt: _dateOrNull(map['deleted_at']),
      syncStatus: _syncStatus(map['sync_status'] as String? ?? 'synced'),
    );
  }
}

class LocalSavingsGoal {
  final String id;
  final String userId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;

  const LocalSavingsGoal({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.synced,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'sync_status': syncStatus.name,
    };
  }

  factory LocalSavingsGoal.fromMap(Map<String, Object?> map) {
    return LocalSavingsGoal(
      id: map['id']! as String,
      userId: map['user_id']! as String,
      name: map['name']! as String,
      targetAmount: (map['target_amount']! as num).toDouble(),
      currentAmount: (map['current_amount']! as num).toDouble(),
      targetDate: _dateOrNull(map['target_date']),
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
      deletedAt: _dateOrNull(map['deleted_at']),
      syncStatus: _syncStatus(map['sync_status'] as String? ?? 'synced'),
    );
  }
}

class LocalRecurringTransaction {
  final String id;
  final String userId;
  final String transactionId;
  final String frequency;
  final DateTime nextOccurrence;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;

  const LocalRecurringTransaction({
    required this.id,
    required this.userId,
    required this.transactionId,
    required this.frequency,
    required this.nextOccurrence,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.synced,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'transaction_id': transactionId,
      'frequency': frequency,
      'next_occurrence': nextOccurrence.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'sync_status': syncStatus.name,
    };
  }

  factory LocalRecurringTransaction.fromMap(Map<String, Object?> map) {
    return LocalRecurringTransaction(
      id: map['id']! as String,
      userId: map['user_id']! as String,
      transactionId: map['transaction_id']! as String,
      frequency: map['frequency']! as String,
      nextOccurrence: _parseDate(map['next_occurrence']),
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
      deletedAt: _dateOrNull(map['deleted_at']),
      syncStatus: _syncStatus(map['sync_status'] as String? ?? 'synced'),
    );
  }
}

DateTime _parseDate(Object? value) {
  if (value == null) return DateTime.now();
  return DateTime.tryParse(value as String) ?? DateTime.now();
}

DateTime? _dateOrNull(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value as String);
}

LocalTransactionType _transactionType(String value) {
  try {
    return LocalTransactionType.values.byName(value);
  } catch (_) {
    return LocalTransactionType.expense;
  }
}

SyncStatus _syncStatus(String value) {
  try {
    return SyncStatus.values.byName(value);
  } catch (_) {
    return SyncStatus.synced;
  }
}
