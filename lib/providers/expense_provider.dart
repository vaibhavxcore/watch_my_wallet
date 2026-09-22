import 'package:flutter/material.dart';

import '../data/local/local_database.dart';
import '../data/models/local_entities.dart';
import '../data/repositories/transaction_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  final TransactionRepository _repository;

  List<LocalTransaction> _transactions = [];
  final Map<String, LocalTransaction> _localTransactions = {};
  List<LocalAccount> _accounts = [];
  List<LocalCategory> _categories = [];
  double _budget = 0.0;
  final double _extraIncome = 0.0;
  double _defaultBudget = 0.0;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<LocalTransaction> get transactions => List.unmodifiable(_transactions);
  List<LocalAccount> get accounts => List.unmodifiable(_accounts);
  List<LocalCategory> get categories => List.unmodifiable(_categories);
  double get budget => _budget;
  double get extraIncome => _extraIncome;
  double get defaultBudget => _defaultBudget;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed Properties for UI
  double get totalIncome => _transactions
      .where((transaction) => transaction.type == LocalTransactionType.income)
      .fold(0.0, (sum, transaction) => sum + transaction.amount);

  double get monthlyExpenses {
    final now = DateTime.now();
    return _transactions
        .where(
          (transaction) =>
              transaction.type == LocalTransactionType.expense &&
              transaction.date.month == now.month &&
              transaction.date.year == now.year,
        )
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  double get remainingBudget => _budget - monthlyExpenses;

  double get budgetProgress =>
      _budget > 0 ? (monthlyExpenses / _budget).clamp(0.0, 1.0) : 0.0;

  Map<String, double> get categoryBreakdown {
    final now = DateTime.now();
    final breakdown = <String, double>{};
    final currentMonthExpenses = _transactions.where(
      (transaction) =>
          transaction.type == LocalTransactionType.expense &&
          transaction.date.month == now.month &&
          transaction.date.year == now.year,
    );

    for (final transaction in currentMonthExpenses) {
      final category = categoryName(transaction.categoryId);
      breakdown[category] = (breakdown[category] ?? 0.0) + transaction.amount;
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
      _transactions = localRecords;
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

  Future<void> addTransaction({
    bool toBudget = false,
    required String accountId,
    required String categoryId,
    required double amount,
    required LocalTransactionType type,
    required String note,
    required DateTime date,
    String? time,
    String? attachmentPath,
    bool isRecurring = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final transaction = await _repository.create(
        userId: 'guest',
        accountId: accountId,
        categoryId: categoryId,
        amount: amount,
        type: type,
        note: note,
        date: date,
        time: time,
        attachmentPath: attachmentPath,
        isRecurring: isRecurring,
      );
      _localTransactions[transaction.id] = transaction;
      _transactions = [..._transactions, transaction]
        ..sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
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

  Future<LocalTransaction?> deleteTransaction(
    LocalTransaction transaction,
  ) async {
    final id = transaction.id;
    final existing = _localTransactions[id] ?? await _repository.getById(id);
    if (existing == null) return null;

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.softDelete(existing);
      _localTransactions.remove(id);
      _transactions = _transactions.where((item) => item.id != id).toList();
      notifyListeners();
      return existing;
    } catch (e) {
      _error = _handleError(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restoreTransaction(LocalTransaction transaction) async {
    final restored = await _repository.update(
      transaction.copyWith(deletedAt: null),
    );
    _localTransactions[restored.id] = restored;
    _transactions = [..._transactions, restored]
      ..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> updateTransaction(
    LocalTransaction transaction, {
    double? amount,
    String? note,
    DateTime? date,
  }) async {
    final existing =
        _localTransactions[transaction.id] ??
        await _repository.getById(transaction.id);
    if (existing == null) return;

    try {
      final updated = await _repository.update(
        LocalTransaction(
          id: existing.id,
          userId: existing.userId,
          accountId: existing.accountId,
          categoryId: existing.categoryId,
          amount: amount ?? existing.amount,
          type: existing.type,
          note: note ?? existing.note,
          date: date ?? existing.date,
          time: existing.time,
          attachmentPath: existing.attachmentPath,
          isRecurring: existing.isRecurring,
          createdAt: existing.createdAt,
          updatedAt: existing.updatedAt,
          deletedAt: existing.deletedAt,
          syncStatus: existing.syncStatus,
        ),
      );
      _localTransactions[updated.id] = updated;
      final index = _transactions.indexWhere((item) => item.id == updated.id);
      if (index != -1) {
        _transactions[index] = updated;
        _transactions.sort((a, b) => b.date.compareTo(a.date));
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = _handleError(e);
      rethrow;
    }
  }

  String categoryName(String categoryId) {
    for (final category in _categories) {
      if (category.id == categoryId) return category.name;
    }
    return 'Other';
  }

  String accountName(String accountId) {
    for (final account in _accounts) {
      if (account.id == accountId) return account.name;
    }
    return 'Unknown account';
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
