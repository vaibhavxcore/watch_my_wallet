import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:watch_my_wallet/core/utils/category_icons_data.dart';
import 'package:watch_my_wallet/core/utils/insight_metrics.dart';
import 'package:watch_my_wallet/data/models/local_entities.dart';
import 'package:watch_my_wallet/providers/expense_provider.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  final _categoryData = CategoryIconsData();
  InsightRange _range = InsightRange.month;
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final transactions = InsightMetrics.forRange(provider.transactions, _range);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          'Insights',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: provider.isLoading && provider.transactions.isEmpty
          ? const Center(child: CircularProgressIndicator.adaptive())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _rangeSelector(),
                  const SizedBox(height: 28),
                  _header('Expense Breakdown', _rangeLabel),
                  const SizedBox(height: 20),
                  _categoryChart(transactions, provider.categoryName),
                  const SizedBox(height: 40),
                  _header('Financial Trend', _rangeLabel),
                  const SizedBox(height: 20),
                  _trendChart(transactions),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  String get _rangeLabel => switch (_range) {
    InsightRange.week => 'This week',
    InsightRange.month => 'This month',
    InsightRange.threeMonths => 'Last 3 months',
    InsightRange.year => 'This year',
  };

  Widget _rangeSelector() => SegmentedButton<InsightRange>(
    showSelectedIcon: false,
    segments: const [
      ButtonSegment(value: InsightRange.week, label: Text('Week')),
      ButtonSegment(value: InsightRange.month, label: Text('Month')),
      ButtonSegment(value: InsightRange.threeMonths, label: Text('3 Months')),
      ButtonSegment(value: InsightRange.year, label: Text('Year')),
    ],
    selected: {_range},
    onSelectionChanged: (value) => setState(() {
      _range = value.first;
      _touchedIndex = -1;
    }),
  );

  Widget _header(String title, String subtitle) => Column(
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

  Widget _categoryChart(
    List<LocalTransaction> transactions,
    String Function(String) categoryName,
  ) {
    final totals = InsightMetrics.expenseByCategory(transactions, categoryName);
    if (totals.isEmpty) return _empty('No expenses recorded in this period');
    final entries = totals.entries.toList();
    final total = totals.values.fold(0.0, (sum, amount) => sum + amount);
    return _card(
      Column(
        children: [
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) => setState(() {
                    _touchedIndex =
                        event.isInterestedForInteractions &&
                            response?.touchedSection != null
                        ? response!.touchedSection!.touchedSectionIndex
                        : -1;
                  }),
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 4,
                centerSpaceRadius: 55,
                sections: List.generate(entries.length, (index) {
                  final entry = entries[index];
                  return PieChartSectionData(
                    color: _categoryData.getCategoryColor(entry.key),
                    value: entry.value,
                    title: '${(entry.value / total * 100).toStringAsFixed(0)}%',
                    radius: index == _touchedIndex ? 65 : 55,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 25),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: entries
                .map(
                  (entry) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _categoryData.getCategoryColor(entry.key),
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
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _trendChart(List<LocalTransaction> transactions) {
    if (transactions.isEmpty) {
      return _empty('No transactions recorded in this period');
    }
    final points = InsightMetrics.trendPoints(_range);
    final values = [
      for (final point in points) ...[
        InsightMetrics.totalFor(
          transactions,
          point,
          LocalTransactionType.income,
        ),
        InsightMetrics.totalFor(
          transactions,
          point,
          LocalTransactionType.expense,
        ),
      ],
    ];
    final peak = values.fold(0.0, (max, value) => value > max ? value : max);
    final labelStep = _range == InsightRange.month ? 5 : 1;
    return SizedBox(
      height: 330,
      child: _card(
        BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: peak == 0 ? 1000 : peak * 1.2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.black.withValues(alpha: 0.8),
                getTooltipItem: (_, _, rod, _) => BarTooltipItem(
                  '₹${NumberFormat.compact().format(rod.toY)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    final index = value.toInt();
                    if (index < 0 ||
                        index >= points.length ||
                        index % labelStep != 0) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        points[index].label,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(
              points.length,
              (index) => BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: InsightMetrics.totalFor(
                      transactions,
                      points[index],
                      LocalTransactionType.income,
                    ),
                    color: const Color(0xFF2E7D32),
                    width: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  BarChartRodData(
                    toY: InsightMetrics.totalFor(
                      transactions,
                      points[index],
                      LocalTransactionType.expense,
                    ),
                    color: const Color(0xFFC62828),
                    width: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(String message) => _card(
    SizedBox(
      height: 200,
      child: Center(
        child: Text(message, style: const TextStyle(color: Colors.grey)),
      ),
    ),
  );

  Widget _card(Widget child) => Container(
    width: double.infinity,
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
    child: child,
  );
}
