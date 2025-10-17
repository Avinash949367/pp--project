import 'package:flutter/material.dart';

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample transactions
    final List<Map<String, String>> transactions = [
      {"title": "NH44 Toll", "date": "01 Sep 2025", "amount": "- ₹120"},
      {"title": "Recharge", "date": "28 Aug 2025", "amount": "+ ₹500"},
      {"title": "City Toll", "date": "27 Aug 2025", "amount": "- ₹60"},
    ];

    final Color darkGray = const Color(0xFF2E2E2E);
    final Color electricBlue = const Color(0xFF1E90FF);
    final Color lightGray = const Color(0xFFB0B0B0);

    return Scaffold(
      backgroundColor: darkGray,
      appBar: AppBar(
        title: const Text("Transaction History"),
        backgroundColor: electricBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final txn = transactions[index];
          final isCredit = (txn['amount'] ?? '').contains("+");
          return Card(
            color: darkGray,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: electricBlue, width: 1),
            ),
            child: ListTile(
              leading: Icon(
                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: isCredit ? Colors.greenAccent : Colors.redAccent,
              ),
              title: Text(
                txn['title']!,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                txn['date']!,
                style: TextStyle(color: lightGray),
              ),
              trailing: Text(
                txn['amount']!,
                style: TextStyle(
                  color: isCredit ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
