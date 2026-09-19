import 'dart:async';

import 'package:flutter/material.dart';

import '../record.dart';
import '../record_database.dart';

class ExpenseProvider extends ChangeNotifier {
  final RecordDatabase _db = RecordDatabase();

  List<Record> _records = [];
  double _budget = 0.0;
  double _extraIncome = 0.0;
  double _defaultBudget = 0.0;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Record> get records => _records;
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

  StreamSubscription? _recordSub;
  StreamSubscription? _budgetSub;

  void initialize() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _recordSub?.cancel();
    _recordSub = _db.stream.listen(
      (data) {
        _records = data;
        _records.sort((a, b) => b.date.compareTo(a.date));
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (err) {
        _error = _handleError(err);
        _isLoading = false;
        notifyListeners();
      },
    );

    _budgetSub?.cancel();
    _budgetSub = _db.budgetDataStream.listen(
      (data) {
        _budget = data['budget'] ?? 0.0;
        _extraIncome = data['extra_income'] ?? 0.0;
        _defaultBudget = data['default_budget'] ?? 0.0;
        _error = null;
        notifyListeners();
      },
      onError: (err) {
        _error = _handleError(err);
        notifyListeners();
      },
    );
  }

  Future<void> addRecord(Record record, {bool toBudget = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.createRecord(record);
      if (record.type == "Income") {
        if (toBudget) {
          await _db.addIncomeToBudget(record.amount);
        } else {
          await _db.addIncomeToSavings(record.amount);
        }
      }
    } catch (e) {
      _error = _handleError(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateBudgetGoal(double amount) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _db.updateDefaultBudget(amount);
    } catch (e) {
      _error = _handleError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  @override
  void dispose() {
    _recordSub?.cancel();
    _budgetSub?.cancel();
    super.dispose();
  }
}
