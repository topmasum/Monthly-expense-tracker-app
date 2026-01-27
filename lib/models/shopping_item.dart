import 'dart:convert';
import 'expense.dart'; // We import this to use the same Category enum

class ShoppingItem {
  final String id;
  String name;
  double estimatedAmount;
  Category category;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.estimatedAmount,
    required this.category,
  });

  factory ShoppingItem.fromMap(Map<String, dynamic> m) => ShoppingItem(
    id: m['id'] as String,
    name: m['name'] as String,
    estimatedAmount: (m['amount'] as num).toDouble(),
    // Load category or default to 'other'
    category: Category.values.firstWhere(
          (e) => e.name == (m['category'] ?? 'other'),
      orElse: () => Category.other,
    ),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'amount': estimatedAmount,
    'category': category.name,
  };

  String toJson() => json.encode(toMap());
  static ShoppingItem fromJson(String jsonStr) =>
      ShoppingItem.fromMap(json.decode(jsonStr));
}