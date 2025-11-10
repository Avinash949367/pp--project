import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'login_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('userEmail');
      final token = prefs.getString('token');

      // Check both email and token for better security
      final bool isAuthenticated = userEmail != null &&
          userEmail.isNotEmpty &&
          token != null &&
          token.isNotEmpty;

      setState(() {
        _isLoggedIn = isAuthenticated;
        _isLoading = false;
      });
    } catch (e) {
      // Handle any errors gracefully
      print('Error checking login status: $e');
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  void _onLoginSuccess() {
    Navigator.pushReplacementNamed(context, '/quickbook');
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // You can add your app logo here
            Image.asset(
              'assets/images/logo.png',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2979FF)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Park-Pro+',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_isLoggedIn) {
      // Navigate to main landing page after splash if logged in
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/quickbook');
      });
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: Center(
        child: LoginWidget(onLoginSuccess: _onLoginSuccess),
      ),
    );
  }
}
