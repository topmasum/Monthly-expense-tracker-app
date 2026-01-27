import 'dart:convert';

// 1. New Enum for Payment Types
enum PaymentMethod { cash, online, card }

enum Category { food, transport, bills, shopping, entertainment, health, other }

class Expense {
  final String id;
  String name;
  double amount;
  DateTime date;
  Category category;
  PaymentMethod paymentMethod; // 2. New Field

  Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    required this.category,
    this.paymentMethod = PaymentMethod.cash, // Default to Cash
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category.name,
      'paymentMethod': paymentMethod.name, // Save it
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      name: map['name'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      category: Category.values.firstWhere(
              (e) => e.name == (map['category'] ?? 'other'),
          orElse: () => Category.other),
      // Load it (or default to cash if old data doesn't have it)
      paymentMethod: PaymentMethod.values.firstWhere(
              (e) => e.name == (map['paymentMethod'] ?? 'cash'),
          orElse: () => PaymentMethod.cash),
    );
  }

  String toJson() => json.encode(toMap());

  factory Expense.fromJson(String source) =>
      Expense.fromMap(json.decode(source));
}