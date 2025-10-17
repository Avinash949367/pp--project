import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _selectedCategory = 'all';

  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'type': 'booking',
      'title': 'Booking Confirmed',
      'message': 'Your booking at Downtown Mall Parking is confirmed for today at 14:00',
      'time': '2 minutes ago',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 2)),
      'isRead': false,
      'icon': Icons.book_online,
      'color': Colors.blueAccent,
      'action': 'view_booking',
    },
    {
      'id': '2',
      'type': 'promotion',
      'title': 'Special Offer!',
      'message': 'Get 50% off on evening parking from 5 PM to 10 PM this weekend',
      'time': '1 hour ago',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
      'isRead': false,
      'icon': Icons.local_offer,
      'color': Colors.blueAccent,
      'action': 'view_offer',
    },
    // Add other notifications as needed
  ];

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_selectedCategory == 'all') return _notifications;
    return _notifications.where((n) => n['type'] == _selectedCategory).toList();
  }

  int get _unreadCount => _notifications.where((n) => !n['isRead']).length;

  void _markAsRead(String id) {
    setState(() {
      final notification = _notifications.firstWhere((n) => n['id'] == id);
      notification['isRead'] = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read'), backgroundColor: Colors.blueAccent),
    );
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        title: const Text('Clear All', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to clear all notifications?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.blueAccent)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _notifications.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications cleared'), backgroundColor: Colors.blueAccent),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) => Colors.blueAccent;

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'booking':
        return 'Bookings';
      case 'promotion':
        return 'Promotions';
      case 'reminder':
        return 'Reminders';
      case 'payment':
        return 'Payments';
      case 'system':
        return 'System';
      case 'security':
        return 'Security';
      default:
        return 'All';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E2E2E),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E90FF),
        foregroundColor: Colors.white,
        actions: [
          if (_unreadCount > 0)
            IconButton(
              icon: Stack(
                alignment: Alignment.topRight,
                children: [
                  const Icon(Icons.mark_email_read),
                  CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.redAccent,
                    child: Text(
                      _unreadCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ],
              ),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearAllNotifications,
            tooltip: 'Clear all notifications',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredNotifications.isEmpty
                ? _buildEmptyState()
                : _buildNotificationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['all', 'booking', 'promotion', 'reminder', 'payment', 'security', 'system'];
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: categories.map((category) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getCategoryLabel(category)),
              selected: _selectedCategory == category,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category : 'all';
                });
              },
              backgroundColor: Colors.grey.shade800,
              selectedColor: Colors.blueAccent,
              labelStyle: TextStyle(
                color: _selectedCategory == category ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w500,
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade600),
          const SizedBox(height: 20),
          const Text('No notifications', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          Text(
            _selectedCategory == 'all'
                ? 'You\'re all caught up!'
                : 'No ${_getCategoryLabel(_selectedCategory).toLowerCase()} notifications',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _filteredNotifications.length,
      itemBuilder: (context, index) {
        final notification = _filteredNotifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: notification['isRead'] ? const Color(0xFF3A3A3A) : Colors.blue.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: notification['color'].withOpacity(0.2),
          child: Icon(notification['icon'], color: notification['color']),
        ),
        title: Text(
          notification['title'],
          style: TextStyle(
            fontWeight: notification['isRead'] ? FontWeight.normal : FontWeight.bold,
            color: notification['isRead'] ? Colors.white70 : Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification['message'],
              style: TextStyle(color: notification['isRead'] ? Colors.white54 : Colors.white70),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              notification['time'],
              style: TextStyle(fontSize: 12, color: Colors.white38),
            ),
          ],
        ),
        onTap: () => _markAsRead(notification['id']),
      ),
    );
  }
}
