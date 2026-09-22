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
  Map<String, double> _categoryBudgets = {};
  Map<String, double> _accountBalances = {};
  List<LocalSavingsGoal> _savingsGoals = [];
  bool _isDarkMode = false;
  double _budgetWarningThreshold = 0.8;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<LocalTransaction> get transactions => List.unmodifiable(_transactions);
  List<LocalAccount> get accounts => List.unmodifiable(_accounts);
  List<LocalCategory> get categories => List.unmodifiable(_categories);
  double get budget => _budget;
  double get extraIncome => _extraIncome;
  double get defaultBudget => _defaultBudget;
  Map<String, double> get categoryBudgets => Map.unmodifiable(_categoryBudgets);
  Map<String, double> get accountBalances => Map.unmodifiable(_accountBalances);
  List<LocalSavingsGoal> get savingsGoals => List.unmodifiable(_savingsGoals);
  bool get isDarkMode => _isDarkMode;
  double get budgetWarningThreshold => _budgetWarningThreshold;
  bool get isBudgetWarning =>
      _budget > 0 && budgetProgress >= _budgetWarningThreshold;
  Map<String, double> get categorySpending {
    final now = DateTime.now();
    final spending = <String, double>{};
    for (final transaction in _transactions) {
      if (transaction.type == LocalTransactionType.expense &&
          transaction.date.month == now.month &&
          transaction.date.year == now.year) {
        spending[transaction.categoryId] =
            (spending[transaction.categoryId] ?? 0) + transaction.amount;
      }
    }
    return spending;
  }

  Map<String, double> get categoryBudgetWarnings {
    final spending = categorySpending;
    return {
      for (final entry in _categoryBudgets.entries)
        if ((spending[entry.key] ?? 0) >= entry.value && entry.value > 0)
          entry.key: spending[entry.key] ?? 0,
    };
  }

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
      await _repository.processRecurringTransactions();
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
      final budget = await _repository.getBudget();
      _budget = budget?.amount ?? 0;
      _defaultBudget = _budget;
      final categoryBudgets = await _repository.getCategoryBudgets();
      _categoryBudgets = {
        for (final item in categoryBudgets) item.categoryId: item.amount,
      };
      _accountBalances = await _repository.getAccountBalances();
      _savingsGoals = await _repository.getSavingsGoals();
      _isDarkMode = (await _repository.getSetting('theme_mode')) == 'dark';
      final threshold = double.tryParse(
        await _repository.getSetting('budget_warning_threshold') ?? '',
      );
      _budgetWarningThreshold = threshold ?? 0.8;
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
    String frequency = 'monthly',
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
        frequency: frequency,
      );
      _localTransactions[transaction.id] = transaction;
      _accountBalances = await _repository.getAccountBalances();
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
    await _repository.saveBudget(amount);
    _defaultBudget = amount;
    _budget = amount;
    notifyListeners();
  }

  Future<void> updateCategoryBudget(String categoryId, double amount) async {
    await _repository.saveCategoryBudget(
      categoryId: categoryId,
      amount: amount,
    );
    _categoryBudgets[categoryId] = amount;
    notifyListeners();
  }

  Future<void> addCategory(String name, LocalTransactionType type) async {
    final category = await _repository.createCategory(name: name, type: type);
    if (category.type == LocalTransactionType.expense) {
      _categories = [..._categories, category]
        ..sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    }
  }

  Future<void> addSavingsGoal({
    required String name,
    required double targetAmount,
    DateTime? targetDate,
  }) async {
    final goal = await _repository.saveSavingsGoal(
      name: name,
      targetAmount: targetAmount,
      targetDate: targetDate,
    );
    _savingsGoals = [goal, ..._savingsGoals];
    notifyListeners();
  }

  Future<void> addSavingsGoalAmount(
    LocalSavingsGoal goal,
    double amount,
  ) async {
    final updated = await _repository.updateSavingsGoalAmount(
      goal: goal,
      currentAmount: (goal.currentAmount + amount).clamp(0, goal.targetAmount),
    );
    _savingsGoals = [
      for (final item in _savingsGoals)
        if (item.id == updated.id) updated else item,
    ];
    notifyListeners();
  }

  Future<void> setBudgetWarningThreshold(double value) async {
    final threshold = value.clamp(0.5, 1.0).toDouble();
    await _repository.saveSetting(
      'budget_warning_threshold',
      threshold.toString(),
    );
    _budgetWarningThreshold = threshold;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    await _repository.saveSetting('theme_mode', value ? 'dark' : 'light');
    _isDarkMode = value;
    notifyListeners();
  }

  Future<void> processRecurringTransactions() async {
    await _repository.processRecurringTransactions();
    await initialize();
  }

  Future<LocalTransaction?> deleteTransaction(
    LocalTransaction transaction,
  ) async {
    final id = transaction.id;
    final existing = _localTransactions[id] ?? await _repository.getById(id);
    if (existing == null) return null;

    _localTransactions.remove(id);
    _transactions = _transactions.where((item) => item.id != id).toList();
    notifyListeners();

    _error = null;
    try {
      await _repository.softDelete(existing);
      _accountBalances = await _repository.getAccountBalances();
      return existing;
    } catch (e) {
      _localTransactions[id] = existing;
      _transactions = [..._transactions, existing]
        ..sort((a, b) => b.date.compareTo(a.date));
      _error = _handleError(e);
      notifyListeners();
      rethrow;
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
      _accountBalances = await _repository.getAccountBalances();
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
