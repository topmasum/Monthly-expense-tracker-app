import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../utils/currency_helper.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(expense.category);
    final icon = _getCategoryIcon(expense.category);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Category Icon (Left Side)
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),

            // 2. Name & Details (Middle)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Expense Name
                  Text(
                    expense.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle Row: Date | Payment Method
                  Row(
                    children: [
                      // Date
                      Text(
                        DateFormat.MMMd().format(expense.date),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),

                      // Separator
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          "|",
                          style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                        ),
                      ),

                      // Payment Method Icon
                      Icon(
                        _getPaymentIcon(expense.paymentMethod),
                        size: 14,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),

                      // Payment Method Label
                      Text(
                        _getPaymentLabel(expense.paymentMethod),
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // 3. Amount & Actions (Right Side)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Amount
                Container(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Text(
                    CurrencyHelper.format(expense.amount),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 8),

                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(Icons.edit, size: 18, color: Colors.grey[500]),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(Icons.delete, size: 18, color: Colors.red[300]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Methods ---

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

  IconData _getPaymentIcon(PaymentMethod p) {
    switch (p) {
      case PaymentMethod.cash: return Icons.money;
      case PaymentMethod.card: return Icons.credit_card;
      case PaymentMethod.online: return Icons.wifi;
    }
  }

  String _getPaymentLabel(PaymentMethod p) {
    switch (p) {
      case PaymentMethod.cash: return "Cash";
      case PaymentMethod.card: return "Card";
      case PaymentMethod.online: return "Online";
    }
  }
}