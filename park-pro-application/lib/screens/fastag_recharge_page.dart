import 'package:flutter/material.dart';

class FastagRechargePage extends StatefulWidget {
  const FastagRechargePage({super.key});

  @override
  State<FastagRechargePage> createState() => _FastagRechargePageState();
}

class _FastagRechargePageState extends State<FastagRechargePage> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedMethod = "UPI"; // Default payment method

  final Color darkGray = const Color(0xFF1E1E1E);
  final Color electricBlue = const Color(0xFF2979FF);

  void _recharge() {
    String amount = _amountController.text.trim();
    if (amount.isEmpty || double.tryParse(amount) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Recharge of ₹$amount via $_selectedMethod initiated")),
    );

    // TODO: integrate with backend / payment gateway
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGray,
      appBar: AppBar(
        title: const Text("Recharge FASTag"),
        backgroundColor: darkGray,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter Recharge Amount",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter amount (₹)",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.currency_rupee, color: electricBlue),
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Select Payment Method",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
            ),
            const SizedBox(height: 10),

            // Payment Method Options
            Column(
              children: [
                RadioListTile(
                  title: const Text("UPI", style: TextStyle(color: Colors.white)),
                  value: "UPI",
                  activeColor: electricBlue,
                  groupValue: _selectedMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedMethod = value.toString();
                    });
                  },
                ),
                RadioListTile(
                  title: const Text("Credit/Debit Card", style: TextStyle(color: Colors.white)),
                  value: "Card",
                  activeColor: electricBlue,
                  groupValue: _selectedMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedMethod = value.toString();
                    });
                  },
                ),
              ],
            ),

            const Spacer(),

            // Recharge Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _recharge,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: electricBlue,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  "Recharge Now",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
