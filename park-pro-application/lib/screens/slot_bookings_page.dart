import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SlotBookingsPage extends StatefulWidget {
  final dynamic slot;

  const SlotBookingsPage({Key? key, required this.slot}) : super(key: key);

  @override
  _SlotBookingsPageState createState() => _SlotBookingsPageState();
}

class _SlotBookingsPageState extends State<SlotBookingsPage> {
  List<dynamic> _bookings = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchSlotBookings();
  }

  Future<void> _fetchSlotBookings() async {
    const String backendBaseUrl = 'http://localhost:8000';

    try {
      // Assuming there's an endpoint to get bookings by slotId
      // For now, fetch all slotbookings and filter
      final response =
          await http.get(Uri.parse('$backendBaseUrl/slotbookings'));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch bookings');
      }
      final allBookings = json.decode(response.body);
      setState(() {
        _bookings = allBookings
            .where((booking) => booking['slotId'] == widget.slot['_id'])
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookings for Slot ${widget.slot['slotId'] ?? 'N/A'}'),
        backgroundColor: const Color(0xFF2979FF),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _bookings.isEmpty
                  ? Center(child: Text('No bookings for this slot.'))
                  : ListView.builder(
                      itemCount: _bookings.length,
                      itemBuilder: (context, index) {
                        final booking = _bookings[index];
                        DateTime? start = booking['startTime'] != null
                            ? DateTime.tryParse(booking['startTime'])
                            : null;
                        DateTime? end = booking['endTime'] != null
                            ? DateTime.tryParse(booking['endTime'])
                            : null;

                        String dateStr = start != null
                            ? DateFormat('dd-MM-yyyy').format(start)
                            : 'N/A';
                        String timeStr = (start != null && end != null)
                            ? '${DateFormat.jm().format(start)} - ${DateFormat.jm().format(end)}'
                            : 'N/A';

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 16),
                          child: ListTile(
                            leading: const Icon(Icons.local_parking),
                            title:
                                Text('Booking ID: ${booking['_id'] ?? 'N/A'}'),
                            subtitle: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(dateStr),
                                Text(timeStr),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
