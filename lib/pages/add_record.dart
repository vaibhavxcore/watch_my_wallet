import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:watch_my_wallet/core/utils/category_icons_data.dart';
import 'package:watch_my_wallet/record.dart';
import 'package:watch_my_wallet/record_database.dart';

class AddRecord extends StatefulWidget {
  const AddRecord({super.key});

  @override
  State<AddRecord> createState() => _AddRecordState();
}

enum RecordType { income, expense }

class _AddRecordState extends State<AddRecord> {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController detailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final ValueNotifier<String?> labelValueListenable = ValueNotifier<String?>(
    null,
  );

  RecordType _selectedType = RecordType.expense;
  DateTime _selectedDate = DateTime.now();
  final categoryIcons = CategoryIconsData();

  final RecordDatabase _recordDatabase = RecordDatabase();

  @override
  void dispose() {
    labelValueListenable.dispose();
    descriptionController.dispose();
    amountController.dispose();
    detailController.dispose();
    super.dispose();
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitData() async {
    if (!_formKey.currentState!.validate()) return;
    if (labelValueListenable.value == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a category")));
      return;
    }

    final amount = double.parse(amountController.text);
    final newRecord = Record(
      type: _selectedType == RecordType.income ? "Income" : "Expense",
      details: detailController.text,
      description: descriptionController.text,
      amount: amount,
      labelText: labelValueListenable.value.toString(),
      date: _selectedDate,
    );

    if (_selectedType == RecordType.income) {
      _showIncomeDialog(newRecord, amount);
    } else {
      await _recordDatabase.createRecord(newRecord);
      if (mounted) Navigator.pop(context);
    }
  }

  void _showIncomeDialog(Record record, double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Income Strategy",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Would you like to add this income to your spending budget or store it as extra income (savings)?",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _recordDatabase.createRecord(record);
              await _recordDatabase.addIncomeToSavings(amount);
              if (mounted) Navigator.pop(this.context);
            },
            child: const Text(
              "Extra Income",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _recordDatabase.createRecord(record);
              await _recordDatabase.addIncomeToBudget(amount);
              if (mounted) Navigator.pop(this.context);
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
    List<Map<String, dynamic>> currentLabels =
        _selectedType == RecordType.expense
        ? categoryIcons.expenseLabels
        : categoryIcons.incomeLabels;

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
      body: SingleChildScrollView(
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
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (val) => setState(() {
                    _selectedType = val.first;
                    labelValueListenable.value = null;
                  }),
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
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
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
                validator: (value) => value!.isEmpty ? 'Enter amount' : null,
              ),
              const Divider(),
              const SizedBox(height: 24),
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
                valueListenable: labelValueListenable,
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
                onChanged: (value) => labelValueListenable.value = value,
                validator: (value) => value == null ? 'Select category' : null,
              ),
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
                      const Icon(Icons.calendar_today, color: Colors.black87),
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
                  hintText: "e.g., Grocery store",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
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
    );
  }
}
