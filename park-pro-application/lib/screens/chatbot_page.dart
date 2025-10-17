import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'bookings_page.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _messages =
      []; // {'sender':'user/bot', 'text': '...'}
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _sessionId = const Uuid().v4(); // Generate unique session ID
  bool _isLoading = false;
  String _token = '';

  @override
  void initState() {
    super.initState();
    _loadTokenAndSession();
  }

  Future<void> _loadTokenAndSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token') ?? '';
      _sessionId = prefs.getString('userEmail') ?? _sessionId;
    });
  }

  Future<void> _navigateToScreen(String screen, {dynamic data}) async {
    switch (screen) {
      case 'bookings':
        // Use provided data or fetch bookings
        List<dynamic> bookings = data ?? await _fetchBookings() ?? [];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingsPage(
                bookings: bookings
                    .map((booking) => Map<String, dynamic>.from(booking))
                    .toList()),
          ),
        );
        break;
      case 'book_slot':
        Navigator.pushNamed(context, '/book-slot');
        break;
      case 'search':
        // Assuming search is part of home page or a separate screen
        Navigator.pushNamed(context, '/search');
        break;
      default:
        // Handle unknown screens or show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navigation to $screen not implemented yet')),
        );
    }
  }

  Future<List<Map<String, dynamic>>?> _fetchBookings() async {
    String backendUrl;
    if (kIsWeb) {
      backendUrl = 'http://localhost:5000/api/user/bookings';
    } else if (Platform.isAndroid) {
      backendUrl = 'http://10.0.2.2:5000/api/user/bookings';
    } else if (Platform.isIOS) {
      backendUrl = 'http://localhost:5000/api/user/bookings';
    } else {
      backendUrl =
          'http://localhost:5000/api/user/bookings'; // default fallback
    }
    final url = Uri.parse(backendUrl);
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final bookings = data['bookings'];
        if (bookings is List) {
          return bookings
              .map((booking) => Map<String, dynamic>.from(booking))
              .toList();
        } else {
          return [];
        }
      }
    } catch (e) {
      print('Error fetching bookings: $e');
    }
    return null;
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _isLoading) return;

    final userMessage = _controller.text.trim();
    setState(() {
      _messages.add({'sender': 'user', 'text': userMessage});
      _isLoading = true;
    });
    _controller.clear();

    // Reload token in case it changed
    await _loadTokenAndSession();

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': userMessage,
          'session_id': _sessionId,
          'token': _token,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botResponse =
            data['response'] ?? 'Sorry, I couldn\'t understand that.';
        final action = data['action'];
        final screen = data['screen'];
        final navData = data['data'];

        // Handle navigation based on action and screen
        if (action == 'navigate' && screen != null) {
          _navigateToScreen(screen, data: navData);
        } else if (action == 'display' &&
            screen == 'bookings' &&
            navData != null) {
          // Display bookings directly in chat
          setState(() {
            List<Map<String, dynamic>> newMessages = List.from(_messages);
            newMessages.add({'sender': 'bot', 'text': botResponse});
            if (navData is List && navData.isNotEmpty) {
              for (var booking in navData) {
                String bookingText =
                    'Station: ${booking['stationName'] ?? 'Unknown Station'}\n'
                    'Vehicle: ${booking['vehicle'] ?? 'Unknown Vehicle'}\n'
                    'Time: ${booking['bookingStartTime'] ?? 'N/A'} - ${booking['bookingEndTime'] ?? 'N/A'}\n'
                    'Status: ${booking['status'] ?? 'N/A'}';
                newMessages.add({'sender': 'bot', 'text': bookingText});
              }
              // Add "View Details" button
              newMessages.add({
                'sender': 'bot',
                'text': 'View Details',
                'action': 'view_details',
                'data': navData
              });
            } else {
              newMessages
                  .add({'sender': 'bot', 'text': 'You have no bookings yet.'});
            }
            _messages = newMessages;
          });
        } else {
          setState(() {
            _messages.add({'sender': 'bot', 'text': botResponse});
          });
        }
      } else {
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': 'Error: Unable to connect to AI service.'
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'sender': 'bot', 'text': 'Error: ${e.toString()}'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E2E2E), // Dark Gray
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E90FF), // Electric Blue
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              child: ClipOval(
                child: Image.asset(
                  'assets/chatbot.png', // <-- your image path
                  fit: BoxFit.cover,
                  width: 30,
                  height: 30,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Park-Pro Chatbot',
                style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['sender'] == 'user';
                final hasAction = msg['action'] != null;
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF1E90FF)
                          : Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['text']!,
                          style: TextStyle(
                            fontSize: 16,
                            color: isUser ? Colors.white : Colors.white70,
                          ),
                        ),
                        if (hasAction && msg['action'] == 'view_details')
                          ElevatedButton(
                            onPressed: () {
                              _navigateToScreen('bookings', data: msg['data']);
                            },
                            child: const Text('View Details'),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Colors.white30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: const Color(0xFF3A3A3A),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF1E90FF)),
                          ),
                        )
                      : const Icon(Icons.send, color: Color(0xFF1E90FF)),
                  onPressed: _isLoading ? null : _sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
