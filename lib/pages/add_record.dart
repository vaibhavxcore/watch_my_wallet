import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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

  final List<Map<String, dynamic>> expenseLabels = [
    {'label': 'Food', 'icon': Icons.fastfood_rounded},
    {'label': 'Grocery', 'icon': Icons.shopping_cart_rounded},
    {'label': 'Transport', 'icon': Icons.directions_bus_rounded},
    {'label': 'Fuel', 'icon': Icons.local_gas_station_rounded},
    {'label': 'Shopping', 'icon': Icons.shopping_bag_rounded},
    {'label': 'Rent', 'icon': Icons.home_rounded},
    {'label': 'Bills', 'icon': Icons.receipt_long_rounded},
    {'label': 'Entertainment', 'icon': Icons.movie_rounded},
    {'label': 'Medical', 'icon': Icons.medical_services_rounded},
    {'label': 'Education', 'icon': Icons.school_rounded},
    {'label': 'Others', 'icon': Icons.more_horiz_rounded},
  ];

  final List<Map<String, dynamic>> incomeLabels = [
    {'label': 'Salary', 'icon': Icons.payments_rounded},
    {'label': 'Business', 'icon': Icons.business_center_rounded},
    {'label': 'Freelance', 'icon': Icons.laptop_mac_rounded},
    {'label': 'Investments', 'icon': Icons.trending_up_rounded},
    {'label': 'Gift', 'icon': Icons.card_giftcard_rounded},
    {'label': 'Others', 'icon': Icons.more_horiz_rounded},
  ];

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

  void _submitData() {
    if (!_formKey.currentState!.validate()) return;
    if (labelValueListenable.value == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a category")));
      return;
    }

    final newRecord = Record(
      type: _selectedType == RecordType.income ? "Income" : "Expense",
      details: detailController.text,
      description: descriptionController.text,
      amount: double.parse(amountController.text),
      labelText: labelValueListenable.value.toString(),
      date: _selectedDate,
    );

    _recordDatabase.createRecord(newRecord);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> currentLabels =
        _selectedType == RecordType.expense ? expenseLabels : incomeLabels;

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
              // 1. Segmented Toggle
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
                    // Reset the selected label value when changing type
                    labelValueListenable.value = null;
                  }),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: Colors.black,
                    selectedForegroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 2. Amount Input
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

              // 3. Category Dropdown
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
                onChanged: (value) {
                  labelValueListenable.value = value;
                },
                validator: (value) => value == null ? 'Select category' : null,
                dropdownStyleData: DropdownStyleData(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 4. Date Picker
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
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

              // 5. Description Field
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
              const SizedBox(height: 24),

              // 6. Notes Field
              const Text(
                "Notes (Optional)",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: detailController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: "Add details...",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Save Button
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
                    elevation: 0,
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
