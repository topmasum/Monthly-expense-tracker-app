import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/storage_service.dart';
import '../widgets/expense_card.dart';
import 'tracker_page.dart';
import 'dart:math';

class HomePage extends StatefulWidget {
  final Function(bool) onThemeToggle;
  final bool isDark;

  const HomePage({
    super.key,
    required this.onThemeToggle,
    required this.isDark,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Expense> _expenses = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _loadExpenses() {
    setState(() {
      _expenses = StorageService.getAllExpenses();
    });
  }

  Future<void> _addOrEditExpense({Expense? existing}) async {
    final nameController =
    TextEditingController(text: existing?.name ?? '');
    final amountController = TextEditingController(
        text: existing != null ? existing.amount.toString() : '');

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Expense' : 'Edit Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Expense name'),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final amount = double.tryParse(amountController.text) ?? 0.0;

              if (name.isEmpty || amount <= 0) return;

              if (existing == null) {
                // Create a new expense
                final id = DateTime.now()
                    .millisecondsSinceEpoch
                    .toString() +
                    Random().nextInt(9999).toString();
                final newExpense = Expense(
                  id: id,
                  name: name,
                  amount: amount,
                  date: DateTime.now(),
                );
                await StorageService.addExpense(newExpense);
              } else {
                // Update existing
                existing.name = name;
                existing.amount = amount;
                existing.date = DateTime.now();
                await StorageService.updateExpense(existing);
              }

              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) _loadExpenses();
  }

  Future<void> _deleteExpense(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete'),
        content:
        const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.deleteExpense(id);
      _loadExpenses();
    }
  }

  Widget _buildExpensesList() {
    final sorted = [..._expenses]
      ..sort((a, b) => b.date.compareTo(a.date));

    if (sorted.isEmpty) {
      return Center(
        child: Text(
          'No expenses yet',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sorted.length,
      itemBuilder: (_, index) {
        final e = sorted[index];
        return ExpenseCard(
          expense: e,
          onEdit: () => _addOrEditExpense(existing: e),
          onDelete: () => _deleteExpense(e.id),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildExpensesList(),
      TrackerPage(expenses: _expenses),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Expense Tracker'),
        actions: [
          Row(
            children: [
              const Icon(Icons.dark_mode),
              Switch(
                value: widget.isDark,
                onChanged: widget.onThemeToggle,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: pages[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
        onPressed: () => _addOrEditExpense(),
        child: const Icon(Icons.add),
      )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Tracker',
          ),
        ],
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
