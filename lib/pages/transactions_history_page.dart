import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:watch_my_wallet/core/utils/category_icons_data.dart';
import 'package:watch_my_wallet/data/models/local_entities.dart';
import 'package:watch_my_wallet/providers/expense_provider.dart';

class TransactionsHistoryPage extends StatefulWidget {
  const TransactionsHistoryPage({super.key});

  @override
  State<TransactionsHistoryPage> createState() =>
      _TransactionsHistoryPageState();
}

class _TransactionsHistoryPageState extends State<TransactionsHistoryPage> {
  final categoryIcon = CategoryIconsData();
  final _searchController = TextEditingController();
  LocalTransactionType? _filterType;
  String? _filterCategoryId;
  DateTime? _filterDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _filterType = null;
      _filterCategoryId = null;
      _filterDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();

    final filteredTransactions = expenseProvider.transactions.where((
      transaction,
    ) {
      final query = _searchController.text.trim().toLowerCase();
      final categoryName = expenseProvider.categoryName(transaction.categoryId);
      final matchesQuery =
          query.isEmpty ||
          transaction.note.toLowerCase().contains(query) ||
          categoryName.toLowerCase().contains(query) ||
          expenseProvider
              .accountName(transaction.accountId)
              .toLowerCase()
              .contains(query);

      final matchesType =
          _filterType == null || transaction.type == _filterType;
      final matchesCategory =
          _filterCategoryId == null ||
          transaction.categoryId == _filterCategoryId;
      final matchesDate =
          _filterDate == null ||
          (transaction.date.year == _filterDate!.year &&
              transaction.date.month == _filterDate!.month &&
              transaction.date.day == _filterDate!.day);

      return matchesQuery && matchesType && matchesCategory && matchesDate;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          "All Transactions",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_alt),
            onPressed: () => _showFilterSheet(context, expenseProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by note, category or account...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Active Filters Display
          if (_filterType != null ||
              _filterCategoryId != null ||
              _filterDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_filterType != null)
                      _buildFilterChip(
                        _filterType == LocalTransactionType.income
                            ? "Income"
                            : "Expense",
                        () => setState(() => _filterType = null),
                      ),
                    if (_filterCategoryId != null)
                      _buildFilterChip(
                        expenseProvider.categoryName(_filterCategoryId!),
                        () => setState(() => _filterCategoryId = null),
                      ),
                    if (_filterDate != null)
                      _buildFilterChip(
                        DateFormat('MMM dd, yyyy').format(_filterDate!),
                        () => setState(() => _filterDate = null),
                      ),
                    TextButton(
                      onPressed: _resetFilters,
                      child: const Text(
                        "Clear All",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Transactions List
          Expanded(
            child: filteredTransactions.isEmpty
                ? const Center(
                    child: Text(
                      "No transactions found.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = filteredTransactions[index];
                      final categoryName = expenseProvider.categoryName(
                        tx.categoryId,
                      );
                      final isIncome = tx.type == LocalTransactionType.income;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: categoryIcon
                                  .getCategoryColor(categoryName)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              categoryIcon.getCategoryIcon(categoryName),
                              color: categoryIcon.getCategoryColor(
                                categoryName,
                              ),
                            ),
                          ),
                          title: Text(
                            tx.note,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${DateFormat('MMM dd').format(tx.date)} • ${expenseProvider.accountName(tx.accountId)}",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          trailing: Text(
                            "${isIncome ? '+' : '-'} ₹${NumberFormat("#,##,###.##").format(tx.amount)}",
                            style: TextStyle(
                              color: isIncome
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onDeleted: onDeleted,
        deleteIcon: const Icon(Icons.close, size: 14),
        backgroundColor: Colors.blue.shade50,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, ExpenseProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Filter Transactions",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Transaction Type
                  const Text(
                    "Type",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text("All"),
                        selected: _filterType == null,
                        onSelected: (val) {
                          setSheetState(() => _filterType = null);
                          setState(() => _filterType = null);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("Income"),
                        selected: _filterType == LocalTransactionType.income,
                        onSelected: (val) {
                          setSheetState(
                            () => _filterType = LocalTransactionType.income,
                          );
                          setState(
                            () => _filterType = LocalTransactionType.income,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("Expense"),
                        selected: _filterType == LocalTransactionType.expense,
                        onSelected: (val) {
                          setSheetState(
                            () => _filterType = LocalTransactionType.expense,
                          );
                          setState(
                            () => _filterType = LocalTransactionType.expense,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category
                  const Text(
                    "Category",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _filterCategoryId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text("All Categories"),
                      ),
                      ...provider.categories.map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ),
                    ],
                    onChanged: (val) {
                      setSheetState(() => _filterCategoryId = val);
                      setState(() => _filterCategoryId = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date
                  const Text(
                    "Date",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _filterDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setSheetState(() => _filterDate = picked);
                        setState(() => _filterDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _filterDate == null
                                ? "Select Date"
                                : DateFormat(
                                    'MMM dd, yyyy',
                                  ).format(_filterDate!),
                          ),
                          const Icon(Icons.calendar_today, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Apply Filters",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
