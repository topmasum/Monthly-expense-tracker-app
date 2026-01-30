import 'package:flutter/material.dart';
import 'dart:math';
import '../models/expense.dart';
import '../services/storage_service.dart';
import '../widgets/expense_card.dart';
import 'tracker_page.dart';
import 'shopping_list_page.dart';
import 'package:intl/intl.dart';
import '../services/receipt_scanner_service.dart';

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
  List<Expense> _filteredExpenses = []; // 1. Holds the search results
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _loadExpenses() {
    setState(() {
      _expenses = StorageService.getAllExpenses();
      _filteredExpenses = _expenses; // 2. Initially show everything
    });
  }

  // 3. THE SMART SEARCH LOGIC
// 3. THE SMART SEARCH LOGIC
  void _runFilter(String enteredKeyword) {
    List<Expense> results = [];
    if (enteredKeyword.isEmpty) {
      // If search is empty, show all
      results = _expenses;
    } else {
      results = _expenses.where((expense) {
        final query = enteredKeyword.toLowerCase();

        // 1. Match Name? (e.g. "Pizza")
        final nameMatches = expense.name.toLowerCase().contains(query);

        // 2. Match Category? (e.g. "Food")
        final categoryMatches = expense.category.name.toLowerCase().contains(query);

        // 3. Match Amount? (e.g. "500")
        final amountMatches = expense.amount.toString().contains(query);

        // 4. Match Date? (e.g. "Jan", "29", "Wednesday")
        final dateFormatted = DateFormat('MMM d EEEE yyyy').format(expense.date).toLowerCase();
        final dateMatches = dateFormatted.contains(query);

        // 5. NEW: Match Payment Method? (e.g. "Cash", "Card", "Online")
        final paymentMatches = expense.paymentMethod.name.toLowerCase().contains(query);

        return nameMatches || categoryMatches || amountMatches || dateMatches || paymentMatches;
      }).toList();
    }

    // Refresh the UI
    setState(() {
      _filteredExpenses = results;
    });
  }

  Future<void> _addOrEditExpense({Expense? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final amountController = TextEditingController(
        text: existing != null ? existing.amount.toString() : '');

    // Default category
    Category selectedCategory = existing?.category ?? Category.other;

    // Default date (either existing date or Today)
    DateTime selectedDate = existing?.date ?? DateTime.now();
    PaymentMethod selectedPayment = existing?.paymentMethod ?? PaymentMethod.cash;

    // NEW: Initialize the Scanner Service
    final ReceiptScannerService scanner = ReceiptScannerService();

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
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setModalState(() => selectedDate = picked);
            }
          }

          // NEW: SCAN FUNCTION
          Future<void> scanReceipt() async {
            // 1. Show a loading indicator or toast if you want
            try {
              final result = await scanner.scanReceipt();

              if (result.isNotEmpty) {
                setModalState(() {
                  // Auto-fill Amount
                  if (result['amount'] != null) {
                    amountController.text = result['amount'].toString();
                  }
                  // Auto-fill Date
                  if (result['date'] != null) {
                    selectedDate = result['date'];
                  }
                });

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Scanned: Found ${result['amount'] ?? 'no amount'}"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Could not read receipt. Try again.")),
                  );
                }
              }
            } catch (e) {
              // Handle permission errors or cancellations
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
                // HEADER ROW: Title + Scan Button
// HEADER ROW: Title + Scan Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. TITLE (Wrapped in Expanded to prevent overlap)
                    Expanded(
                      child: Text(
                        existing == null ? 'New Expense' : 'Edit Expense',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis, // Adds "..." if screen is TINY
                      ),
                    ),

                    // 2. COMPACT SCAN BUTTON
                    if (existing == null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilledButton.tonalIcon(
                          onPressed: scanReceipt,
                          icon: const Icon(Icons.camera_alt, size: 16),
                          label: const Text("Scan", style: TextStyle(fontWeight: FontWeight.bold)),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            visualDensity: VisualDensity.compact, // Makes button height smaller
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            foregroundColor: Colors.blue,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // 1. NAME
                TextField(
                  controller: nameController,
                  autofocus: existing == null, // Only autofocus if new
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
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    border: const OutlineInputBorder(),
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

                // PAYMENT METHOD
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
                    // Category Dropdown
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<Category>(
                        value: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        ),
                        isExpanded: true,
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

                    // DATE PICKER BUTTON
                    Expanded(
                      flex: 1,
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
                        date: selectedDate,
                        category: selectedCategory,
                        paymentMethod: selectedPayment,
                      );
                      await StorageService.addExpense(newExpense);
                    } else {
                      existing.name = name;
                      existing.amount = amount;
                      existing.date = selectedDate;
                      existing.category = selectedCategory;
                      existing.paymentMethod = selectedPayment;
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
    // Sort results by date (newest first)
    final sorted = [..._filteredExpenses]..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: [
        // A. PROFESSIONAL SEARCH BAR
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Container(
            // 1. The Decoration (Shadow & Background)
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor, // Adapts to light/dark mode background
              borderRadius: BorderRadius.circular(16), // Modern soft corners
              boxShadow: [
                BoxShadow(
                  // Subtler shadow in dark mode, softer one in light mode
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5), // Pushes shadow down slightly
                ),
              ],
            ),
            // 2. The Input Field itself
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _runFilter(value),
              textAlignVertical: TextAlignVertical.center, // Centers text vertically with icons
              decoration: InputDecoration(
                hintText: 'Search name, category, date...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Icon(
                    Icons.search,
                    // FIX: Use light grey in Dark Mode, dark grey in Light Mode
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                ),
                // Clear button logic handles itself
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _runFilter('');
                    FocusScope.of(context).unfocus();
                  },
                )
                    : null,
                border: InputBorder.none, // Important: removes the default underline/outline
                contentPadding: const EdgeInsets.symmetric(vertical: 16), // Adjust height
              ),
            ),
          ),
        ),

        // B. THE LIST
        Expanded(
          child: sorted.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _searchController.text.isEmpty
                      ? 'No expenses yet'
                      : 'No results found',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.only(top: 8, left: 12, right: 12, bottom: 80),
            itemCount: sorted.length,
            itemBuilder: (_, index) {
              final e = sorted[index];
              return ExpenseCard(
                expense: e,
                onEdit: () => _addOrEditExpense(existing: e),
                onDelete: () => _deleteExpense(e.id),
              );
            },
          ),
        ),
      ],
    );
  }

// ... (Keep your build() method, but make sure it calls _buildExpensesList()) ...


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
        // 1. Professional Background
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 3.0, // Shows a subtle shadow ONLY when scrolling
        surfaceTintColor: Colors.transparent, // Removes the default purple tint of Material 3

        // 2. Title + Date Subtitle
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'Pocket Planner',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800, // Extra Bold
                letterSpacing: -0.5, // Tighter spacing looks modern
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEEE, MMM d').format(DateTime.now()).toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
                letterSpacing: 1.5, // Wide spacing for the subtitle
              ),
            ),
          ],
        ),

        // 3. Encapsulated Settings Button
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1) // Subtle light circle in Dark Mode
                  : Colors.grey[200],             // Subtle grey circle in Light Mode
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.settings_outlined,
                size: 20,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
              onPressed: _showSettingsPanel,
              tooltip: "Settings",
            ),
          ),
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