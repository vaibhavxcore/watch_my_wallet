import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watch_my_wallet/record.dart';
import 'package:watch_my_wallet/record_database.dart';

class AddRecord extends StatefulWidget {
  const AddRecord({super.key});

  @override
  State<AddRecord> createState() => _AddRecordState();
}

enum RecordType { income, expense }

final List<Map<String, dynamic>> listLabel = [
  {'label': 'Food', 'icon': Icons.fastfood},
  {'label': 'Grocery', 'icon': Icons.shopping_cart},
  {'label': 'Travelling', 'icon': Icons.directions_car},
  {'label': 'Fuel', 'icon': Icons.local_gas_station},
];

final valueListenable = ValueNotifier<String?>(null);

class _AddRecordState extends State<AddRecord> {
  TextEditingController descriptionController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController detailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  RecordType? _recordType;
  String recordValue = "";
  final RecordDatabase _recordDatabase = RecordDatabase();

  void _showDialog() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Record added")));
  }

  void _addRecord() {
    if (!_formKey.currentState!.validate()) return;
    if (_recordType == null) return;

    final newRecord = Record(
      type: recordValue.toString(),
      details: detailController.text,
      description: descriptionController.text,
      amount: double.parse(amountController.text),
      labelText: valueListenable.value.toString(),
    );
    _recordDatabase.createRecord(newRecord);
    _showDialog();

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Record"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              //Radio Button I/E
              RadioGroup<RecordType>(
                groupValue: _recordType,
                onChanged: (RecordType? record) {
                  setState(() {
                    _recordType = record;
                    recordValue = (record == RecordType.income)
                        ? "Income"
                        : "Expense";
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Radio<RecordType>(value: RecordType.income),
                    Text("Income"),

                    const SizedBox(width: 50),
                    Radio<RecordType>(value: RecordType.expense),
                    Text("Expense"),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              //Description textfield
              TextFormField(
                controller: descriptionController,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter an description' : null,
                decoration: InputDecoration(
                  hintText: "Description",
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              //label dropdown
              DropdownButtonFormField2<String>(
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 22,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    gapPadding: 0,
                  ),
                ),
                hint: const Text(
                  'Select Label',
                  style: TextStyle(fontSize: 14),
                ),

                items: listLabel
                    .map(
                      (item) => DropdownItem<String>(
                        value: item['label'],
                        child: Row(
                          children: [
                            Icon(item['icon'], size: 22),
                            const SizedBox(width: 10),
                            Text(item['label']),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                valueListenable: valueListenable,
                validator: (value) {
                  if (value == null) {
                    return 'Select a Label';
                  }
                  return null;
                },
                onChanged: (value) {
                  valueListenable.value = value;
                },
                iconStyleData: const IconStyleData(
                  icon: Icon(Icons.arrow_drop_down, color: Colors.black45),
                ),
                dropdownStyleData: DropdownStyleData(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                menuItemStyleData: const MenuItemStyleData(
                  useDecorationHorizontalPadding: true,
                ),
              ),

              const SizedBox(height: 20),

              //amount textfirld
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) =>
                    value!.isEmpty ? 'Please enter an amount' : null,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.currency_rupee),
                  hintText: "Enter Amount",
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              //details textfield
              TextFormField(
                controller: detailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value!.isEmpty ? 'Enter some details' : null,
                decoration: InputDecoration(
                  hintText: "Details",
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _addRecord(),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  child: Text(
                    "Add Record",
                    style: TextStyle(color: Colors.white),
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
