import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // App Preferences
  bool _darkMode = true;
  String _language = 'English';
  String _defaultParkingZone = 'Zone A';

  // Notification Controls
  bool _bookingReminders = true;
  bool _entryExitAlerts = true;
  bool _paymentAlerts = true;
  bool _promotionalUpdates = false;

  // AI Assistant Preferences (UI only)
  bool _enableVoiceCommands = false;
  String _voiceType = 'Neutral';

  final List<String> _languages = ['English', 'Hindi', 'Spanish'];
  final List<String> _parkingZones = ['Zone A', 'Zone B', 'Zone C'];
  final List<String> _voiceTypes = ['Male', 'Female', 'Neutral'];

  // Controllers for password change dialog
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  // Removed the separate controller for verification code dialog to create local controller instead
  // final TextEditingController _verificationCodeDialogController =
  //     TextEditingController();

  // Password visibility toggles
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isVerificationNewPasswordVisible = false;
  bool _isVerificationConfirmPasswordVisible = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    // Removed disposal of _verificationCodeDialogController as it is removed
    super.dispose();
  }

  Future<String?> _getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail');
  }

  Future<bool> _verifyCurrentPassword(String email, String password) async {
    final url = Uri.parse('http://localhost:8000/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'email': email, 'password': password},
      );
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('Error verifying password: $e');
    }
    return false;
  }

  Future<bool> _sendVerificationCode(String email) async {
    final url = Uri.parse('http://localhost:8000/send-verification-code');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'email': email},
      );
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('Error sending verification code: $e');
    }
    return false;
  }

  Future<bool> _verifyCodeAndChangePassword(
      String email, String code, String newPassword) async {
    final url = Uri.parse('http://localhost:8000/change-password-with-code');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'email': email, 'code': code, 'new_password': newPassword},
      );
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('Error changing password with code: $e');
    }
    return false;
  }

  Future<bool> _changePassword(
      String email, String currentPassword, String newPassword) async {
    final url = Uri.parse('http://localhost:8000/change-password');
    final body = Uri(queryParameters: {
      'current_password': currentPassword,
      'new_password': newPassword,
    }).query;
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-User-Email': email,
        },
        body: body,
      );
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('Error changing password: $e');
    }
    return false;
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1F2937),
              title: const Text('Change Password',
                  style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: !_isCurrentPasswordVisible,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isCurrentPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isCurrentPasswordVisible =
                                  !_isCurrentPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: !_isNewPasswordVisible,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isNewPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isNewPasswordVisible = !_isNewPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _clearControllers();
                  },
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () => _handlePasswordChange(),
                  child: const Text('Change Password',
                      style: TextStyle(color: Colors.blue)),
                ),
                TextButton(
                  onPressed: () async {
                    final email = await _getUserEmail();
                    if (email == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User not logged in')),
                      );
                      return;
                    }
                    final success = await _sendVerificationCode(email);
                    if (success) {
                      Navigator.of(context).pop();
                      _showVerificationCodeDialog();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Failed to send verification code')),
                      );
                    }
                  },
                  child: const Text('Try any other',
                      style: TextStyle(color: Colors.orange)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showVerificationCodeDialog() {
    _clearControllers(); // Clear text before showing dialog
    // Removed Navigator.of(context).pop(); to prevent double pop

    final TextEditingController verificationCodeController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1F2937),
              title: const Text('Verify Email',
                  style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'A 4-digit verification code has been sent to your email.',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: verificationCodeController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Verification Code',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: !_isVerificationNewPasswordVisible,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isVerificationNewPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isVerificationNewPasswordVisible =
                                  !_isVerificationNewPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: !_isVerificationConfirmPasswordVisible,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isVerificationConfirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isVerificationConfirmPasswordVisible =
                                  !_isVerificationConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // _clearControllers(); // Removed here to avoid clearing after dispose
                  },
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    final code = verificationCodeController.text;
                    _handleVerificationAndChangeWithCode(code);
                  },
                  child: const Text('Verify & Change',
                      style: TextStyle(color: Colors.blue)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handlePasswordChange() async {
    final email = await _getUserEmail();
    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('New password must be at least 6 characters')),
      );
      return;
    }

    final isCurrentPasswordValid =
        await _verifyCurrentPassword(email, currentPassword);
    if (!isCurrentPasswordValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current password is incorrect')),
      );
      return;
    }

    final success = await _changePassword(email, currentPassword, newPassword);
    if (success) {
      Navigator.of(context).pop();
      _clearControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to change password')),
      );
    }
  }

  void _handleVerificationAndChange() async {
    // This method is replaced by _handleVerificationAndChangeWithCode
  }

  void _handleVerificationAndChangeWithCode(String code) async {
    final email = await _getUserEmail();
    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 4-digit code')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('New password must be at least 6 characters')),
      );
      return;
    }

    final success =
        await _verifyCodeAndChangePassword(email, code, newPassword);
    if (success) {
      Navigator.of(context).pop();
      _clearControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Invalid verification code or failed to change password')),
      );
    }
  }

  void _clearControllers() {
    // Only clear text, do not dispose controllers here
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    // Removed _verificationCodeDialogController.clear(); as controller is removed
    _isCurrentPasswordVisible = false;
    _isNewPasswordVisible = false;
    _isConfirmPasswordVisible = false;
    _isVerificationNewPasswordVisible = false;
    _isVerificationConfirmPasswordVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF1F2937),
      ),
      backgroundColor: const Color(0xFF111827),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. App Preferences
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text('App Preferences',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            ),
            Card(
              color: const Color(0xFF1F2937),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode, color: Colors.white),
                    title: const Text('Dark Mode',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    value: _darkMode,
                    onChanged: (val) {
                      setState(() {
                        _darkMode = val;
                      });
                    },
                  ),
                  const Divider(color: Colors.grey, height: 1),
                  ListTile(
                    leading: const Icon(Icons.language, color: Colors.white),
                    title: const Text('Language',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    trailing: DropdownButton<String>(
                      dropdownColor: const Color(0xFF1F2937),
                      value: _language,
                      items: _languages
                          .map((lang) => DropdownMenuItem(
                              value: lang,
                              child: Text(lang,
                                  style: const TextStyle(color: Colors.white))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _language = val;
                          });
                        }
                      },
                    ),
                  ),
                  const Divider(color: Colors.grey, height: 1),
                  ListTile(
                    leading:
                        const Icon(Icons.local_parking, color: Colors.white),
                    title: const Text('Default Parking Zone',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    trailing: DropdownButton<String>(
                      dropdownColor: const Color(0xFF1F2937),
                      value: _defaultParkingZone,
                      items: _parkingZones
                          .map((zone) => DropdownMenuItem(
                              value: zone,
                              child: Text(zone,
                                  style: const TextStyle(color: Colors.white))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _defaultParkingZone = val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 2. Notification Controls
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text('Notification Controls',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            ),
            Card(
              color: const Color(0xFF1F2937),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary:
                        const Icon(Icons.calendar_today, color: Colors.white),
                    title: const Text('Booking Reminders',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    value: _bookingReminders,
                    onChanged: (val) {
                      setState(() {
                        _bookingReminders = val;
                      });
                    },
                  ),
                  const Divider(color: Colors.grey, height: 1),
                  SwitchListTile(
                    secondary:
                        const Icon(Icons.directions_car, color: Colors.white),
                    title: const Text('Entry & Exit Alerts',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    value: _entryExitAlerts,
                    onChanged: (val) {
                      setState(() {
                        _entryExitAlerts = val;
                      });
                    },
                  ),
                  const Divider(color: Colors.grey, height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.payment, color: Colors.white),
                    title: const Text('Payment Alerts',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    value: _paymentAlerts,
                    onChanged: (val) {
                      setState(() {
                        _paymentAlerts = val;
                      });
                    },
                  ),
                  const Divider(color: Colors.grey, height: 1),
                  SwitchListTile(
                    secondary:
                        const Icon(Icons.local_offer, color: Colors.white),
                    title: const Text('Promotional Updates',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    value: _promotionalUpdates,
                    onChanged: (val) {
                      setState(() {
                        _promotionalUpdates = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 3. Privacy & Security
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text('Privacy & Security',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            ),
            Card(
              color: const Color(0xFF1F2937),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.lock_reset),
                      label: const Text('Change Password'),
                      onPressed: () {
                        _showChangePasswordDialog();
                      },
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40)),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.cleaning_services),
                      label: const Text('Clear Search History'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Clear Search History clicked')));
                      },
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40)),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Delete Account'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Delete Account clicked')));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size.fromHeight(40),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 4. AI Assistant Preferences (UI only)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text('AI Assistant Preferences',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            ),
            Card(
              color: const Color(0xFF1F2937),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.mic, color: Colors.white),
                    title: const Text('Enable Voice Commands',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    value: _enableVoiceCommands,
                    onChanged: (val) {
                      setState(() {
                        _enableVoiceCommands = val;
                      });
                    },
                  ),
                  const Divider(color: Colors.grey, height: 1),
                  ListTile(
                    leading: const Icon(Icons.record_voice_over,
                        color: Colors.white),
                    title: const Text('Voice Type',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    trailing: DropdownButton<String>(
                      dropdownColor: const Color(0xFF1F2937),
                      value: _voiceType,
                      items: _voiceTypes
                          .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type,
                                  style: const TextStyle(color: Colors.white))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _voiceType = val;
                          });
                        }
                      },
                    ),
                  ),
                  const Divider(color: Colors.grey, height: 1),
                  ListTile(
                    leading: const Icon(Icons.shortcut, color: Colors.white),
                    title: const Text('Command Shortcuts',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    trailing: ElevatedButton(
                      onPressed: null, // Disabled for now
                      child: const Text('Edit'),
                    ),
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
