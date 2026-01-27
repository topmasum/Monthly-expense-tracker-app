import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../utils/currency_helper.dart'; // <--- 1. IMPORT THIS

class TrackerPage extends StatefulWidget {
  final List<Expense> expenses;
  const TrackerPage({super.key, required this.expenses});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  late DateTime _focusedDate;

  @override
  void initState() {
    super.initState();
    _focusedDate = DateTime.now();
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedDate = DateTime(
        _focusedDate.year,
        _focusedDate.month + offset,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter expenses for the FOCUSED month
    final currentMonthExpenses = widget.expenses.where((e) {
      return e.date.year == _focusedDate.year &&
          e.date.month == _focusedDate.month;
    }).toList();

    final totalMonth =
    currentMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);

    // Group by category for the chart
    Map<Category, double> categoryTotals = {};
    for (var e in currentMonthExpenses) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // MONTH SELECTOR HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  DateFormat.yMMMM().format(_focusedDate),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // TOTAL PILL (NOW USING CURRENCY HELPER)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.1)
                      : Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                // 2. UPDATED HERE:
                child: Text(
                  CurrencyHelper.format(totalMonth),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Theme.of(context).primaryColor,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // BODY (Chart or Empty Message)
            Expanded(
              child: currentMonthExpenses.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart,
                        size: 60, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      "No expenses in ${DateFormat.MMMM().format(_focusedDate)}",
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
                  : Column(
                children: [
                  // PIE CHART
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: categoryTotals.entries.map((entry) {
                          final percentage =
                              (entry.value / totalMonth) * 100;
                          return PieChartSectionData(
                            color: _getCategoryColor(entry.key),
                            value: entry.value,
                            title: '${percentage.toStringAsFixed(0)}%',
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // LEGEND LIST (NOW USING CURRENCY HELPER)
                  Expanded(
                    child: ListView(
                      children: categoryTotals.entries.map((entry) {
                        return ListTile(
                          visualDensity: VisualDensity.compact,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor:
                            _getCategoryColor(entry.key),
                            child: Icon(_getCategoryIcon(entry.key),
                                color: Colors.white, size: 16),
                          ),
                          title: Text(
                            entry.key.name.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          // 3. UPDATED HERE:
                          trailing: Text(
                            CurrencyHelper.format(entry.value),
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---
  Color _getCategoryColor(Category c) {
    switch (c) {
      case Category.food: return Colors.orange;
      case Category.transport: return Colors.blue;
      case Category.bills: return Colors.red;
      case Category.shopping: return Colors.purple;
      case Category.entertainment: return Colors.pink;
      case Category.health: return Colors.teal;
      case Category.other: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(Category c) {
    switch (c) {
      case Category.food: return Icons.lunch_dining;
      case Category.transport: return Icons.directions_car;
      case Category.bills: return Icons.receipt_long;
      case Category.shopping: return Icons.shopping_bag_outlined;
      case Category.entertainment: return Icons.movie_creation_outlined;
      case Category.health: return Icons.health_and_safety;
      case Category.other: return Icons.category_outlined;
    }
  }
}