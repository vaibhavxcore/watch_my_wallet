import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:watch_my_wallet/core/utils/category_icons_data.dart';
import 'package:watch_my_wallet/providers/auth_provider.dart';
import 'package:watch_my_wallet/providers/expense_provider.dart';
import 'package:watch_my_wallet/record.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final categoryIcon = CategoryIconsData();

  @override
  Widget build(BuildContext context) {
    // 1. Access the providers
    final expenseProvider = context.watch<ExpenseProvider>();
    final authProvider = context.watch<AuthProvider>();

    // 2. Extract data from state
    final userEmail = authProvider.user?.email ?? "User";
    final userName = userEmail.split('@')[0];

    final records = expenseProvider.records;
    final currentBudgetLimit = expenseProvider.budget;
    final totalSavings = expenseProvider.extraIncome;

    if (expenseProvider.isLoading && records.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    if (expenseProvider.error != null && records.isEmpty) {
      return Scaffold(
        body: Center(child: Text("Error: ${expenseProvider.error}")),
      );
    }

    final now = DateTime.now();
    double monthlyExpenses = 0;
    double totalIncome = 0;

    for (var rec in records) {
      if (rec.type == "Expense") {
        if (rec.date.month == now.month && rec.date.year == now.year) {
          monthlyExpenses += rec.amount;
        }
      } else if (rec.type == "Income") {
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

          records.isEmpty
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
                      final rec = records[index];
                      final isIncome = rec.type == "Income";
                      final dateFormatted = DateFormat(
                        'MMM dd, yyyy',
                      ).format(rec.date);

                      return Container(
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
                            onTap: () => _editRecord(context, rec),
                            onLongPress: () => _confirmDelete(context, rec),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: categoryIcon
                                          .getCategoryColor(rec.labelText)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Icon(
                                      categoryIcon.getCategoryIcon(
                                        rec.labelText,
                                      ),
                                      color: categoryIcon.getCategoryColor(
                                        rec.labelText,
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
                                          rec.description,
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
                                          rec.labelText,
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
                                    crossAxisAlignment: CrossAxisAlignment.end,
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
                      );
                    }, childCount: records.length),
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Record record) async {
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
      await context.read<ExpenseProvider>().deleteRecord(record);
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

  Future<void> _editRecord(BuildContext context, Record record) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => EditRecordDialog(record: record),
    );
    if (result == null || !context.mounted) return;
    final amount = double.tryParse(result['amount'] ?? '');
    final note = result['note']?.trim() ?? '';
    if (amount == null || amount <= 0 || note.isEmpty) return;
    try {
      await context.read<ExpenseProvider>().updateRecord(
        record,
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
  final Record record;

  const EditRecordDialog({super.key, required this.record});

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
      text: widget.record.amount.toStringAsFixed(2),
    );
    _noteController = TextEditingController(text: widget.record.description);
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
