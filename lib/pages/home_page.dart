import 'package:flutter/material.dart';
import 'dart:math';
import '../models/expense.dart';
import '../services/storage_service.dart';
import '../widgets/expense_card.dart';
import 'tracker_page.dart';
import 'shopping_list_page.dart';
import '../utils/currency_helper.dart';

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
    final nameController = TextEditingController(text: existing?.name ?? '');
    final amountController = TextEditingController(
        text: existing != null ? existing.amount.toString() : '');

    // Default category
    Category selectedCategory = existing?.category ?? Category.other;

    // NEW: Default date (either existing date or Today)
    DateTime selectedDate = existing?.date ?? DateTime.now();
    PaymentMethod selectedPayment = existing?.paymentMethod ?? PaymentMethod.cash;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {

          // Helper function to pick date
          Future<void> pickDate() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(), // Can't pick future dates for expenses
            );
            if (picked != null) {
              setModalState(() => selectedDate = picked);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  existing == null ? 'Add New Expense' : 'Edit Expense',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // 1. NAME
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Expense Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 15),

                // 2. AMOUNT
                TextField(
                  controller: amountController,
                  // 1. Remove 'const' here
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    border: const OutlineInputBorder(), // You can move 'const' here if you want

                    // This allows the currency to change dynamically
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        StorageService.getCurrency(),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 15),
                const Text("Payment Method", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPaymentChoice(PaymentMethod.cash, Icons.money, "Cash", selectedPayment, (val) => setModalState(() => selectedPayment = val)),
                    _buildPaymentChoice(PaymentMethod.online, Icons.wifi, "Online", selectedPayment, (val) => setModalState(() => selectedPayment = val)),
                    _buildPaymentChoice(PaymentMethod.card, Icons.credit_card, "Card", selectedPayment, (val) => setModalState(() => selectedPayment = val)),
                  ],
                ),
                const SizedBox(height: 15),

                // 3. ROW: CATEGORY + DATE PICKER
                Row(
                  children: [
                    // Category Dropdown (Flexible width)
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<Category>(
                        value: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        ),
                        isExpanded: true, // Prevents overflow
                        items: Category.values.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(
                              cat.name.toUpperCase(),
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() => selectedCategory = value);
                          }
                        },
                      ),
                    ),

                    const SizedBox(width: 10),

                    // NEW: DATE PICKER BUTTON
                    Expanded(
                      flex: 1, // Takes up 1/3 of the row
                      child: InkWell(
                        onTap: pickDate,
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today, size: 18, color: Colors.blue),
                              const SizedBox(height: 4),
                              Text(
                                "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // SAVE BUTTON
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final amount = double.tryParse(amountController.text) ?? 0.0;

                    if (name.isEmpty || amount <= 0) return;

                    if (existing == null) {
                      final id = DateTime.now().millisecondsSinceEpoch.toString() +
                          Random().nextInt(9999).toString();
                      final newExpense = Expense(
                        id: id,
                        name: name,
                        amount: amount,
                        date: selectedDate, // Use user-selected date
                        category: selectedCategory,
                        paymentMethod: selectedPayment,
                      );
                      await StorageService.addExpense(newExpense);
                    } else {
                      existing.name = name;
                      existing.amount = amount;
                      existing.date = selectedDate; // Use user-selected date
                      existing.category = selectedCategory;
                      await StorageService.updateExpense(existing);
                    }

                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadExpenses();
                  },
                  child: Text(
                    existing == null ? 'Save Expense' : 'Update Expense',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  Future<void> _deleteExpense(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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
    final sorted = [..._expenses]..sort((a, b) => b.date.compareTo(a.date));

    if (sorted.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No expenses yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      // --- THE FIX IS HERE ---
      // We keep 12px padding on Top/Left/Right,
      // but add 80px to Bottom to clear the FloatingActionButton.
      padding: const EdgeInsets.only(
        top: 12,
        left: 12,
        right: 12,
        bottom: 80,
      ),
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
    // 1. Add ShoppingListPage to the list of pages
    final pages = [
      _buildExpensesList(),       // Index 0
      TrackerPage(expenses: _expenses), // Index 1
      const ShoppingListPage(),   // Index 2 (NEW)
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pocket Planner'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined), // Modern outline icon
            onPressed: _showSettingsPanel, // Opens the new pro panel
          ),
          const SizedBox(width: 8), // Little padding at the end
        ],
      ),
      body: pages[_currentIndex],

      // 2. Logic: Only show the main FAB on the first page.
      // The Shopping Page has its OWN internal FAB.
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
        onPressed: () => _addOrEditExpense(),
        child: const Icon(Icons.add),
      )
          : null,

      // 3. Add the third item to the bottom bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
          // NEW CODE
          onTap: (i) {
            setState(() {
              _currentIndex = i;
              // Reload data whenever we switch tabs!
              // This ensures expenses added from "Planning" show up instantly here.
              _loadExpenses();
            });
          },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Analysis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist),
            label: 'Planning', // The new tab
          ),
        ],
      ),

    );
  }
  void _showSettingsPanel() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setPanelState) {
            final currencies = ['\$', '€', '£', '৳', '₹', '¥'];
            final currentCurrency = StorageService.getCurrency();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Settings",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // 1. APPEARANCE SECTION
                  const Text(
                    "Appearance",
                    style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isDark ? Icons.dark_mode : Icons.light_mode,
                        color: Colors.purple,
                      ),
                    ),
                    title: const Text("Dark Mode", style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Switch(
                      value: widget.isDark,
                      activeColor: Colors.purple,
                      onChanged: (val) {
                        // Close panel, toggle theme, then re-open panel (optional) or just toggle
                        widget.onThemeToggle(val);
                        setPanelState(() {}); // Refresh the switch visual
                      },
                    ),
                  ),
                  const Divider(height: 30),

                  // 2. CURRENCY SECTION
                  const Text(
                    "Currency",
                    style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 10,
                    children: currencies.map((symbol) {
                      final isSelected = currentCurrency == symbol;
                      return ChoiceChip(
                        label: Text(
                          symbol,
                          style: TextStyle(
                            fontSize: 16,
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Colors.blue,
                        backgroundColor: Colors.grey[100],
                        onSelected: (selected) async {
                          if (selected) {
                            await StorageService.saveCurrency(symbol);
                            setPanelState(() {}); // Update the chip selection immediately
                            setState(() {}); // Update the main HomePage behind the sheet
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }
  Widget _buildPaymentChoice(PaymentMethod method, IconData icon, String label, PaymentMethod current, Function(PaymentMethod) onTap) {
    final isSelected = method == current;
    return InkWell(
      onTap: () => onTap(method),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey[100],
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.blue : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}