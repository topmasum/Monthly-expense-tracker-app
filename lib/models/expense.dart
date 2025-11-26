import 'dart:convert';


class Expense {
  final String id;
  String name;
  double amount;
  DateTime date;


  Expense({required this.id, required this.name, required this.amount, required this.date});


  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
    id: m['id'] as String,
    name: m['name'] as String,
    amount: (m['amount'] as num).toDouble(),
    date: DateTime.parse(m['date'] as String),
  );


  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'amount': amount,
    'date': date.toIso8601String(),
  };


  String toJson() => json.encode(toMap());
  static Expense fromJson(String jsonStr) => Expense.fromMap(json.decode(jsonStr));
}
