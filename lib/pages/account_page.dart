import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:watch_my_wallet/providers/auth_provider.dart';
import 'package:watch_my_wallet/providers/expense_provider.dart';
import 'package:watch_my_wallet/data/models/local_entities.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _budgetController = TextEditingController();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _budgetController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<AuthProvider>().signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateBudgetDialog(double currentDefault) {
    _budgetController.text = currentDefault > 0
        ? currentDefault.toString()
        : '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Monthly Budget Goal',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Set the amount your budget resets to on the 1st of every month.",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _budgetController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: true,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixIcon: const Icon(
                    Icons.currency_rupee,
                    color: Colors.black,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(_budgetController.text) ?? 0.0;
                context.read<ExpenseProvider>().updateBudgetGoal(amount);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Set Goal',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAmountDialog({
    required String title,
    required String hint,
    required Future<void> Function(double amount) onSave,
  }) async {
    _amountController.clear();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(_amountController.text);
              if (amount == null || amount < 0) return;
              await onSave(amount);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCategoryDialog() async {
    _nameController.clear();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New expense category'),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (_nameController.text.trim().isEmpty) return;
              await context.read<ExpenseProvider>().addCategory(
                _nameController.text,
                LocalTransactionType.expense,
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSavingsGoalDialog() async {
    _nameController.clear();
    _amountController.clear();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Savings goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Goal name'),
            ),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Target amount'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(_amountController.text);
              if (_nameController.text.trim().isEmpty ||
                  amount == null ||
                  amount <= 0) {
                return;
              }
              await context.read<ExpenseProvider>().addSavingsGoal(
                name: _nameController.text,
                targetAmount: amount,
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showGoalContributionDialog(
    ExpenseProvider provider,
    LocalSavingsGoal goal,
  ) async {
    _amountController.clear();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add money to ${goal.name}'),
        content: TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText:
                'Remaining: ₹${NumberFormat('#,##,###.##').format(goal.targetAmount - goal.currentAmount)}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(_amountController.text);
              if (amount == null || amount <= 0) return;
              await provider.addSavingsGoalAmount(goal, amount);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Add money'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCategoryBudgetDialog(ExpenseProvider provider) async {
    String? categoryId = provider.categories.isEmpty
        ? null
        : provider.categories.first.id;
    _amountController.clear();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Category budget'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: categoryId,
                items: provider.categories
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setDialogState(() => categoryId = value),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Monthly amount'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(_amountController.text);
              if (categoryId == null || amount == null || amount < 0) return;
              await provider.updateCategoryBudget(categoryId!, amount);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();

    final userEmail = authProvider.user?.email ?? "User";
    final userName = userEmail.split('@')[0];

    final defaultBudget = expenseProvider.defaultBudget;
    final savings = expenseProvider.extraIncome;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: expenseProvider.error != null
          ? Center(
              child: Text(
                "Error: ${expenseProvider.error}",
                style: const TextStyle(color: Colors.red),
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Profile Header
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(25, 75, 25, 30),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 35,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                userEmail,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _showLogoutDialog,
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Overview Stats Cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildValueCard(
                            title: "MONTHLY GOAL",
                            value: defaultBudget,
                            color: Colors.blue.shade700,
                            icon: Icons.track_changes_rounded,
                            onTap: () => _showUpdateBudgetDialog(defaultBudget),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildValueCard(
                            title: "TOTAL SAVINGS",
                            value: savings,
                            color: Colors.green.shade700,
                            icon: Icons.account_balance_wallet_rounded,
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                    child: Column(
                      children: [
                        _buildSettingItem(
                          icon: Icons.category_outlined,
                          title: 'Add custom category',
                          trailing: '',
                          color: Colors.teal,
                          onTap: _showCategoryDialog,
                        ),
                        _buildSettingItem(
                          icon: Icons.savings_outlined,
                          title: 'Add savings goal',
                          trailing: '${expenseProvider.savingsGoals.length}',
                          color: Colors.green,
                          onTap: _showSavingsGoalDialog,
                        ),
                        _buildSettingItem(
                          icon: Icons.pie_chart_outline,
                          title: 'Category budgets',
                          trailing: '${expenseProvider.categoryBudgets.length}',
                          color: Colors.deepOrange,
                          onTap: () =>
                              _showCategoryBudgetDialog(expenseProvider),
                        ),
                        _buildSettingItem(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Manage accounts',
                          trailing: '${expenseProvider.accountBalances.length}',
                          color: Colors.indigo,
                          onTap: () => _showAccounts(expenseProvider),
                        ),
                        _buildSettingItem(
                          icon: Icons.tune,
                          title: 'Budget warning',
                          trailing:
                              '${(expenseProvider.budgetWarningThreshold * 100).round()}%',
                          color: Colors.orange,
                          onTap: () => _showAmountDialog(
                            title: 'Warning threshold',
                            hint: 'Percent (50-100)',
                            onSave: (amount) => expenseProvider
                                .setBudgetWarningThreshold(amount / 100),
                          ),
                        ),
                        SwitchListTile.adaptive(
                          title: const Text('Dark theme'),
                          value: expenseProvider.isDarkMode,
                          onChanged: expenseProvider.setDarkMode,
                        ),
                      ],
                    ),
                  ),
                ),

                if (expenseProvider.categoryBudgets.isNotEmpty ||
                    expenseProvider.savingsGoals.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (expenseProvider.categoryBudgets.isNotEmpty) ...[
                            const Text(
                              'CATEGORY BUDGETS',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...expenseProvider.categoryBudgets.entries.map((
                              entry,
                            ) {
                              final spent =
                                  expenseProvider.categorySpending[entry.key] ??
                                  0;
                              final progress = entry.value == 0
                                  ? 0.0
                                  : (spent / entry.value).clamp(0.0, 1.0);
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  expenseProvider.categoryName(entry.key),
                                ),
                                subtitle: LinearProgressIndicator(
                                  value: progress,
                                  color: progress >= 1
                                      ? Colors.red
                                      : Colors.orange,
                                ),
                                trailing: Text(
                                  '₹${NumberFormat('#,##,###.##').format(spent)} / ₹${NumberFormat('#,##,###.##').format(entry.value)}',
                                ),
                              );
                            }),
                          ],
                          if (expenseProvider.savingsGoals.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'SAVINGS GOALS',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...expenseProvider.savingsGoals.map(
                              (goal) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(goal.name),
                                subtitle: LinearProgressIndicator(
                                  value: goal.targetAmount == 0
                                      ? 0
                                      : (goal.currentAmount / goal.targetAmount)
                                            .clamp(0.0, 1.0),
                                  color: Colors.green,
                                ),
                                trailing: Text(
                                  '₹${NumberFormat('#,##,###.##').format(goal.currentAmount)} / ₹${NumberFormat('#,##,###.##').format(goal.targetAmount)}',
                                ),
                                onTap: () => _showGoalContributionDialog(
                                  expenseProvider,
                                  goal,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                //  Settings List
                SliverPadding(
                  padding: const EdgeInsets.all(25),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const Text(
                        "PREFERENCES",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSettingItem(
                        icon: Icons.notifications_none_rounded,
                        title: "Notifications",
                        trailing: "On",
                        color: Colors.orange,
                      ),
                      _buildSettingItem(
                        icon: Icons.security_rounded,
                        title: "Privacy & Security",
                        trailing: "",
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "ACCOUNT",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSettingItem(
                        icon: Icons.alternate_email_rounded,
                        title: "Change Email",
                        trailing: "",
                        color: Colors.purple,
                      ),
                      _buildSettingItem(
                        icon: Icons.delete_outline_rounded,
                        title: "Delete Account",
                        trailing: "",
                        color: Colors.red,
                        isLast: true,
                      ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildValueCard({
    required String title,
    required double value,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "₹${NumberFormat.compact().format(value)}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String trailing,
    required Color color,
    VoidCallback? onTap,
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF2D3243),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailing.isNotEmpty)
                Text(
                  trailing,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: Colors.grey.shade300,
              ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Future<void> _showAccounts(ExpenseProvider provider) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Manage accounts'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: provider.accounts
                .map(
                  (account) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(account.name),
                    subtitle: Text(
                      'Opening: ₹${NumberFormat('#,##,###.##').format(account.openingBalance)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₹${NumberFormat('#,##,###.##').format(provider.accountBalances[account.id] ?? 0)}',
                        ),
                        PopupMenuButton<String>(
                          onSelected: (action) async {
                            Navigator.pop(dialogContext);
                            if (action == 'edit') {
                              await _showAccountEditor(
                                provider,
                                account: account,
                              );
                            } else {
                              await _confirmArchiveAccount(provider, account);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'archive',
                              child: Text('Archive'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _showAccountEditor(provider);
            },
            child: const Text('Add account'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAccountEditor(
    ExpenseProvider provider, {
    LocalAccount? account,
  }) async {
    _nameController.text = account?.name ?? '';
    _amountController.text = account == null
        ? ''
        : account.openingBalance.toString();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(account == null ? 'New account' : 'Edit account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Account name'),
            ),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(labelText: 'Opening balance'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              final openingBalance = double.tryParse(_amountController.text);
              if (name.isEmpty || openingBalance == null) return;
              if (account == null) {
                await provider.addAccount(
                  name: name,
                  openingBalance: openingBalance,
                );
              } else {
                await provider.updateAccount(
                  account: account,
                  name: name,
                  openingBalance: openingBalance,
                );
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: Text(account == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmArchiveAccount(
    ExpenseProvider provider,
    LocalAccount account,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Archive ${account.name}?'),
        content: const Text(
          'Archived accounts are removed from new transactions, but their past records remain available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await provider.archiveAccount(account);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } on StateError catch (error) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error.message.toString())),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }
}
