import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eduthon/screens/otp_screen.dart';
import 'package:eduthon/screens/auth/signup_screen.dart';
import 'package:eduthon/services/database_helper.dart'; // Import DB Helper
import 'package:eduthon/services/auth_service.dart'; // Import Auth Service
import 'package:eduthon/screens/main_layout.dart'; // Import Student Dashboard
import 'package:eduthon/screens/teacher/teacher_dashboard.dart'; // Import Teacher Dashboard
import 'package:http/http.dart' as http;
import 'dart:convert'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required void Function() onSignupTap});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  final String _baseUrl = "http://192.168.1.4:8000";

  @override
  void initState() {
    super.initState();
    _runBetaTestDiagnostics();
  }

  Future<void> _runBetaTestDiagnostics() async {
    print("DEBUG: --- STARTING BETA TEST DIAGNOSTICS ---");
    
    // 1. Check if DB has the new table
    try {
      final students = await DatabaseHelper.instance.database.then((db) => db.query('registered_students'));
      print("DEBUG: Table 'registered_students' exists. Count: ${students.length}");
    } catch (e) {
      print("DEBUG: CRITICAL ERROR - Table 'registered_students' MISSING! Migration failed? Error: $e");
    }

    // 2. Check Specific Numbers
    final testNumbers = ["9226581437", "7020908728"];
    
    for (var rawNum in testNumbers) {
      // Normalize Logic (Same as OTP Screen)
      String normalized = rawNum.replaceAll(RegExp(r'\D'), '');
      if (normalized.length > 10) {
        normalized = normalized.substring(normalized.length - 10);
      }
      
      print("DEBUG: Testing Number: $rawNum (Normalized: $normalized)");

      // Check Teacher
      final teacher = await DatabaseHelper.instance.getTeacherByMobile(normalized);
      if (teacher != null) {
        print("DEBUG:  -> FOUND as TEACHER: ${teacher['name']} (ID: ${teacher['id']})");
      } else {
        print("DEBUG:  -> Not a Teacher");
      }

      // Check Student
      final student = await DatabaseHelper.instance.getStudentByMobile(normalized);
      if (student != null) {
        print("DEBUG:  -> FOUND as STUDENT: ${student['name']}");
      } else {
        print("DEBUG:  -> Not a Student");
      }
    }
    print("DEBUG: --- END DIAGNOSTICS ---");
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your phone number")),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login-send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'mobile_number': _phoneController.text,
        }),
      );

      setState(() { _isLoading = false; });

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OtpScreen(
                mobileNumber: _phoneController.text,
                isNewUser: false, 
                userName: "Returning User", 
              ),
            ),
          );
        }
      } else if (response.statusCode == 404) {
        _showErrorSnackBar("User not found. Please sign up first.");
      } else {
        final body = json.decode(response.body);
        _showErrorSnackBar(body['detail'] ?? "Login failed.");
      }
    } catch (e) {
      // --- OFFLINE FALLBACK ---
      print("Network Error: $e. Checking Local DB...");
      
      final localUser = await DatabaseHelper.instance.getUser(_phoneController.text);
      
      setState(() { _isLoading = false; });

      if (localUser != null) {
        // User exists locally -> Allow Offline Login
        _showErrorSnackBar("Offline Mode: Logging you in...");
        
        final role = localUser['role'];
        final name = localUser['name'];
        final token = localUser['token']; // Token might be old, but okay for offline

        if (role == 'teacher') {
          await AuthService.saveTeacherData(id: "1", name: name, subject: "Science", token: token);
           Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => TeacherDashboard(
                teacherId: "1", 
                teacherName: name, 
                teacherSubject: "Science" 
              )
            ), 
            (route) => false
          );
        } else {
          await AuthService.saveStudentData(name: name, token: token);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainLayout()), 
            (route) => false
          );
        }
      } else {
        _showErrorSnackBar("No internet and user not found locally.");
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- 1. CUSTOM LOGO ---
                SizedBox(
                  height: 100,
                  width: 100,
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                ),
                const SizedBox(height: 24),

                Text(
                  'Welcome Back!', 
                  style: GoogleFonts.poppins(
                    fontSize: 28, 
                    fontWeight: FontWeight.bold, 
                    color: Theme.of(context).primaryColor
                  )
                ),
                Text(
                  'Login to continue learning', 
                  style: GoogleFonts.poppins(
                    fontSize: 14, 
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)
                  )
                ),
                
                const SizedBox(height: 40),

                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)),
                    prefixIcon: Icon(Iconsax.call, color: Theme.of(context).primaryColor),
                    filled: true, 
                    fillColor: isDark ? Theme.of(context).cardColor : const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Get OTP'),
                  ),
                ),

                const SizedBox(height: 24),

                // --- 2. FIXED SIGN UP CLICK ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ", 
                      style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6))
                    ),
                    GestureDetector(
                      onTap: () {
                        // Direct Navigation to Sign Up
                        Navigator.push(context, MaterialPageRoute(builder: (_) => SignupScreen(onLoginTap: () {  },)));
                      },
                      child: Text(
                        "Sign Up", 
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).primaryColor, 
                          fontWeight: FontWeight.bold
                        )
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}