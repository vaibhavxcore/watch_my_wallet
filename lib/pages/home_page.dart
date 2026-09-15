import 'package:flutter/material.dart';
import 'package:watch_my_wallet/record.dart';
import 'package:watch_my_wallet/record_database.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final recordDB = RecordDatabase();

  IconData getCategoryIcon(String label) {
    switch (label) {
      case 'Food':
        return Icons.fastfood_rounded;
      case 'Grocery':
        return Icons.shopping_cart_rounded;
      case 'Transport':
        return Icons.directions_bus_rounded;
      case 'Fuel':
        return Icons.local_gas_station_rounded;
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Rent':
        return Icons.home_rounded;
      case 'Bills':
        return Icons.receipt_long_rounded;
      case 'Entertainment':
        return Icons.movie_rounded;
      case 'Medical':
        return Icons.medical_services_rounded;
      case 'Education':
        return Icons.school_rounded;
      case 'Salary':
        return Icons.payments_rounded;
      case 'Business':
        return Icons.business_center_rounded;
      case 'Freelance':
        return Icons.laptop_mac_rounded;
      case 'Investments':
        return Icons.trending_up_rounded;
      case 'Gift':
        return Icons.card_giftcard_rounded;
      default:
        return Icons.more_horiz_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<List<Record>>(
        stream: recordDB.stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          final records = snapshot.data!;
          double totalIncome = 0;
          double totalExpense = 0;
          for (var rec in records) {
            if (rec.type == "Income") {
              totalIncome += rec.amount;
            } else {
              totalExpense += rec.amount;
            }
          }
          double balance = totalIncome - totalExpense;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(25, 60, 25, 0),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome back,",
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "Watch My Wallet",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 130,
                        left: 20,
                        right: 20,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Total Balance",
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "₹${balance.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMiniSummary(
                                  "Income",
                                  totalIncome,
                                  Colors.green,
                                ),
                                _buildMiniSummary(
                                  "Expense",
                                  totalExpense,
                                  Colors.red,
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(25, 30, 25, 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Recent Transactions",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          "View All",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              records.isEmpty
                  ? const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text("No transactions yet")),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final rec = records[index];
                          final isIncome = rec.type == "Income";
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              // Added Material for Ink Splashes
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                // Added InkWell for splash effect
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {},
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      getCategoryIcon(rec.labelText),
                                      color: Colors.black,
                                    ),
                                  ),
                                  title: Text(
                                    rec.description,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    rec.labelText,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "${isIncome ? '+' : '-'} ₹${rec.amount.toStringAsFixed(2)}",
                                        style: TextStyle(
                                          color: isIncome
                                              ? Colors.green[700]
                                              : Colors.red[700],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Text(
                                        "Today",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 11,
                                        ),
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
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMiniSummary(String title, double amount, Color color) {
    return Row(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(
            title == "Income" ? Icons.arrow_downward : Icons.arrow_upward,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              "₹${amount.toStringAsFixed(0)}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }
}
