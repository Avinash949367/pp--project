import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SlotBookingPage extends StatefulWidget {
  final dynamic slot;
  final dynamic station;

  const SlotBookingPage({Key? key, required this.slot, required this.station})
      : super(key: key);

  @override
  _SlotBookingPageState createState() => _SlotBookingPageState();
}

class _SlotBookingPageState extends State<SlotBookingPage> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 10, minute: 0);
  List<dynamic> _vehicles = [];
  String? _selectedVehicleId;
  bool _isLoading = false;
  bool _vehiclesLoading = false;
  String _errorMessage = '';
  String _vehiclesError = '';

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    setState(() {
      _vehiclesLoading = true;
      _vehiclesError = '';
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      setState(() {
        _vehiclesError = 'User not authenticated';
        _vehiclesLoading = false;
      });
      return;
    }

    const String backendBaseUrl = 'http://localhost:5000/api';
    try {
      final response = await http.get(
        Uri.parse('$backendBaseUrl/user/vehicles'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _vehicles = data['vehicles'] ?? [];
          _vehiclesLoading = false;
        });
      } else {
        setState(() {
          _vehiclesError = 'Failed to load vehicles: ${response.statusCode}';
          _vehiclesLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _vehiclesError = 'Error fetching vehicles: $e';
        _vehiclesLoading = false;
      });
    }
  }

  Future<void> _addVehicle(String number, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    const String backendBaseUrl = 'http://localhost:5000/api';
    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/user/vehicles'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode({'number': number, 'type': type}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        setState(() {
          _vehicles.add(data['vehicle']);
          _selectedVehicleId = data['vehicle']['_id'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vehicle added successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to add vehicle: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding vehicle: $e')),
      );
    }
  }

  void _showAddVehicleDialog() {
    String number = '';
    String type = 'car';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Vehicle Number'),
              onChanged: (value) => number = value,
            ),
            DropdownButtonFormField<String>(
              value: type,
              items: ['car', 'bike', 'ev']
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(t.toUpperCase())))
                  .toList(),
              onChanged: (value) => setState(() => type = value!),
              decoration: InputDecoration(labelText: 'Type'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (number.isNotEmpty) {
                _addVehicle(number, type);
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
        if (_endTime.hour < _startTime.hour ||
            (_endTime.hour == _startTime.hour &&
                _endTime.minute <= _startTime.minute)) {
          _endTime =
              TimeOfDay(hour: _startTime.hour + 1, minute: _startTime.minute);
        }
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  Future<void> _bookSlot() async {
    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a vehicle')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('token');
    if (userId == null || token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User not logged in';
      });
      return;
    }

    final startDateTime = DateTime(_selectedDate.year, _selectedDate.month,
        _selectedDate.day, _startTime.hour, _startTime.minute);
    final endDateTime = DateTime(_selectedDate.year, _selectedDate.month,
        _selectedDate.day, _endTime.hour, _endTime.minute);

    final bookingData = {
      'slotId': widget.slot['_id'],
      'userId': userId,
      'vehicleId': _selectedVehicleId,
      'stationId': widget.station['id'],
      'startTime': startDateTime.toIso8601String(),
      'endTime': endDateTime.toIso8601String(),
      'amountPaid':
          10.0, // Placeholder, calculate based on slot price and duration
      'paymentMethod': 'upi',
    };

    const String backendBaseUrl = 'http://localhost:5000/api';
    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/slotbookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode(bookingData),
      );
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking successful!')),
        );
        Navigator.pop(context); // Go back
      } else {
        setState(() {
          _errorMessage = 'Booking failed: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Slot ${widget.slot['slotId'] ?? 'N/A'}'),
        backgroundColor: const Color(0xFF2979FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Station: ${widget.station['stationName'] ?? widget.station['name'] ?? 'N/A'}'),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                      'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
                ),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: Text('Select Date'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('Start Time: ${_startTime.format(context)}'),
                ),
                TextButton(
                  onPressed: () => _selectStartTime(context),
                  child: Text('Select Start Time'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('End Time: ${_endTime.format(context)}'),
                ),
                TextButton(
                  onPressed: () => _selectEndTime(context),
                  child: Text('Select End Time'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text('Select Vehicle:'),
            if (_vehiclesLoading)
              CircularProgressIndicator()
            else if (_vehiclesError.isNotEmpty)
              Text(_vehiclesError, style: TextStyle(color: Colors.red))
            else
              DropdownButtonFormField<String>(
                value: _selectedVehicleId,
                items: [
                  ..._vehicles.map((vehicle) => DropdownMenuItem<String>(
                        value: vehicle['_id'],
                        child:
                            Text('${vehicle['number']} (${vehicle['type']})'),
                      )),
                  DropdownMenuItem<String>(
                    value: 'add_new',
                    child: Text('Add New Vehicle'),
                  ),
                ],
                onChanged: (value) {
                  if (value == 'add_new') {
                    _showAddVehicleDialog();
                  } else {
                    setState(() {
                      _selectedVehicleId = value;
                    });
                  }
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select a vehicle',
                ),
              ),
            SizedBox(height: 16),
            if (_errorMessage.isNotEmpty)
              Text(_errorMessage, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _bookSlot,
              child:
                  _isLoading ? CircularProgressIndicator() : Text('Book Slot'),
            ),
          ],
        ),
      ),
    );
  }
}
