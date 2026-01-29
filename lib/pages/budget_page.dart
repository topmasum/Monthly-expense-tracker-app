import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/storage_service.dart';
import '../utils/currency_helper.dart';

class BudgetPage extends StatefulWidget {
  final DateTime month; // <--- 1. NEW: Requires a month

  const BudgetPage({super.key, required this.month});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  Map<Category, double> _budgets = {};

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  void _loadBudgets() {
    setState(() {
      // 2. NEW: Load budgets for the SPECIFIC month
      _budgets = StorageService.getBudgets(widget.month);
    });
  }

  double _calculateTotalBudget() {
    return _budgets.values.fold(0.0, (sum, val) => sum + val);
  }

  Future<void> _showBudgetEditor(Category category) async {
    final currentLimit = _budgets[category] ?? 0.0;
    final textVal = currentLimit > 0
        ? (currentLimit % 1 == 0 ? currentLimit.toInt().toString() : currentLimit.toString())
        : '';

    final controller = TextEditingController(text: textVal);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 30,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getCategoryColor(category).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_getCategoryIcon(category), size: 32, color: _getCategoryColor(category)),
            ),
            const SizedBox(height: 16),

            Text(
              "Set limit for ${category.name.toUpperCase()}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                prefix: Text(
                  StorageService.getCurrency(),
                  style: TextStyle(
                      fontSize: 40,
                      color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.5)
                  ),
                ),
                hintText: "0",
                hintStyle: TextStyle(color: Theme.of(context).hintColor),
                border: InputBorder.none,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),

            const SizedBox(height: 10),
            const Text("Monthly Limit", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.red.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      // 3. NEW: Pass widget.month here
                      await StorageService.saveBudget(category, 0.0, widget.month);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadBudgets();
                    },
                    child: const Text("Remove Limit", style: TextStyle(color: Colors.red)),
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final amount = double.tryParse(controller.text) ?? 0.0;
                      // 4. NEW: Pass widget.month here
                      await StorageService.saveBudget(category, amount, widget.month);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadBudgets();
                    },
                    child: const Text("Save Limit", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalBudget = _calculateTotalBudget();
    // 5. NEW: Show formatted month in title
    final monthName = DateFormat('MMMM yyyy').format(widget.month);

    return Scaffold(
      appBar: AppBar(
        title: Text("Budgets for $monthName"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.deepPurple.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  "Total Monthly Budget",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyHelper.format(totalBudget),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: Category.values.map((cat) {
                final limit = _budgets[cat] ?? 0.0;
                final isSet = limit > 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSet ? _getCategoryColor(cat).withOpacity(0.3) : Colors.transparent,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(cat).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_getCategoryIcon(cat), color: _getCategoryColor(cat)),
                    ),
                    title: Text(
                      cat.name.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(
                      isSet ? "Limit: ${CurrencyHelper.format(limit)}" : "Tap to set limit",
                      style: TextStyle(
                        color: isSet ? Colors.grey[700] : Colors.grey[400],
                        fontWeight: isSet ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    trailing: isSet
                        ? Icon(Icons.check_circle, color: _getCategoryColor(cat), size: 20)
                        : const Icon(Icons.add_circle_outline, color: Colors.grey),
                    onTap: () => _showBudgetEditor(cat),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
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