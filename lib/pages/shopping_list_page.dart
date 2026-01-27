import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/shopping_item.dart';
import '../services/storage_service.dart';
import '../utils/currency_helper.dart';

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key});

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  List<ShoppingItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    setState(() {
      _items = StorageService.getShoppingList();
    });
  }

  // --- LOGIC: Move Item to Real Expenses ---
  Future<void> _markAsPurchased(ShoppingItem item) async {
    final actualAmountController =
    TextEditingController(text: item.estimatedAmount.toString());

    // 1. Ask user for the FINAL price (prices might change!)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Bought this item?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Adding '${item.name}' to your expenses."),
            const SizedBox(height: 16),
            TextField(
              controller: actualAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Final Cost",
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Confirm & Add"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final finalAmount = double.tryParse(actualAmountController.text) ?? item.estimatedAmount;

      // 2. Create the Real Expense
      final newExpense = Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: item.name,
        amount: finalAmount,
        date: DateTime.now(),
        category: item.category,
      );
      await StorageService.addExpense(newExpense);

      // 3. Delete from Shopping List
      await StorageService.deleteShoppingItem(item.id);

      // 4. Update UI
      _loadItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Moved '${item.name}' to expenses!")),
        );
      }
    }
  }

  // --- LOGIC: Add New Planning Item ---
  Future<void> _addItem() async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    Category selectedCategory = Category.other;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
              const Text(
                'Plan Future Expense',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<Category>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: Category.values.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat.name.toUpperCase()));
                }).toList(),
                onChanged: (v) => setModalState(() => selectedCategory = v!),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Item Name', border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 15),

              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Est. Cost', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 25),

              ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                onPressed: () async {
                  if (nameController.text.isEmpty) return;

                  final newItem = ShoppingItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(9999).toString(),
                    name: nameController.text.trim(),
                    estimatedAmount: double.tryParse(amountController.text) ?? 0.0,
                    category: selectedCategory,
                  );
                  await StorageService.addShoppingItem(newItem);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadItems();
                },
                child: const Text('Add to List'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteItem(String id) async {
    await StorageService.deleteShoppingItem(id);
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _items.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checklist_rtl, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text("No future expenses planned", style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        itemBuilder: (_, index) {
          final item = _items[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.purple.withOpacity(0.1),
                child: const Icon(Icons.push_pin, color: Colors.purple),
              ),
              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                item.estimatedAmount > 0
                    ? "Est: ${CurrencyHelper.format(item.estimatedAmount)}"
                    : "No estimate",
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // PURCHASE BUTTON
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                    onPressed: () => _markAsPurchased(item),
                    tooltip: "Buy Now",
                  ),
                  // DELETE BUTTON
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () => _deleteItem(item.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}