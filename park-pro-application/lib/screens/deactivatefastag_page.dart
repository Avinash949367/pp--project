import 'package:flutter/material.dart';

class DeactivateFastagPage extends StatelessWidget {
  const DeactivateFastagPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color darkGray = const Color(0xFF2E2E2E);
    final Color electricBlue = const Color(0xFF1E90FF);

    return Scaffold(
      backgroundColor: darkGray,
      appBar: AppBar(
        title: const Text("Deactivate FASTag"),
        backgroundColor: electricBlue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Are you sure you want to deactivate your FASTag?",
              style: TextStyle(fontSize: 18, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("FASTag Deactivated")),
                  );
                  Navigator.pop(context);
                },
                child: const Text(
                  "Deactivate",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
