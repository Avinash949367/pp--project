import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class LoginWidget extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginWidget({Key? key, required this.onLoginSuccess}) : super(key: key);

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _login() async {
    final email = emailController.text;
    final password = passwordController.text;

    String backendUrl;
    if (kIsWeb) {
      backendUrl = 'http://localhost:5000/login';
    } else if (Platform.isAndroid) {
      backendUrl = 'http://10.0.2.2:5000/login';
    } else if (Platform.isIOS) {
      backendUrl = 'http://localhost:5000/login';
    } else {
      backendUrl = 'http://localhost:5000/login'; // default fallback
    }

    final url = Uri.parse(backendUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userEmail', data['user']['email'] ?? email);
        await prefs.setString('userName', data['user']['name'] ?? 'User');
        await prefs.setString('userId', data['user']['_id']);
        await prefs.setString('token', data['token']);
        widget.onLoginSuccess();
      } else {
        _showError('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  void _handleForgotPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showError('Please enter your email first');
      return;
    }
    final success = await _sendVerificationCode(email);
    if (success) {
      _showForgotPasswordDialog();
    } else {
      _showError('Failed to send verification code');
    }
  }

  Future<bool> _sendVerificationCode(String email) async {
    String backendUrl;
    if (kIsWeb) {
      backendUrl = 'http://localhost:5000/send-verification-code';
    } else if (Platform.isAndroid) {
      backendUrl = 'http://10.0.2.2:5000/send-verification-code';
    } else if (Platform.isIOS) {
      backendUrl = 'http://localhost:5000/send-verification-code';
    } else {
      backendUrl =
          'http://localhost:5000/send-verification-code'; // default fallback
    }
    final url = Uri.parse(backendUrl);
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
    String backendUrl;
    if (kIsWeb) {
      backendUrl = 'http://localhost:5000/change-password-with-code';
    } else if (Platform.isAndroid) {
      backendUrl = 'http://10.0.2.2:5000/change-password-with-code';
    } else if (Platform.isIOS) {
      backendUrl = 'http://localhost:5000/change-password-with-code';
    } else {
      backendUrl =
          'http://localhost:5000/change-password-with-code'; // default fallback
    }
    final url = Uri.parse(backendUrl);
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

  void _showForgotPasswordDialog() {
    final TextEditingController codeController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    bool _isNewPasswordVisible = false;
    bool _isConfirmPasswordVisible = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1F2937),
              title: const Text('Reset Password',
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
                      controller: codeController,
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
                      controller: newPasswordController,
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
                      controller: confirmPasswordController,
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () async {
                    final code = codeController.text;
                    final newPassword = newPasswordController.text;
                    final confirmPassword = confirmPasswordController.text;
                    final email = emailController.text;

                    if (code.length != 4) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter a valid 4-digit code')),
                      );
                      return;
                    }

                    if (newPassword != confirmPassword) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('New passwords do not match')),
                      );
                      return;
                    }

                    if (newPassword.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'New password must be at least 6 characters')),
                      );
                      return;
                    }

                    final success = await _verifyCodeAndChangePassword(
                        email, code, newPassword);
                    if (success) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Password reset successfully')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Invalid code or failed to reset password')),
                      );
                    }
                  },
                  child: const Text('Reset Password',
                      style: TextStyle(color: Colors.blue)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSignupDialog(BuildContext context) {
    final TextEditingController signupEmail = TextEditingController();
    final TextEditingController signupName = TextEditingController();
    final TextEditingController signupPassword = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          title: const Text("Sign Up", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: signupName,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Name"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: signupEmail,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Email"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: signupPassword,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Password"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6)),
              onPressed: () {
                if (signupEmail.text.isNotEmpty &&
                    signupName.text.isNotEmpty &&
                    signupPassword.text.isNotEmpty) {
                  Navigator.pop(context);
                  // Optionally, you can add signup logic here
                }
              },
              child:
                  const Text("Sign Up", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF1F2937),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Login to Park-Pro+",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: emailController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration("Email"),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1F2937),
              hintText: "Password",
              hintStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final email = emailController.text.trim();
              final password = passwordController.text.trim();
              if (email.isNotEmpty && password.isNotEmpty) {
                print('Login button pressed with email: $email');
                _login();
              } else {
                _showError('Please enter both email and password');
              }
            },
            child: const Text("Login",
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          TextButton(
            onPressed: () {
              _handleForgotPassword();
            },
            child: const Text("Forgot Password?",
                style: TextStyle(color: Colors.orangeAccent)),
          ),
          TextButton(
            onPressed: () {
              _showSignupDialog(context);
            },
            child: const Text("Don’t have an account? Sign Up",
                style: TextStyle(color: Colors.blueAccent)),
          )
        ],
      ),
    );
  }
}
