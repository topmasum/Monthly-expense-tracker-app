import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/storage_service.dart';
import '../utils/currency_helper.dart';
import 'budget_page.dart';

class TrackerPage extends StatefulWidget {
  final List<Expense> expenses;
  const TrackerPage({super.key, required this.expenses});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  late DateTime _focusedDate;
  Map<Category, double> _budgets = {};

  @override
  void initState() {
    super.initState();
    _focusedDate = DateTime.now();
    _loadBudgets();
  }

  void _loadBudgets() {
    setState(() {
      // 1. NEW: Fetch budgets for the currently focused month
      _budgets = StorageService.getBudgets(_focusedDate);
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedDate = DateTime(
        _focusedDate.year,
        _focusedDate.month + offset,
      );
      // 2. NEW: Reload budgets when month changes
      _loadBudgets();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 3. Filter Expenses
    final currentMonthExpenses = widget.expenses.where((e) {
      return e.date.year == _focusedDate.year &&
          e.date.month == _focusedDate.month;
    }).toList();

    final totalSpent = currentMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);

    Map<Category, double> categoryTotals = {};
    for (var e in currentMonthExpenses) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }

    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalBudgetLimit = _budgets.values.fold(0.0, (sum, val) => sum + val);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => _changeMonth(-1),
              ),
              Text(
                DateFormat.yMMMM().format(_focusedDate),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Total Pill
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
              child: Text(
                CurrencyHelper.format(totalSpent),
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

          // Budget Card
          _buildBudgetSummaryCard(totalSpent, totalBudgetLimit),

          const SizedBox(height: 20),

          // Content
          if (currentMonthExpenses.isEmpty)
            Container(
              height: 200,
              alignment: Alignment.center,
              child: Text(
                "No expenses this month",
                style: TextStyle(color: Colors.grey[500]),
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: sortedEntries.map((entry) {
                        final percentage = (entry.value / totalSpent) * 100;
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

                const SizedBox(height: 30),

                ...sortedEntries.map((entry) {
                  final cat = entry.key;
                  final spent = entry.value;
                  final limit = _budgets[cat] ?? 0.0;

                  double progress = 0.0;
                  if (limit > 0) progress = (spent / limit).clamp(0.0, 1.0);

                  Color progressColor = Colors.green;
                  if (progress > 0.7) progressColor = Colors.orange;
                  if (progress >= 1.0) progressColor = Colors.red;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: _getCategoryColor(cat),
                            child: Icon(_getCategoryIcon(cat), color: Colors.white, size: 18),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(cat.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(
                                limit > 0
                                    ? "${CurrencyHelper.format(spent)} / ${CurrencyHelper.format(limit)}"
                                    : CurrencyHelper.format(spent),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: (limit > 0 && spent > limit) ? Colors.red : Theme.of(context).textTheme.bodyMedium?.color
                                ),
                              ),
                            ],
                          ),
                          subtitle: limit > 0
                              ? Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey[200],
                              color: progressColor,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          )
                              : null,
                        ),
                        Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 80),
              ],
            ),
        ],
      ),
    );
  }
  Widget _buildBudgetSummaryCard(double spent, double totalLimit) {
    // 1. CHECK THEME
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Define a High-Visibility color for links/bars in dark mode
    final highlightColor = isDark ? Colors.blue[200] : Theme.of(context).primaryColor;

    if (totalLimit == 0) {
      return Card(
        elevation: 0,
        color: isDark ? Colors.blue.withOpacity(0.15) : Colors.blue.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(
              builder: (_) => BudgetPage(month: _focusedDate),
            ));
            _loadBudgets();
          },
          leading: const Icon(Icons.account_balance_wallet, color: Colors.blue),
          title: const Text("No Monthly Budget Set", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: const Text("Tap to start planning", style: TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blue),
        ),
      );
    }

    final progress = (spent / totalLimit).clamp(0.0, 1.0);
    final remaining = totalLimit - spent;

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => BudgetPage(month: _focusedDate),
          ));
          _loadBudgets();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Monthly Budget", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  // FIX 1: Explicitly use Light Blue in Dark Mode so it's not black
                  Text("Edit Limits", style: TextStyle(fontSize: 12, color: highlightColor, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),

              LinearProgressIndicator(
                value: progress,
                // FIX 2: Use 'white24' for the empty track in dark mode (looks much better than grey)
                backgroundColor: isDark ? Colors.white24 : Colors.grey[200],
                // FIX 3: Ensure the filled bar is bright
                color: progress > 1.0 ? Colors.red : (isDark ? Colors.blueAccent : Theme.of(context).primaryColor),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${(progress * 100).toStringAsFixed(0)}% Used",
                    style: TextStyle(
                        fontSize: 12,
                        // FIX 4: Ensure text is Light Grey in dark mode
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  Text(
                    remaining >= 0
                        ? "${CurrencyHelper.format(remaining)} left"
                        : "${CurrencyHelper.format(remaining.abs())} over",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: remaining >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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