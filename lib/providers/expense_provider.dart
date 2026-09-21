import 'package:flutter/material.dart';

import '../data/local/local_database.dart';
import '../data/models/local_entities.dart';
import '../data/repositories/transaction_repository.dart';
import '../record.dart';

class ExpenseProvider extends ChangeNotifier {
  final TransactionRepository _repository;

  List<Record> _records = [];
  final Map<String, LocalTransaction> _localTransactions = {};
  List<LocalAccount> _accounts = [];
  List<LocalCategory> _categories = [];
  double _budget = 0.0;
  final double _extraIncome = 0.0;
  double _defaultBudget = 0.0;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Record> get records => _records;
  List<LocalAccount> get accounts => List.unmodifiable(_accounts);
  List<LocalCategory> get categories => List.unmodifiable(_categories);
  double get budget => _budget;
  double get extraIncome => _extraIncome;
  double get defaultBudget => _defaultBudget;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed Properties for UI
  double get totalIncome => _records
      .where((r) => r.type == "Income")
      .fold(0.0, (sum, r) => sum + r.amount);

  double get monthlyExpenses {
    final now = DateTime.now();
    return _records
        .where(
          (r) =>
              r.type == "Expense" &&
              r.date.month == now.month &&
              r.date.year == now.year,
        )
        .fold(0.0, (sum, r) => sum + r.amount);
  }

  double get remainingBudget => _budget - monthlyExpenses;

  double get budgetProgress =>
      _budget > 0 ? (monthlyExpenses / _budget).clamp(0.0, 1.0) : 0.0;

  Map<String, double> get categoryBreakdown {
    final now = DateTime.now();
    final breakdown = <String, double>{};
    final currentMonthExpenses = _records.where(
      (r) =>
          r.type == "Expense" &&
          r.date.month == now.month &&
          r.date.year == now.year,
    );

    for (var r in currentMonthExpenses) {
      breakdown[r.labelText] = (breakdown[r.labelText] ?? 0.0) + r.amount;
    }
    return breakdown;
  }

  ExpenseProvider(LocalDatabase database)
    : _repository = TransactionRepository(database);

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final localRecords = await _repository.getAll();
      _localTransactions
        ..clear()
        ..addEntries(
          localRecords.map(
            (transaction) => MapEntry(transaction.id, transaction),
          ),
        );
      _accounts = await _repository.getAccounts();
      _categories = await _repository.getCategories(
        type: LocalTransactionType.expense,
      );
      _records = localRecords.map(_toLegacyRecord).toList();
      _records.sort((a, b) => b.date.compareTo(a.date));
      _error = null;
    } catch (e) {
      _error = _handleError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories(LocalTransactionType type) async {
    _categories = await _repository.getCategories(type: type);
    notifyListeners();
  }

  Future<void> addRecord(
    Record record, {
    bool toBudget = false,
    String? accountId,
    String? categoryId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.create(
        userId: 'guest',
        accountId: accountId ?? 'account_cash',
        categoryId: categoryId ?? _categoryId(record),
        amount: record.amount,
        type: record.type == 'Income'
            ? LocalTransactionType.income
            : LocalTransactionType.expense,
        note: record.description,
        date: record.date,
      );
      await initialize();
    } catch (e) {
      _error = _handleError(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateBudgetGoal(double amount) async {
    _defaultBudget = amount;
    _budget = amount;
    notifyListeners();
  }

  Future<void> deleteRecord(Record record) async {
    final id = record.id;
    if (id == null) return;
    final transaction = _localTransactions[id] ?? await _repository.getById(id);
    if (transaction == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.softDelete(transaction);
      await initialize();
    } catch (e) {
      _error = _handleError(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRecord(
    Record record, {
    required double amount,
    required String note,
  }) async {
    final id = record.id;
    if (id == null) return;
    final transaction = _localTransactions[id] ?? await _repository.getById(id);
    if (transaction == null) return;

    try {
      final updated = await _repository.update(
        LocalTransaction(
          id: transaction.id,
          userId: transaction.userId,
          accountId: transaction.accountId,
          categoryId: transaction.categoryId,
          amount: amount,
          type: transaction.type,
          note: note,
          date: transaction.date,
          createdAt: transaction.createdAt,
          updatedAt: transaction.updatedAt,
          deletedAt: transaction.deletedAt,
          syncStatus: transaction.syncStatus,
        ),
      );
      _localTransactions[updated.id] = updated;
      final index = _records.indexWhere((item) => item.id == updated.id);
      if (index != -1) {
        _records[index] = _toLegacyRecord(updated);
        _records.sort((a, b) => b.date.compareTo(a.date));
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = _handleError(e);
      rethrow;
    }
  }

  String _categoryId(Record record) {
    final type = record.type == 'Income' ? 'income' : 'expense';
    final label = record.labelText.toLowerCase() == 'others'
        ? 'other'
        : record.labelText.toLowerCase();
    return 'category_${type}_$label';
  }

  Record _toLegacyRecord(LocalTransaction transaction) {
    final type = transaction.type == LocalTransactionType.income
        ? 'Income'
        : 'Expense';
    final category = transaction.categoryId.split('_').skip(2).join('_');
    return Record(
      id: transaction.id,
      uid: transaction.userId,
      description: transaction.note,
      labelText: category.isEmpty ? 'Other' : _titleCase(category),
      amount: transaction.amount,
      type: type,
      date: transaction.date.toLocal(),
    );
  }

  String _titleCase(String value) {
    return value
        .split('_')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String _handleError(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('network') ||
        msg.contains('connection') ||
        msg.contains('failed host lookup')) {
      return "No internet connection. Please check your network.";
    }
    if (msg.contains('security policy')) {
      return "Access denied. Please check your RLS policies in Supabase.";
    }
    return "Something went wrong. Please try again.";
  }
}
