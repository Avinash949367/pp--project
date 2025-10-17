import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'slot_booking_page.dart';

class SlotSelectionPage extends StatefulWidget {
  final dynamic station;
  final List<dynamic> slots;

  const SlotSelectionPage(
      {Key? key, required this.station, required this.slots})
      : super(key: key);

  @override
  _SlotSelectionPageState createState() => _SlotSelectionPageState();
}

class _SlotSelectionPageState extends State<SlotSelectionPage> {
  List<dynamic> _fetchedSlots = [];
  bool _isLoading = true;
  String _errorMessage = '';
  dynamic _selectedSlot;
  List<String> _selectedTypes = [];

  @override
  void initState() {
    super.initState();
    _fetchAllSlots();
  }

  Future<void> _fetchAllSlots() async {
    const String backendBaseUrl = 'http://localhost:5000/api';

    try {
      final slotsResponse = await http.get(Uri.parse(
          '$backendBaseUrl/slots/station/${widget.station['stationId']}'));
      if (slotsResponse.statusCode != 200) {
        throw Exception('Failed to fetch slots');
      }
      final slots = json.decode(slotsResponse.body);

      print('All slots: $slots');
      print('Station id: ${widget.station['id']}');
      setState(() {
        _fetchedSlots = slots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _confirmBooking() {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a slot')),
      );
      return;
    }
    // TODO: Implement booking confirmation logic, e.g., call backend API

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Booking Confirmed'),
        content: Text('You have booked slot ${_selectedSlot['slotNumber']}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back to previous page
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Slots-Cursor_AI'),
        backgroundColor: const Color(0xFF2979FF),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Wrap(
                        spacing: 8.0,
                        children: ['bike', 'van', 'ev', 'car'].map((type) {
                          return FilterChip(
                            label: Text(type.toUpperCase()),
                            selected: _selectedTypes.contains(type),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  if (!_selectedTypes.contains(type)) {
                                    _selectedTypes.add(type);
                                  }
                                } else {
                                  _selectedTypes.remove(type);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    Expanded(
                      child: _fetchedSlots.isEmpty
                          ? Center(child: Text('No slots available.'))
                          : Builder(
                              builder: (context) {
                                final filteredSlots = _fetchedSlots
                                    .where((slot) =>
                                        _selectedTypes.isEmpty ||
                                        (slot['type'] != null &&
                                            _selectedTypes.contains(
                                                slot['type']!.toLowerCase())))
                                    .toList();
                                return filteredSlots.isEmpty
                                    ? Center(
                                        child: Text(
                                            'No slots match the selected filters.'))
                                    : GridView.builder(
                                        padding: const EdgeInsets.all(16.0),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 16.0,
                                          mainAxisSpacing: 16.0,
                                          childAspectRatio: 0.8,
                                        ),
                                        itemCount: filteredSlots.length,
                                        itemBuilder: (context, index) {
                                          final slot = filteredSlots[index];
                                          return SlotCard(
                                            slot: slot,
                                            isSelected: _selectedSlot == slot,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      SlotBookingPage(
                                                          slot: slot,
                                                          station:
                                                              widget.station),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}

class SlotCard extends StatelessWidget {
  final dynamic slot;
  final bool isSelected;
  final VoidCallback onTap;

  const SlotCard({
    Key? key,
    required this.slot,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<String> images =
        slot['images'] != null ? List<String>.from(slot['images']) : [];
    String slotType = slot['type'] ?? 'Unknown';
    double price = slot['price'] != null ? slot['price'].toDouble() : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isSelected ? 8.0 : 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(
            color: isSelected ? Colors.blueAccent : Colors.transparent,
            width: 3.0,
          ),
        ),
        color: isSelected ? Colors.blue[50] : Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
                child: images.isNotEmpty
                    ? images.length > 1
                        ? PageView.builder(
                            itemCount: images.length *
                                1000, // Large number for infinite scroll
                            controller: PageController(
                                initialPage:
                                    images.length * 500), // Start in the middle
                            itemBuilder: (context, index) {
                              String url = images[index % images.length];
                              return Image.network(
                                url,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                        color: Colors.grey[300],
                                        child: Icon(Icons.image,
                                            size: 50, color: Colors.grey)),
                              );
                            },
                          )
                        : Image.network(
                            images[0],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                    color: Colors.grey[300],
                                    child: Icon(Icons.image,
                                        size: 50, color: Colors.grey)),
                          )
                    : Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.directions_car,
                            size: 50, color: Colors.grey[600]),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Slot - ${slot['slotId'] ?? 'N/A'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 6.0),
                  Row(
                    children: [
                      Icon(Icons.category, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4.0),
                      Text(
                        'Type: $slotType',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.0),
                  Row(
                    children: [
                      Icon(Icons.attach_money,
                          size: 16, color: Colors.green[600]),
                      SizedBox(width: 4.0),
                      Text(
                        'Price: \$${price.toStringAsFixed(2)}/hr',
                        style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
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
