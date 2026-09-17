import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:watch_my_wallet/core/utils/category_icons_data.dart';
import 'package:watch_my_wallet/record.dart';
import 'package:watch_my_wallet/record_database.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  final recordDB = RecordDatabase();
  final categoryData = CategoryIconsData();
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          "Insights",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
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
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Not enough data for insights yet.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("Expense Breakdown", "Current Month"),
                const SizedBox(height: 20),
                _buildCategoryChart(records),
                const SizedBox(height: 40),
                _buildSectionHeader("Financial Trend", "Last 6 Months"),
                const SizedBox(height: 20),
                _buildTrendChart(records),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1C1E),
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChart(List<Record> records) {
    final now = DateTime.now();
    final currentMonthExpenses = records
        .where(
          (r) =>
              r.type == "Expense" &&
              r.date.month == now.month &&
              r.date.year == now.year,
        )
        .toList();

    if (currentMonthExpenses.isEmpty) {
      return _buildEmptyState("No expenses recorded this month");
    }

    Map<String, double> categoryMap = {};
    double total = 0;
    for (var rec in currentMonthExpenses) {
      categoryMap[rec.labelText] =
          (categoryMap[rec.labelText] ?? 0) + rec.amount;
      total += rec.amount;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 4,
                centerSpaceRadius: 55,
                sections: categoryMap.entries.map((entry) {
                  final index = categoryMap.keys.toList().indexOf(entry.key);
                  final isTouched = index == touchedIndex;
                  final radius = isTouched ? 65.0 : 55.0;

                  return PieChartSectionData(
                    color: categoryData.getCategoryColor(entry.key),
                    value: entry.value,
                    title: '${(entry.value / total * 100).toStringAsFixed(0)}%',
                    radius: radius,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 25),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: categoryMap.entries.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: categoryData.getCategoryColor(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3243),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<Record> records) {
    final now = DateTime.now();
    List<DateTime> months = List.generate(
      6,
      (i) => DateTime(now.year, now.month - (5 - i), 1),
    );

    return Container(
      height: 330,
      padding: const EdgeInsets.fromLTRB(10, 30, 20, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(records, months),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.black.withValues(alpha: 0.8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '₹${NumberFormat.compact().format(rod.toY)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < months.length) {
                    return Text(
                      DateFormat('MMM').format(months[index]),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: months.asMap().entries.map((entry) {
            int index = entry.key;
            DateTime month = entry.value;

            double income = records
                .where(
                  (r) =>
                      r.type == "Income" &&
                      r.date.month == month.month &&
                      r.date.year == month.year,
                )
                .fold(0, (sum, r) => sum + r.amount);

            double expense = records
                .where(
                  (r) =>
                      r.type == "Expense" &&
                      r.date.month == month.month &&
                      r.date.year == month.year,
                )
                .fold(0, (sum, r) => sum + r.amount);

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: income,
                  color: const Color(0xFF2E7D32),
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: expense,
                  color: const Color(0xFFC62828),
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
      ),
      child: Center(
        child: Text(message, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }

  double _getMaxY(List<Record> records, List<DateTime> months) {
    double maxVal = 0;
    for (var month in months) {
      double inc = records
          .where(
            (r) =>
                r.type == "Income" &&
                r.date.month == month.month &&
                r.date.year == month.year,
          )
          .fold(0, (sum, r) => sum + r.amount);
      double exp = records
          .where(
            (r) =>
                r.type == "Expense" &&
                r.date.month == month.month &&
                r.date.year == month.year,
          )
          .fold(0, (sum, r) => sum + r.amount);
      if (inc > maxVal) maxVal = inc;
      if (exp > maxVal) maxVal = exp;
    }
    return maxVal == 0 ? 1000 : maxVal * 1.2;
  }
}
