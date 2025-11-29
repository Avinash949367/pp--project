import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'fastag_recharge_page.dart';
import 'buynewfastag_page.dart';
import 'transactionhistory_page.dart';
import 'linkvehiclepage_page.dart';
import 'deactivatefastag_page.dart';

class FastagPage extends StatefulWidget {
  const FastagPage({super.key});

  @override
  State<FastagPage> createState() => _FastagPageState();
}

class _FastagPageState extends State<FastagPage> {
  final Color darkGray = const Color(0xFF1E1E1E);
  final Color electricBlue = const Color(0xFF2979FF);

  double balance = 0.0;
  bool isLoading = true;
  bool hasFastag = false;
  String fastagId = '';
  String vehicleNumber = '';
  String vehicleType = '';
  List<dynamic> recentTransactions = [];
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    userEmail = prefs.getString('userEmail');
    if (userEmail != null) {
      await _fetchFastagData();
    } else {
      setState(() {
        isLoading = false;
        hasFastag = false;
      });
    }
  }

  Future<void> _fetchFastagData() async {
    if (userEmail == null) return;

    try {
      // Get user data to check for FastTag
      final userResponse = await http.get(
        Uri.parse('http://localhost:5000/api/users/email/$userEmail'),
      );

      if (userResponse.statusCode == 200) {
        final userData = json.decode(userResponse.body);

        if (userData['fastagId'] != null && userData['fastagId'].isNotEmpty) {
          setState(() {
            hasFastag = true;
            fastagId = userData['fastagId'];
            vehicleNumber = userData['vehicle'] ?? '';
            vehicleType = userData['vehicleType'] ?? '';
            balance = (userData['walletBalance'] ?? 0).toDouble();
          });

          // Fetch recent transactions
          await _fetchRecentTransactions();
        } else {
          setState(() {
            hasFastag = false;
            isLoading = false;
          });
        }
      } else {
        setState(() {
          hasFastag = false;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasFastag = false;
        isLoading = false;
      });
    }
  }

  Future<void> _fetchRecentTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      String backendUrl;
      if (kIsWeb) {
        backendUrl = 'http://localhost:5000/api/fastag/transactions';
      } else if (Platform.isAndroid) {
        backendUrl = 'http://10.0.2.2:5000/api/fastag/transactions';
      } else if (Platform.isIOS) {
        backendUrl = 'http://localhost:5000/api/fastag/transactions';
      } else {
        backendUrl = 'http://localhost:5000/api/fastag/transactions';
      }

      final response = await http.get(
        Uri.parse(backendUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          recentTransactions = data['transactions'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: darkGray,
        appBar: AppBar(
          title: const Text("FASTag"),
          backgroundColor: darkGray,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2979FF),
          ),
        ),
      );
    }

    if (!hasFastag) {
      return Scaffold(
        backgroundColor: darkGray,
        appBar: AppBar(
          title: const Text("FASTag"),
          backgroundColor: darkGray,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.credit_card_off,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 20),
              const Text(
                "No FASTag Found",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "You don't have an active FASTag. Apply for a new one to get started.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BuyNewFastagPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text("Apply for FASTag"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: electricBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: darkGray,
      appBar: AppBar(
        title: const Text("FASTag"),
        backgroundColor: darkGray,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Balance Card with Recharge Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: electricBlue,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "FASTag Balance",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      Text(
                        fastagId,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "₹ ${balance.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (vehicleNumber.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Vehicle: $vehicleNumber",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Recharge button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FastagRechargePage(),
                          ),
                        );
                        if (result != null && result is double) {
                          setState(() {
                            balance += result;
                          });
                          // Refresh data after recharge
                          await _fetchFastagData();
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text("Recharge"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: electricBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // FASTag QR Code Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "FASTag QR Code",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Scan this QR code at toll plazas",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      fastagId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "ID: $fastagId",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Recent Transactions Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Recent Transactions",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TransactionHistoryPage(),
                            ),
                          );
                        },
                        child: Text(
                          "View All",
                          style: TextStyle(
                            color: electricBlue,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (recentTransactions.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          "No recent transactions",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  else
                    ...recentTransactions.take(3).map((transaction) {
                      final createdAt = DateTime.parse(
                          transaction['createdAt'] ??
                              DateTime.now().toIso8601String());
                      final formattedDate =
                          "${createdAt.day} ${createdAt.month == 1 ? 'Jan' : createdAt.month == 2 ? 'Feb' : createdAt.month == 3 ? 'Mar' : createdAt.month == 4 ? 'Apr' : createdAt.month == 5 ? 'May' : createdAt.month == 6 ? 'Jun' : createdAt.month == 7 ? 'Jul' : createdAt.month == 8 ? 'Aug' : createdAt.month == 9 ? 'Sep' : createdAt.month == 10 ? 'Oct' : createdAt.month == 11 ? 'Nov' : 'Dec'} ${createdAt.year}";
                      final isRecharge = transaction['type'] == 'recharge';
                      final amount = transaction['amount']?.toDouble() ?? 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(
                              isRecharge
                                  ? Icons.account_balance_wallet
                                  : Icons.local_shipping,
                              color: electricBlue,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Vehicle: ${transaction['vehicleNumber'] ?? vehicleNumber}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isRecharge
                                        ? "FASTag recharge via ${transaction['paymentMethod'] ?? 'UPI'}"
                                        : "Toll payment",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Amount: ₹${amount.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      color: electricBlue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: transaction['status'] == 'completed'
                                        ? Colors.green[700]
                                        : Colors.orange[700],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    transaction['status'] == 'completed'
                                        ? "Completed"
                                        : "Pending",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // FASTag Services Section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "FASTag Services",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 3 / 2,
                children: [
                  ServiceCard(
                    icon: Icons.link,
                    title: "Link Vehicle",
                    electricBlue: electricBlue,
                    darkGray: darkGray,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LinkVehiclePage()),
                      );
                    },
                  ),
                  ServiceCard(
                    icon: Icons.cancel,
                    title: "Deactivate FASTag",
                    electricBlue: electricBlue,
                    darkGray: darkGray,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DeactivateFastagPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Service Card Widget
class ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color electricBlue;
  final Color darkGray;

  const ServiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.electricBlue,
    required this.darkGray,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: darkGray,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: electricBlue),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
