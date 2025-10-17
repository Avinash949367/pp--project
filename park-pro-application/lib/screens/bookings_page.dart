import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

class BookingsPage extends StatefulWidget {
  final List<Map<String, dynamic>> bookings;

  const BookingsPage({Key? key, required this.bookings}) : super(key: key);

  @override
  _BookingsPageState createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  late Map<String, List<dynamic>> categorizedBookings;
  String selectedCategory = 'Past';
  Map<String, dynamic> stationMap = {};

  @override
  void initState() {
    super.initState();
    categorizedBookings = _categorizeBookings();
    _fetchStations();
  }

  Future<void> _fetchStations() async {
    Set<String> stationIds = {};
    for (var booking in widget.bookings) {
      if (booking['stationId'] != null) {
        stationIds.add(booking['stationId']);
      }
    }
    for (String stationId in stationIds) {
      try {
        String backendUrl;
        if (kIsWeb) {
          backendUrl = 'http://localhost:5000/api/stations/$stationId';
        } else if (Platform.isAndroid) {
          backendUrl = 'http://10.0.2.2:5000/api/stations/$stationId';
        } else if (Platform.isIOS) {
          backendUrl = 'http://localhost:5000/api/stations/$stationId';
        } else {
          backendUrl =
              'http://localhost:5000/api/stations/$stationId'; // default fallback
        }
        final response = await http.get(Uri.parse(backendUrl));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true && data['station'] != null) {
            setState(() {
              stationMap[stationId] = data['station'];
            });
          }
        }
      } catch (e) {
        // Handle error, perhaps log or show snackbar
      }
    }
  }

  Map<String, List<dynamic>> _categorizeBookings() {
    final Map<String, List<dynamic>> categorized = {
      'Ongoing': [],
      'Today': [],
      'Future': [],
      'Past': [],
    };

    final now = DateTime.now();

    for (var booking in widget.bookings) {
      DateTime? start = booking['bookingStartTime'] != null
          ? DateTime.tryParse(booking['bookingStartTime'])
          : null;
      DateTime? end = booking['bookingEndTime'] != null
          ? DateTime.tryParse(booking['bookingEndTime'])
          : null;

      if (start == null || end == null) {
        categorized['Past']!.add(booking);
        continue;
      }

      if (now.isAfter(start) && now.isBefore(end)) {
        categorized['Ongoing']!.add(booking);
      } else if (start.year == now.year &&
          start.month == now.month &&
          start.day == now.day) {
        categorized['Today']!.add(booking);
      } else if (start.isAfter(now)) {
        categorized['Future']!.add(booking);
      } else {
        categorized['Past']!.add(booking);
      }
    }

    return categorized;
  }

  void _showContactDialog(BuildContext context, String? email, String? phone) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          title: const Text('Contact', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (email != null && email.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.white),
                  title:
                      Text(email, style: const TextStyle(color: Colors.white)),
                  onTap: () async {
                    final Uri emailUri = Uri(
                      scheme: 'mailto',
                      path: email,
                    );
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri);
                    }
                  },
                ),
              if (phone != null && phone.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.phone, color: Colors.white),
                  title:
                      Text(phone, style: const TextStyle(color: Colors.white)),
                  onTap: () async {
                    final Uri phoneUri = Uri(
                      scheme: 'tel',
                      path: phone,
                    );
                    if (await canLaunchUrl(phoneUri)) {
                      await launchUrl(phoneUri);
                    }
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close',
                  style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        );
      },
    );
  }

  void _openMap(String? url) async {
    if (url != null && url.isNotEmpty) {
      final Uri mapUri = Uri.parse(url);
      if (await canLaunchUrl(mapUri)) {
        await launchUrl(mapUri);
      }
    }
  }

  void _showBookingDetails(BuildContext context, dynamic booking) {
    showDialog(
      context: context,
      builder: (context) {
        // Extract user-viewable fields from station
        final station = stationMap[booking['stationId']];
        final stationName = station != null ? station['name'] : 'N/A';
        final email = station != null ? station['email'] : '';
        final phone = station != null ? station['phone'] : '';
        final address = station != null ? station['address'] : '';
        final googleMapLocation =
            station != null ? station['googleMapLocation'] : '';

        return AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          title: Text('Booking Details - $stationName',
              style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (address.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('Address: $address',
                        style: const TextStyle(color: Colors.white)),
                  ),
                if (email.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('Email: $email',
                        style: const TextStyle(color: Colors.white)),
                  ),
                if (phone.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('Phone: $phone',
                        style: const TextStyle(color: Colors.white)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showContactDialog(context, email, phone);
              },
              child: const Text('Contact',
                  style: TextStyle(color: Colors.blueAccent)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _openMap(googleMapLocation);
              },
              child: const Text('Maps',
                  style: TextStyle(color: Colors.blueAccent)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close',
                  style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryButton(String category) {
    final bool isSelected = selectedCategory == category;
    return Expanded(
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: isSelected ? Colors.blueAccent : Colors.transparent,
          foregroundColor: isSelected ? Colors.white : Colors.blueAccent,
        ),
        onPressed: () {
          setState(() {
            selectedCategory = category;
          });
        },
        child: Text(category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingsToShow = categorizedBookings[selectedCategory] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: const Color(0xFF1F2937),
      ),
      backgroundColor: const Color(0xFF111827),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1F2937),
            child: Row(
              children: [
                _buildCategoryButton('Past'),
                _buildCategoryButton('Ongoing'),
                _buildCategoryButton('Today'),
                _buildCategoryButton('Future'),
              ],
            ),
          ),
          Expanded(
            child: bookingsToShow.isEmpty
                ? const Center(
                    child: Text(
                      'No books found.',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    itemCount: bookingsToShow.length,
                    itemBuilder: (context, index) {
                      final booking = bookingsToShow[index];
                      DateTime? start = booking['bookingStartTime'] != null
                          ? DateTime.tryParse(booking['bookingStartTime'])
                          : null;
                      DateTime? end = booking['bookingEndTime'] != null
                          ? DateTime.tryParse(booking['bookingEndTime'])
                          : null;

                      String dateStr = start != null
                          ? DateFormat('dd-MM-yyyy').format(start)
                          : 'N/A';
                      String timeStr = (start != null && end != null)
                          ? '${DateFormat.jm().format(start)} - ${DateFormat.jm().format(end)}'
                          : 'N/A';

                      return Card(
                        color: const Color(0xFF1F2937),
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 16),
                        child: ListTile(
                          leading: const Icon(Icons.local_parking,
                              color: Colors.white),
                          title: Text(
                            '${booking['stationName'] ?? stationMap[booking['stationId']] != null ? stationMap[booking['stationId']]['name'] : 'Unknown Station'} - Slot ${booking['slotId']?['slotId'] ?? booking['slotId'] ?? 'N/A'}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dateStr,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              Text(
                                timeStr,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          onTap: () => _showBookingDetails(context, booking),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
