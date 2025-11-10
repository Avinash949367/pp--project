import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'bookings_page.dart';
import 'profile_page.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

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
  late FlutterTts _flutterTts;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastWords = '';
  Timer? _listenTimer;
  bool _voiceMode = false;
  bool _wakeWordListening = false;
  Map<String, dynamic>? _lastStationData;
  Map<String, dynamic>? _lastSlotData;

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
    _flutterTts = FlutterTts();
    _speech = stt.SpeechToText();
    _requestPermissions();
    _loadTokenAndSession();
    _startWakeWordListening();
  }

  Future<void> _requestPermissions() async {
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      // Permission granted
    } else {
      // Handle permission denied
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Microphone permission is required for voice input')),
      );
    }
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
      case 'profile':
        Navigator.pushNamed(context, '/profile');
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

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => setState(() {
          _isListening = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Speech recognition error. Please try again.')),
          );
        }),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _lastWords = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _controller.text = _lastWords;
              _sendMessage();
            }
          }),
        );
        // Start 10-second timer
        _listenTimer = Timer(const Duration(seconds: 10), () {
          _stopListening();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available.')),
        );
      }
    } else {
      _stopListening();
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
    _listenTimer?.cancel();
  }

  void _activateVoiceMode() {
    setState(() => _voiceMode = true);
    _listen();
    _flutterTts.setVolume(1.0);
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setPitch(1.0);
    _flutterTts
        .speak("Voice mode activated. Say 'hey vision' to start listening.");
  }

  void _deactivateVoiceMode() {
    setState(() => _voiceMode = false);
    _stopListening();
    _flutterTts.speak("Voice mode deactivated.");
  }

  void _checkWakeWord(String text) {
    if (text.toLowerCase().contains('hey vision') && !_voiceMode) {
      _activateVoiceMode();
    }
  }

  void _startWakeWordListening() async {
    if (!_wakeWordListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('Wake word listening status: $val'),
        onError: (val) => print('Wake word listening error: $val'),
      );
      if (available) {
        setState(() => _wakeWordListening = true);
        _speech.listen(
          onResult: (val) {
            String recognizedText = val.recognizedWords.toLowerCase();
            print('Wake word detected: $recognizedText');
            if (recognizedText.contains('hey vision') && !_voiceMode) {
              _activateVoiceMode();
            }
          },
          listenFor: const Duration(seconds: 30), // Listen continuously
          pauseFor: const Duration(seconds: 5), // Pause briefly between listens
          partialResults: true,
          onSoundLevelChange: (level) => print('Sound level: $level'),
        );
      }
    }
  }

  void _handleAction(String action, String screen, dynamic data) {
    switch (action) {
      case 'navigate':
        _navigateToScreen(screen, data: data);
        break;
      case 'display':
        // Handle display actions like showing data in chat
        if (screen == 'payments' && data != null) {
          setState(() {
            _messages.add(
                {'sender': 'bot', 'text': 'Here is your payment history:'});
            if (data is List && data.isNotEmpty) {
              for (var payment in data) {
                String paymentText =
                    'Amount: ₹${payment['amount'] ?? 'N/A'}\nDate: ${payment['date'] ?? 'N/A'}\nStatus: ${payment['status'] ?? 'N/A'}';
                _messages.add({'sender': 'bot', 'text': paymentText});
              }
            } else {
              _messages
                  .add({'sender': 'bot', 'text': 'No payment history found.'});
            }
          });
        } else if (screen == 'emergency') {
          setState(() {
            _messages.add({
              'sender': 'bot',
              'text': 'Emergency contacts: Police - 100, Ambulance - 108.'
            });
          });
        }
        break;
      case 'cancel':
        // Show confirmation dialog for cancellation
        _showConfirmationDialog(
            'Cancel Booking', 'Are you sure you want to cancel this booking?',
            () {
          // Implement cancellation logic
          setState(() {
            _messages.add(
                {'sender': 'bot', 'text': 'Booking cancelled successfully.'});
          });
        });
        break;
      case 'logout':
        _showConfirmationDialog('Logout', 'Are you sure you want to logout?',
            () {
          // Implement logout logic
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
        });
        break;
      default:
        // Handle unknown actions
        break;
    }
  }

  void _showConfirmationDialog(
      String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
            ),
          ],
        );
      },
    );
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

    // Determine AI service URL based on platform
    String aiServiceUrl;
    if (kIsWeb) {
      aiServiceUrl = 'http://localhost:8000/chat';
    } else if (Platform.isAndroid) {
      aiServiceUrl = 'http://10.0.2.2:8000/chat';
    } else if (Platform.isIOS) {
      aiServiceUrl = 'http://localhost:8000/chat';
    } else {
      aiServiceUrl = 'http://localhost:8000/chat'; // default fallback
    }

    try {
      final response = await http.post(
        Uri.parse(aiServiceUrl),
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

        // Debug prints
        print('AI Response: ${data.toString()}');
        print(
            'Action: $action, Screen: $screen, Data: ${navData != null ? 'has data' : 'no data'}');

        // Handle navigation based on action and screen
        if (action == 'navigate' && screen != null) {
          // Add the bot response message before navigating
          setState(() {
            _messages.add({'sender': 'bot', 'text': botResponse});
          });
          // Speak the response
          await _flutterTts.speak(botResponse);
          // Then perform navigation
          _navigateToScreen(screen, data: navData);
        } else if (action == 'cancel' || action == 'logout') {
          _handleAction(action, screen ?? '', navData);
        } else if (action == 'display' &&
            (screen == 'payments' ||
                screen == 'emergency' ||
                screen == 'bookings') &&
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
          // Speak the response
          await _flutterTts.setVolume(1.0);
          await _flutterTts.setSpeechRate(0.5);
          await _flutterTts.setPitch(1.0);
          await _flutterTts.speak(botResponse);
        } else if (action == 'display' &&
            screen == 'stations' &&
            navData != null) {
          // Store station data for context
          if (navData is List && navData.isNotEmpty) {
            _lastStationData = navData[0]; // Store first station for context
          }

          // Display stations directly in chat
          setState(() {
            List<Map<String, dynamic>> newMessages = List.from(_messages);
            newMessages.add({'sender': 'bot', 'text': botResponse});
            if (navData is List && navData.isNotEmpty) {
              for (var station in navData) {
                String stationText =
                    'Station: ${station['name'] ?? 'Unknown Station'}\n'
                    'Address: ${station['address'] ?? 'N/A'}\n'
                    'City: ${station['city'] ?? 'N/A'}\n'
                    'Slots: ${station['slots'] ?? 'N/A'}\n'
                    'Price: ₹${station['price'] ?? 'N/A'}';
                newMessages.add({'sender': 'bot', 'text': stationText});
              }
              // Add "View Slots" button instead of generic "View Details"
              newMessages.add({
                'sender': 'bot',
                'text': 'View Slots',
                'action': 'view_slots',
                'data': navData
              });
            } else {
              newMessages
                  .add({'sender': 'bot', 'text': 'No parking stations found.'});
            }
            _messages = newMessages;
          });
          // Speak the response
          await _flutterTts.speak(botResponse);
        } else if (action == 'display' &&
            screen == 'slots' &&
            navData != null) {
          // Store slot data for context
          if (navData is List && navData.isNotEmpty) {
            _lastSlotData = navData[0]; // Store first slot for context
          }

          // Debug print for slots data
          print('Slots data received: $navData');

          // Display slots directly in chat
          setState(() {
            List<Map<String, dynamic>> newMessages = List.from(_messages);
            newMessages.add({'sender': 'bot', 'text': botResponse});
            if (navData is List && navData.isNotEmpty) {
              String slotsList = 'Available Slots:\n\n';
              for (var slot in navData) {
                slotsList +=
                    '• Slot ID: ${slot['slotId'] ?? 'N/A'} | Type: ${slot['type'] ?? 'N/A'} | Price: ₹${slot['price'] ?? 'N/A'} | Status: ${slot['availability'] ?? 'N/A'}\n';
              }
              newMessages.add({'sender': 'bot', 'text': slotsList});
              // Add "Book Slot" button or similar
              newMessages.add({
                'sender': 'bot',
                'text': 'Select a Slot to Book',
                'action': 'book_slot',
                'data': navData
              });
            } else {
              newMessages.add({'sender': 'bot', 'text': 'No slots available.'});
            }
            _messages = newMessages;
          });
          // Speak the response
          await _flutterTts.speak(botResponse);
        } else {
          setState(() {
            _messages.add({'sender': 'bot', 'text': botResponse});
          });
          // Speak the response
          await _flutterTts.speak(botResponse);
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
                        if (hasAction && msg['action'] == 'book_slot')
                          ElevatedButton(
                            onPressed: () {
                              _navigateToScreen('book_slot', data: msg['data']);
                            },
                            child: const Text('Book a Slot'),
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
                    onChanged: _checkWakeWord,
                  ),
                ),
                IconButton(
                  icon: _isListening
                      ? const Icon(Icons.mic, color: Colors.red)
                      : const Icon(Icons.mic_none, color: Color(0xFF1E90FF)),
                  onPressed: _listen,
                ),
                IconButton(
                  icon: const Icon(Icons.stop, color: Colors.red),
                  onPressed: _stopListening,
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
