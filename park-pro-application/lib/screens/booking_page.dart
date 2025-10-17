import 'package:flutter/material.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final Color darkGray = const Color(0xFF1E1E1E);
  final Color electricBlue = const Color(0xFF2979FF);

  final List<Map<String, dynamic>> _bookings = [
    {
      'id': '1',
      'parkingName': 'Downtown Mall Parking',
      'address': '123 Main St, City Center',
      'date': '2025-08-25',
      'time': '14:00 - 18:00',
      'price': 240.0,
      'status': 'confirmed',
      'vehicle': 'TS09AB1234',
      'spotNumber': 'A-12',
    },
    {
      'id': '2',
      'parkingName': 'IT Park Block C',
      'address': '456 Tech Street, Hitech City',
      'date': '2025-08-24',
      'time': '09:00 - 17:00',
      'price': 320.0,
      'status': 'completed',
      'vehicle': 'TS08CD5678',
      'spotNumber': 'B-07',
    },
    {
      'id': '3',
      'parkingName': 'Airport Terminal A',
      'address': '789 Airport Road',
      'date': '2025-08-23',
      'time': '10:30 - 12:30',
      'price': 120.0,
      'status': 'cancelled',
      'vehicle': 'TS07EF9012',
      'spotNumber': 'C-03',
    },
  ];

  String _filterStatus = 'all';

  List<Map<String, dynamic>> get _filteredBookings {
    if (_filterStatus == 'all') return _bookings;
    return _bookings.where((booking) => booking['status'] == _filterStatus).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return electricBlue;
      case 'completed':
        return Colors.greenAccent;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: darkGray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                booking['parkingName'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                booking['address'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.calendar_today, 'Date', booking['date']),
              _buildDetailRow(Icons.access_time, 'Time', booking['time']),
              _buildDetailRow(Icons.local_parking, 'Spot', booking['spotNumber']),
              _buildDetailRow(Icons.directions_car, 'Vehicle', booking['vehicle']),
              _buildDetailRow(Icons.currency_rupee, 'Amount', '₹${booking['price']}'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Chip(
                    label: Text(
                      booking['status'].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: _getStatusColor(booking['status']),
                  ),
                  const Spacer(),
                  if (booking['status'] == 'confirmed')
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _cancelBooking(booking);
                      },
                      child: const Text('Cancel Booking'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade300,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _cancelBooking(Map<String, dynamic> booking) {
    setState(() {
      final index = _bookings.indexWhere((b) => b['id'] == booking['id']);
      if (index != -1) {
        _bookings[index]['status'] = 'cancelled';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking at ${booking['parkingName']} cancelled'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGray,
      appBar: AppBar(
        title: const Text(
          'My Bookings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: darkGray,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Bookings')),
              const PopupMenuItem(value: 'confirmed', child: Text('Confirmed')),
              const PopupMenuItem(value: 'completed', child: Text('Completed')),
              const PopupMenuItem(value: 'cancelled', child: Text('Cancelled')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: _filteredBookings.isEmpty
          ? _buildEmptyState()
          : _buildBookingsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_online,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'No bookings yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Book your first parking spot to see it here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.search),
            label: const Text('Find Parking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: electricBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '${_filteredBookings.length} booking${_filteredBookings.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (_filterStatus != 'all')
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filterStatus = 'all';
                    });
                  },
                  child: const Text('Clear filter'),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: _filteredBookings.length,
            itemBuilder: (context, index) {
              final booking = _filteredBookings[index];
              return _buildBookingCard(booking);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          _getStatusIcon(booking['status']),
          size: 32,
          color: _getStatusColor(booking['status']),
        ),
        title: Text(
          booking['parkingName'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              booking['address'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${booking['date']} • ${booking['time']}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${booking['price']} • ${booking['vehicle']}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
        trailing: Chip(
          label: Text(
            booking['status'].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: _getStatusColor(booking['status']),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        ),
        onTap: () => _showBookingDetails(booking),
      ),
    );
  }
}
