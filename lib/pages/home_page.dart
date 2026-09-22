import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:watch_my_wallet/core/utils/category_icons_data.dart';
import 'package:watch_my_wallet/providers/auth_provider.dart';
import 'package:watch_my_wallet/providers/expense_provider.dart';
import 'package:watch_my_wallet/data/models/local_entities.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  @override
  Widget build(BuildContext context) {
    // 1. Access the providers
    final expenseProvider = context.watch<ExpenseProvider>();
    final authProvider = context.watch<AuthProvider>();

    // 2. Extract data from state
    final userEmail = authProvider.user?.email ?? "User";
    final userName = userEmail.split('@')[0];

    final transactions = expenseProvider.transactions;
    final visibleTransactions = transactions.where((transaction) {
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
    final currentBudgetLimit = expenseProvider.budget;
    final totalSavings = expenseProvider.extraIncome;

    if (expenseProvider.isLoading && transactions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    if (expenseProvider.error != null && transactions.isEmpty) {
      return Scaffold(
        body: Center(child: Text("Error: ${expenseProvider.error}")),
      );
    }

    final now = DateTime.now();
    double monthlyExpenses = 0;
    double totalIncome = 0;

    for (final rec in transactions) {
      if (rec.type == LocalTransactionType.expense) {
        if (rec.date.month == now.month && rec.date.year == now.year) {
          monthlyExpenses += rec.amount;
        }
      } else if (rec.type == LocalTransactionType.income) {
        totalIncome += rec.amount;
      }
    }

    double remainingBudget = currentBudgetLimit - monthlyExpenses;
    double budgetProgress = currentBudgetLimit > 0
        ? (monthlyExpenses / currentBudgetLimit).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium Dark Header
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 260,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(25, 70, 25, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Good day,",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        userName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                // Floating Remaining Budget Card
                Positioned(
                  bottom: -130,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "REMAINING BUDGET",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "₹${NumberFormat("#,##,###.##").format(remainingBudget)}",
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: remainingBudget < 0
                                ? Colors.red.shade700
                                : Colors.black,
                            letterSpacing: -1,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Budget Progress Bar
                        if (currentBudgetLimit > 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Limit: ₹${NumberFormat("#,##,###").format(currentBudgetLimit)}",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${(budgetProgress * 100).toInt()}%",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: budgetProgress,
                              backgroundColor: Colors.grey.shade100,
                              color: budgetProgress > 0.9
                                  ? Colors.red
                                  : Colors.black,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Savings: ₹${NumberFormat("#,##,###").format(totalSavings)}",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                remainingBudget >= 0
                                    ? "₹${NumberFormat("#,##,###").format(remainingBudget)} left"
                                    : "Over budget",
                                style: TextStyle(
                                  color: remainingBudget >= 0
                                      ? Colors.grey
                                      : Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _buildSummaryTile(
                              "Month Exp",
                              monthlyExpenses,
                              Colors.red.shade600,
                              Icons.arrow_upward_rounded,
                            ),
                            Container(
                              height: 35,
                              width: 1,
                              color: Colors.grey.shade100,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                            _buildSummaryTile(
                              "Total Inc",
                              totalIncome,
                              Colors.green.shade600,
                              Icons.arrow_downward_rounded,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 150)),

          // Recent Activity Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Activity",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1D1E),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "See All",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search transactions',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.clear),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _filterType == null,
                        onSelected: (_) => setState(() => _filterType = null),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Expense'),
                        selected: _filterType == LocalTransactionType.expense,
                        onSelected: (_) => setState(
                          () => _filterType = LocalTransactionType.expense,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Income'),
                        selected: _filterType == LocalTransactionType.income,
                        onSelected: (_) => setState(
                          () => _filterType = LocalTransactionType.income,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Filter by date',
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _filterDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (!mounted) return;
                          setState(() => _filterDate = date);
                        },
                        icon: Icon(
                          _filterDate == null
                              ? Icons.event_outlined
                              : Icons.event_available,
                        ),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _filterCategoryId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All categories'),
                      ),
                      ...expenseProvider.categories.map(
                        (category) => DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _filterCategoryId = value),
                  ),
                ],
              ),
            ),
          ),
          visibleTransactions.isEmpty
              ? const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      "No transactions yet.",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final rec = visibleTransactions[index];
                      final isIncome = rec.type == LocalTransactionType.income;
                      final categoryName = expenseProvider.categoryName(
                        rec.categoryId,
                      );
                      final dateFormatted = DateFormat(
                        'MMM dd, yyyy',
                      ).format(rec.date);

                      return Dismissible(
                        key: ValueKey(rec.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          color: Colors.red.shade700,
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) async {
                          final deleted = await context
                              .read<ExpenseProvider>()
                              .deleteTransaction(rec);
                          if (!context.mounted || deleted == null) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Transaction deleted'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () => context
                                    .read<ExpenseProvider>()
                                    .restoreTransaction(deleted),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () =>
                                  _showTransactionDetails(context, rec),
                              onLongPress: () => _confirmDelete(context, rec),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: categoryIcon
                                            .getCategoryColor(categoryName)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Icon(
                                        categoryIcon.getCategoryIcon(
                                          categoryName,
                                        ),
                                        color: categoryIcon.getCategoryColor(
                                          categoryName,
                                        ),
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            rec.note,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 17,
                                              color: Color(0xFF1A1D1E),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            categoryName,
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "${isIncome ? '+' : '-'} ₹${NumberFormat("#,##,###.##").format(rec.amount)}",
                                          style: TextStyle(
                                            color: isIncome
                                                ? Colors.green.shade700
                                                : Colors.red.shade700,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 17,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          dateFormatted,
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }, childCount: visibleTransactions.length),
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Future<void> _showTransactionDetails(
    BuildContext context,
    LocalTransaction transaction,
  ) async {
    final provider = context.read<ExpenseProvider>();
    final shouldEdit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(provider.categoryName(transaction.categoryId)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(transaction.note),
            const SizedBox(height: 12),
            Text('Amount: ₹${transaction.amount.toStringAsFixed(2)}'),
            Text('Account: ${provider.accountName(transaction.accountId)}'),
            Text('Date: ${DateFormat.yMMMd().format(transaction.date)}'),
            if (transaction.isRecurring) const Text('Recurring transaction'),
            if (transaction.attachmentPath != null)
              Text('Attachment: ${transaction.attachmentPath}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
    if (shouldEdit == true && context.mounted) {
      await _editRecord(context, transaction);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    LocalTransaction transaction,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text(
          'This transaction will be removed from your lists.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !context.mounted) return;
    try {
      await context.read<ExpenseProvider>().deleteTransaction(transaction);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transaction deleted')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete transaction')),
        );
      }
    }
  }

  Future<void> _editRecord(
    BuildContext context,
    LocalTransaction transaction,
  ) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => EditRecordDialog(transaction: transaction),
    );
    if (result == null || !context.mounted) return;
    final amount = double.tryParse(result['amount'] ?? '');
    final note = result['note']?.trim() ?? '';
    if (amount == null || amount <= 0 || note.isEmpty) return;
    try {
      await context.read<ExpenseProvider>().updateTransaction(
        transaction,
        amount: amount,
        note: note,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update transaction')),
        );
      }
    }
  }

  Widget _buildSummaryTile(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  "₹${NumberFormat.compact().format(amount)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Color(0xFF1A1D1E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditRecordDialog extends StatefulWidget {
  final LocalTransaction transaction;

  const EditRecordDialog({super.key, required this.transaction});

  @override
  State<EditRecordDialog> createState() => _EditRecordDialogState();
}

class _EditRecordDialogState extends State<EditRecordDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction.amount.toStringAsFixed(2),
    );
    _noteController = TextEditingController(text: widget.transaction.note);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit transaction'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount'),
          ),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Note'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop({
            'amount': _amountController.text,
            'note': _noteController.text,
          }),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
