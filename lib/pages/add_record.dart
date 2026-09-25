import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:watch_my_wallet/data/models/local_entities.dart';
import 'package:watch_my_wallet/providers/expense_provider.dart';

import '../core/utils/category_icons_data.dart';

class AddRecord extends StatefulWidget {
  const AddRecord({super.key});

  @override
  State<AddRecord> createState() => _AddRecordState();
}

enum RecordType { income, expense, transfer }

class _AddRecordState extends State<AddRecord> {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController attachmentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final ValueNotifier<String?> categoryValueNotifier = ValueNotifier<String?>(
    null,
  );
  final ValueNotifier<String?> accountValueNotifier = ValueNotifier<String?>(
    null,
  );
  final ValueNotifier<String?> toAccountValueNotifier = ValueNotifier<String?>(
    null,
  );

  RecordType _selectedType = RecordType.expense;
  String? _selectedAccountId;
  String? _selectedToAccountId;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  bool _isRecurring = false;
  String _recurringFrequency = 'monthly';
  final categoryIcons = CategoryIconsData();

  @override
  void initState() {
    super.initState();
    accountValueNotifier.value = _selectedAccountId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final provider = context.read<ExpenseProvider>();
        if (provider.accounts.isEmpty) {
          await provider.initialize(showLoader: false);
        }
        await provider.loadCategories(LocalTransactionType.expense);
      }
    });
  }

  @override
  void dispose() {
    categoryValueNotifier.dispose();
    accountValueNotifier.dispose();
    toAccountValueNotifier.dispose();
    descriptionController.dispose();
    amountController.dispose();
    attachmentController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitData() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null) {
      _showErrorSnackBar("Please select an account");
      return;
    }
    if (_selectedType != RecordType.transfer &&
        categoryValueNotifier.value == null) {
      _showErrorSnackBar("Please select a category");
      return;
    }
    if (_selectedType == RecordType.transfer &&
        _selectedAccountId == _selectedToAccountId) {
      _showErrorSnackBar("Source and Destination accounts cannot be the same");
      return;
    }
    if (_selectedType == RecordType.transfer && _selectedToAccountId == null) {
      _showErrorSnackBar("Please select a destination account");
      return;
    }
    if (_selectedType != RecordType.transfer && _selectedCategoryId == null) {
      _showErrorSnackBar("Please select a valid category");
      return;
    }

    final expenseProvider = context.read<ExpenseProvider>();

    try {
      final amount = double.tryParse(amountController.text) ?? 0.0;
      if (amount <= 0) {
        _showErrorSnackBar("Please enter a valid amount greater than 0");
        return;
      }

      if (_selectedType == RecordType.income) {
        _showIncomeDialog(
          amount,
          accountId: _selectedAccountId!,
          categoryId: _selectedCategoryId!,
        );
      } else if (_selectedType == RecordType.transfer) {
        final toAccount = _selectedToAccountId;
        if (toAccount == null) {
          _showErrorSnackBar("Please select a destination account");
          return;
        }
        await expenseProvider.addTransaction(
          amount: amount,
          type: LocalTransactionType.transfer,
          note: descriptionController.text.trim().isEmpty
              ? "Account Transfer"
              : descriptionController.text,
          date: _selectedDate,
          time: _selectedTime?.format(context),
          attachmentPath: attachmentController.text.trim().isEmpty
              ? null
              : attachmentController.text.trim(),
          isRecurring: _isRecurring,
          frequency: _recurringFrequency,
          accountId: _selectedAccountId!,
          toAccountId: toAccount,
          categoryId: 'category_transfer_default',
        );
        if (!mounted) return;
        if (expenseProvider.error != null) {
          _showErrorSnackBar(expenseProvider.error!);
        } else {
          Navigator.pop(context);
        }
      } else {
        final categoryId = _selectedCategoryId;
        if (categoryId == null) {
          _showErrorSnackBar("Please select a valid category");
          return;
        }
        await expenseProvider.addTransaction(
          amount: amount,
          type: LocalTransactionType.expense,
          note: descriptionController.text,
          date: _selectedDate,
          time: _selectedTime?.format(context),
          attachmentPath: attachmentController.text.trim().isEmpty
              ? null
              : attachmentController.text.trim(),
          isRecurring: _isRecurring,
          frequency: _recurringFrequency,
          accountId: _selectedAccountId!,
          categoryId: categoryId,
        );
        if (!mounted) return;
        if (expenseProvider.error != null) {
          _showErrorSnackBar(expenseProvider.error!);
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _showErrorSnackBar("Failed to save transaction. Please try again.");
    }
  }

  void _showIncomeDialog(
    double amount, {
    required String accountId,
    required String categoryId,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Income Strategy",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Would you like to add this income to your spending budget or store it as extra savings?",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (!mounted) return;
              final expenseProvider = context.read<ExpenseProvider>();
              Navigator.pop(dialogContext);
              await expenseProvider.addTransaction(
                toBudget: false,
                amount: amount,
                type: LocalTransactionType.income,
                note: descriptionController.text,
                date: _selectedDate,
                time: _selectedTime?.format(context),
                attachmentPath: attachmentController.text.trim().isEmpty
                    ? null
                    : attachmentController.text.trim(),
                isRecurring: _isRecurring,
                frequency: _recurringFrequency,
                accountId: accountId,
                categoryId: categoryId,
              );
              if (!mounted) return;
              if (expenseProvider.error != null) {
                _showErrorSnackBar(expenseProvider.error!);
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text(
              "Extra Income",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!mounted) return;
              final expenseProvider = context.read<ExpenseProvider>();
              Navigator.pop(dialogContext);
              await expenseProvider.addTransaction(
                toBudget: true,
                amount: amount,
                type: LocalTransactionType.income,
                note: descriptionController.text,
                date: _selectedDate,
                time: _selectedTime?.format(context),
                attachmentPath: attachmentController.text.trim().isEmpty
                    ? null
                    : attachmentController.text.trim(),
                isRecurring: _isRecurring,
                frequency: _recurringFrequency,
                accountId: accountId,
                categoryId: categoryId,
              );
              if (!mounted) return;
              if (expenseProvider.error != null) {
                _showErrorSnackBar(expenseProvider.error!);
              } else {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Add to Budget",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final isLoading = expenseProvider.isLoading;

    if (expenseProvider.accounts.isNotEmpty &&
        !expenseProvider.accounts.any(
          (account) => account.id == _selectedAccountId,
        )) {
      final cashAccount = expenseProvider.accounts.firstWhere(
        (account) => account.name.toLowerCase().contains('cash'),
        orElse: () => expenseProvider.accounts.first,
      );
      _selectedAccountId = cashAccount.id;
      accountValueNotifier.value = _selectedAccountId;
    }

    final currentLabels = expenseProvider.categories
        .map(
          (category) => <String, dynamic>{
            'label': category.name,
            'icon': categoryIcons.getCategoryIcon(category.name),
          },
        )
        .toList();

    final eligibleDestinationAccounts = expenseProvider.accounts
        .where((account) => account.id != _selectedAccountId)
        .toList();
    if (_selectedToAccountId == null &&
        eligibleDestinationAccounts.isNotEmpty) {
      _selectedToAccountId = eligibleDestinationAccounts.first.id;
      toAccountValueNotifier.value = _selectedToAccountId;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "New Transaction",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: SegmentedButton<RecordType>(
                      segments: const [
                        ButtonSegment(
                          value: RecordType.expense,
                          label: Text("Expense"),
                          icon: Icon(Icons.remove_circle_outline),
                        ),
                        ButtonSegment(
                          value: RecordType.income,
                          label: Text("Income"),
                          icon: Icon(Icons.add_circle_outline),
                        ),
                        ButtonSegment(
                          value: RecordType.transfer,
                          label: Text("Transfer"),
                          icon: Icon(Icons.swap_horiz),
                        ),
                      ],
                      selected: {_selectedType},
                      onSelectionChanged: (val) async {
                        final selectedType = val.first;
                        categoryValueNotifier.value = null;
                        _selectedCategoryId = null;
                        setState(() {
                          _selectedType = selectedType;
                        });
                        if (selectedType != RecordType.transfer) {
                          await expenseProvider.loadCategories(
                            selectedType == RecordType.income
                                ? LocalTransactionType.income
                                : LocalTransactionType.expense,
                          );
                        }
                      },
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: Colors.black,
                        selectedForegroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "Amount",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.currency_rupee,
                        color: Colors.black,
                        size: 32,
                      ),
                      hintText: "0.00",
                      border: InputBorder.none,
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter amount' : null,
                  ),
                  const Divider(),
                  const SizedBox(height: 24),
                  if (_selectedType != RecordType.transfer) ...[
                    const Text(
                      "Category",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField2<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      hint: const Text('Select Category'),
                      valueListenable: categoryValueNotifier,
                      items: currentLabels
                          .map(
                            (item) => DropdownItem<String>(
                              value: item['label'],
                              child: Row(
                                children: [
                                  Icon(item['icon'], color: Colors.black87),
                                  const SizedBox(width: 12),
                                  Text(item['label']),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        categoryValueNotifier.value = value;
                        final matchingCategories = expenseProvider.categories
                            .where((category) => category.name == value)
                            .toList();
                        _selectedCategoryId = matchingCategories.isEmpty
                            ? null
                            : matchingCategories.first.id;
                      },
                      validator: (value) =>
                          value == null ? 'Select category' : null,
                      dropdownStyleData: DropdownStyleData(
                        maxHeight: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        scrollbarTheme: ScrollbarThemeData(
                          radius: const Radius.circular(40),
                          thickness: WidgetStateProperty.all(6),
                          thumbVisibility: WidgetStateProperty.all(true),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    _selectedType == RecordType.transfer
                        ? "From Account"
                        : "Account",
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField2<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    hint: const Text('Select Account'),
                    valueListenable: accountValueNotifier,
                    items: expenseProvider.accounts
                        .map(
                          (account) => DropdownItem<String>(
                            value: account.id,
                            child: Text(account.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedAccountId = value;
                          _selectedToAccountId = null;
                        });
                        accountValueNotifier.value = value;
                        toAccountValueNotifier.value = null;
                      }
                    },
                    validator: (value) =>
                        value == null ? 'Select account' : null,
                    dropdownStyleData: DropdownStyleData(
                      maxHeight: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      scrollbarTheme: ScrollbarThemeData(
                        radius: const Radius.circular(40),
                        thickness: WidgetStateProperty.all(6),
                        thumbVisibility: WidgetStateProperty.all(true),
                      ),
                    ),
                  ),
                  if (_selectedType == RecordType.transfer) ...[
                    const SizedBox(height: 24),
                    const Text(
                      "To Account",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField2<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      hint: const Text('Select Target Account'),
                      valueListenable: toAccountValueNotifier,
                      items: eligibleDestinationAccounts
                          .map(
                            (account) => DropdownItem<String>(
                              value: account.id,
                              child: Text(account.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedToAccountId = value);
                          toAccountValueNotifier.value = value;
                        }
                      },
                      validator: (value) =>
                          value == null ? 'Select target account' : null,
                      dropdownStyleData: DropdownStyleData(
                        maxHeight: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        scrollbarTheme: ScrollbarThemeData(
                          radius: const Radius.circular(40),
                          thickness: WidgetStateProperty.all(6),
                          thumbVisibility: WidgetStateProperty.all(true),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    "Date",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.black87,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('MMM dd, yyyy').format(_selectedDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _selectedTime ?? TimeOfDay.now(),
                            );
                            if (picked != null && mounted) {
                              setState(() => _selectedTime = picked);
                            }
                          },
                          icon: const Icon(Icons.schedule),
                          label: Text(
                            _selectedTime?.format(context) ?? 'Add time',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Recurring'),
                          value: _isRecurring,
                          onChanged: (value) =>
                              setState(() => _isRecurring = value),
                        ),
                      ),
                    ],
                  ),
                  if (_isRecurring) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _recurringFrequency,
                      decoration: const InputDecoration(
                        labelText: 'Repeat frequency',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'weekly',
                          child: Text('Weekly'),
                        ),
                        DropdownMenuItem(
                          value: 'monthly',
                          child: Text('Monthly'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null && mounted) {
                          setState(() => _recurringFrequency = value);
                        }
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'A new transaction will be created automatically on each ${_recurringFrequency == 'weekly' ? 'week' : 'month'} when the app starts.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: attachmentController,
                    decoration: InputDecoration(
                      labelText: 'Attachment path (optional)',
                      prefixIcon: const Icon(Icons.attach_file),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Description",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      hintText: _selectedType == RecordType.transfer
                          ? "e.g., Monthly savings shift"
                          : "e.g., Grocery store",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) =>
                        _selectedType != RecordType.transfer &&
                            (value == null || value.isEmpty)
                        ? 'Enter description'
                        : null,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submitData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Save Transaction",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: const Center(child: CircularProgressIndicator.adaptive()),
            ),
        ],
      ),
    );
  }
}
