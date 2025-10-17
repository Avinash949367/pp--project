import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'bookings_page.dart';
import 'login_widget.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isLoggedIn = false;
  String userName = "";
  String userEmail = "";
  String? profileImageUrl;
  String? phoneNumber;

  final TextEditingController editNameController = TextEditingController();
  final TextEditingController editPhoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserCredentials();
  }

  Future<void> _loadUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('userEmail');
    final name = prefs.getString('userName');
    final imageUrl = prefs.getString('profileImageUrl');
    if (email != null && name != null) {
      setState(() {
        isLoggedIn = true;
        userEmail = email;
        userName = name;
        profileImageUrl = imageUrl;
      });
      // Fetch latest user data from backend
      await _fetchUserData(email);
    }
  }

  Future<void> _fetchUserData(String email) async {
    final url = Uri.parse('http://localhost:5000/api/users/email/$email');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userName = data['name'] ?? userName;
          userEmail = data['email'] ?? userEmail;
          profileImageUrl = data['profileImage'];
          phoneNumber = data['phone'];
          editNameController.text = userName;
          editPhoneController.text = phoneNumber ?? '';
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', userName);
        await prefs.setString('userEmail', userEmail);
        await prefs.setString('phoneNumber', phoneNumber ?? '');
        if (profileImageUrl != null) {
          await prefs.setString('profileImageUrl', profileImageUrl!);
        }
      }
    } catch (e) {
      // Handle error silently or show a message
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

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadProfileImage(File imageFile) async {
    final url =
        Uri.parse('http://localhost:5000/api/user/profile/upload-image');
    final request = http.MultipartRequest('POST', url);
    request.files
        .add(await http.MultipartFile.fromPath('file', imageFile.path));
    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = json.decode(respStr);
        return data['url'];
      }
    } catch (e) {
      _showError('Image upload failed: $e');
    }
    return null;
  }

  Future<void> _showEditProfileDialog() async {
    editNameController.text = userName;
    editPhoneController.text = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1F2937),
            title: const Text('Edit Profile',
                style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await _pickImage();
                      setState(() {});
                    },
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (profileImageUrl != null &&
                                      profileImageUrl!.isNotEmpty
                                  ? NetworkImage(profileImageUrl!)
                                  : const AssetImage("assets/profile.png"))
                              as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: editNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1F2937),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: editPhoneController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1F2937),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1F2937),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      hintText: userEmail,
                      hintStyle: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6)),
                onPressed: () async {
                  String? uploadedImageUrl = profileImageUrl;
                  if (_imageFile != null) {
                    final url = await _uploadProfileImage(_imageFile!);
                    if (url != null) {
                      uploadedImageUrl = url;
                    } else {
                      return;
                    }
                  }
                  final success = await _updateUserProfile(
                    userEmail,
                    editNameController.text,
                    editPhoneController.text,
                    uploadedImageUrl,
                  );
                  if (success) {
                    setState(() {
                      userName = editNameController.text;
                      profileImageUrl = uploadedImageUrl;
                    });
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('userName', userName);
                    if (profileImageUrl != null) {
                      await prefs.setString(
                          'profileImageUrl', profileImageUrl!);
                    }
                    Navigator.pop(context);
                  } else {
                    _showError('Failed to update profile');
                  }
                },
                child:
                    const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
      },
    );
  }

  Future<bool> _updateUserProfile(
      String email, String name, String phone, String? profileImage) async {
    final url = Uri.parse('http://localhost:5000/api/user/profile');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'email': email,
          'name': name,
          'phone': phone,
          if (profileImage != null) 'profileImage': profileImage,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      _showError('Error updating profile: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937),
        elevation: 0,
        title: Text(
          isLoggedIn ? "Profile" : "Login",
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: isLoggedIn
            ? [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: _showEditProfileDialog,
                )
              ]
            : null,
      ),
      body: isLoggedIn ? _buildProfileView() : _buildLoginView(),
    );
  }

  // ---------------- Profile Page ----------------
  Widget _buildProfileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Profile Header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      (profileImageUrl != null && profileImageUrl!.isNotEmpty
                              ? NetworkImage(profileImageUrl!)
                              : const AssetImage("assets/profile.png"))
                          as ImageProvider<Object>?,
                ),
                const SizedBox(height: 12),
                Text(userName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Text(userEmail,
                    style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 10),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Account Options
          _buildListTile(Icons.history, "My Bookings"),
          _buildListTile(Icons.directions_car, "My Vehicles"),
          _buildListTile(Icons.payment, "My Payments"),
          _buildListTile(Icons.notifications, "Notifications"),
          _buildListTile(Icons.settings, "Settings"),
          _buildListTile(Icons.help, "Help & Support"),

          const SizedBox(height: 20),

          // Logout
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('userEmail');
              await prefs.remove('userName');
              await prefs.remove('profileImageUrl');
              setState(() {
                isLoggedIn = false;
                userName = "";
                userEmail = "";
                profileImageUrl = null;
              });
            },
            child: const Text("Logout",
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // ---------------- Login Page ----------------
  Widget _buildLoginView() {
    return LoginWidget(onLoginSuccess: () {
      // Navigate to main landing page after login success
      Navigator.pushReplacementNamed(context, '/quickbook');
    });
  }

  // ---------------- Signup Pop-Up ----------------
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
                  setState(() {
                    isLoggedIn = true;
                    userEmail = signupEmail.text;
                    userName = signupName.text;
                  });
                  Navigator.pop(context);
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

  // ---------------- Widgets ----------------
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

  Widget _buildListTile(IconData icon, String title) {
    return Card(
      color: const Color(0xFF1F2937),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF3B82F6)),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing:
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        onTap: () async {
          if (title == "My Bookings") {
            final prefs = await SharedPreferences.getInstance();
            final userEmail = prefs.getString('userEmail');
            if (userEmail == null) {
              _showError('User not logged in');
              return;
            }
            // Fetch user ID from backend using email
            final userId = await _fetchUserIdByEmail(userEmail);
            if (userId == null) {
              _showError('User ID not found');
              return;
            }
            // Fetch bookings using user ID
            final bookings = await _fetchBookings(userId);
            if (!mounted) return;
            if (bookings == null) {
              _showError('Failed to load bookings');
              return;
            }
            // Navigate to bookings page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingsPage(
                    bookings: bookings
                        .map((booking) => Map<String, dynamic>.from(booking))
                        .toList()),
              ),
            );
          } else if (title == "My Vehicles") {
            final vehicles = await _fetchVehicles();
            if (!mounted) return;
            if (vehicles == null) {
              _showError('Failed to load vehicles');
              return;
            }
            _showVehiclesDialog(vehicles);
          } else if (title == "My Payments") {
            final payments = await _fetchPayments();
            if (!mounted) return;
            if (payments == null) {
              _showError('Failed to load payments');
              return;
            }
            _showPaymentsDialog(payments);
          } else if (title == "Notifications") {
            Navigator.pushNamed(context, '/settings');
          } else if (title == "Settings") {
            Navigator.pushNamed(context, '/settings');
          } else if (title == "Help & Support") {
            _showHelpSupportDialog();
          }
        },
      ),
    );
  }

  void _showHelpSupportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          title: const Text('Help & Support',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.email, color: Colors.white),
                title:
                    const Text('Email', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: 'parkproplus@gmail.com',
                  );
                  if (await canLaunchUrl(emailLaunchUri)) {
                    await launchUrl(emailLaunchUri);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.white),
                title:
                    const Text('Phone', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  final Uri phoneLaunchUri = Uri(
                    scheme: 'tel',
                    path: '8309113119',
                  );
                  if (await canLaunchUrl(phoneLaunchUri)) {
                    await launchUrl(phoneLaunchUri);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat, color: Colors.white),
                title: const Text('WhatsApp',
                    style: TextStyle(color: Colors.white)),
                onTap: () async {
                  final Uri whatsappLaunchUri =
                      Uri.parse('https://wa.me/8309113119');
                  if (await canLaunchUrl(whatsappLaunchUri)) {
                    await launchUrl(whatsappLaunchUri);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _fetchUserIdByEmail(String email) async {
    final url = Uri.parse('http://localhost:5000/api/users/email/$email');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['_id'];
      }
    } catch (e) {
      _showError('Error fetching user ID: $e');
    }
    return null;
  }

  Future<List<dynamic>?> _fetchBookings(String userId) async {
    String backendUrl;
    if (kIsWeb) {
      backendUrl = 'http://localhost:5000/api/slots/slotbookings/$userId';
    } else if (Platform.isAndroid) {
      backendUrl = 'http://10.0.2.2:5000/api/slots/slotbookings/$userId';
    } else if (Platform.isIOS) {
      backendUrl = 'http://localhost:5000/api/slots/slotbookings/$userId';
    } else {
      backendUrl =
          'http://localhost:5000/api/slots/slotbookings/$userId'; // default fallback
    }
    final url = Uri.parse(backendUrl);
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      }
    } catch (e) {
      _showError('Error fetching bookings: $e');
    }
    return null;
  }

  Future<bool> _sendVerificationCode(String email) async {
    final url = Uri.parse('http://localhost:5000/send-verification-code');
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
    final url = Uri.parse('http://localhost:5000/change-password-with-code');
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

  Future<List<dynamic>?> _fetchVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      _showError('No token found');
      return null;
    }
    String backendUrl;
    if (kIsWeb) {
      backendUrl = 'http://localhost:5000/api/user/vehicles';
    } else if (Platform.isAndroid) {
      backendUrl = 'http://10.0.2.2:5000/api/user/vehicles';
    } else if (Platform.isIOS) {
      backendUrl = 'http://localhost:5000/api/user/vehicles';
    } else {
      backendUrl =
          'http://localhost:5000/api/user/vehicles'; // default fallback
    }
    final url = Uri.parse(backendUrl);
    try {
      final response =
          await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      }
    } catch (e) {
      _showError('Error fetching vehicles: $e');
    }
    return null;
  }

  Future<List<dynamic>?> _fetchPayments() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      _showError('No token found');
      return null;
    }
    String backendUrl;
    if (kIsWeb) {
      backendUrl = 'http://localhost:5000/api/user/payments';
    } else if (Platform.isAndroid) {
      backendUrl = 'http://10.0.2.2:5000/api/user/payments';
    } else if (Platform.isIOS) {
      backendUrl = 'http://localhost:5000/api/user/payments';
    } else {
      backendUrl =
          'http://localhost:5000/api/user/payments'; // default fallback
    }
    final url = Uri.parse(backendUrl);
    try {
      final response =
          await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      }
    } catch (e) {
      _showError('Error fetching payments: $e');
    }
    return null;
  }

  void _showVehiclesDialog(List<dynamic> vehicles) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          title:
              const Text('My Vehicles', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return ListTile(
                  title: Text(vehicle['licensePlate'] ?? 'Unknown',
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text('${vehicle['make']} ${vehicle['model']}',
                      style: const TextStyle(color: Colors.grey)),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentsDialog(List<dynamic> payments) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          title:
              const Text('My Payments', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return ListTile(
                  title: Text('Amount: ${payment['amount']}',
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text('Date: ${payment['date']}',
                      style: const TextStyle(color: Colors.grey)),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
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
}
