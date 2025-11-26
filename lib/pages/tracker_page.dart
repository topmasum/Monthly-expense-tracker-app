import 'package:flutter/material.dart';
import '../models/expense.dart';
import 'dart:math';

class TrackerPage extends StatelessWidget {
  final List<Expense> expenses;
  const TrackerPage({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);

    // Calculate daily totals
    List<double> dailyTotals = List.filled(daysInMonth, 0.0);
    double totalMonth = 0;

    for (var e in expenses) {
      if (e.date.year == now.year && e.date.month == now.month) {
        dailyTotals[e.date.day - 1] += e.amount;
        totalMonth += e.amount;
      }
    }

    final maxAmount = dailyTotals.isEmpty ? 0 : dailyTotals.reduce(max);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: maxAmount == 0
            ? const Center(
          child: Text(
            "No expenses this month",
            style: TextStyle(fontSize: 16),
          ),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Professional header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${_monthName(now.month)} ${now.year}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "\$${totalMonth.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              "Daily Expense Chart",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Scrollable bars
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(daysInMonth, (i) {
                    final barHeight = max(
                      (dailyTotals[i] / maxAmount) * 200,
                      4,
                    ).toDouble(); // safe double

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "\$${dailyTotals[i].toStringAsFixed(0)}",
                          style: const TextStyle(fontSize: 10),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 12,
                          height: barHeight,
                          margin:
                          const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${i + 1}",
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Scroll to view all days",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to get month name
  String _monthName(int m) {
    const names = [
      "",
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return names[m];
  }
}
