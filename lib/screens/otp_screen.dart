import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

// --- SCREENS IMPORTS ---
import 'package:eduthon/screens/role_selection_screen.dart';
import 'package:eduthon/screens/main_layout.dart'; // Student Dashboard
import 'package:eduthon/screens/teacher/teacher_dashboard.dart'; // Teacher Dashboard

// --- SERVICES IMPORTS ---
import 'package:eduthon/services/auth_service.dart';
import 'package:eduthon/services/database_helper.dart';
import 'package:eduthon/screens/role_selection_screen.dart'; // Import RoleSelectionScreen
import 'package:http/http.dart' as http;
import 'dart:convert';

class OtpScreen extends StatefulWidget {
  final String mobileNumber;
  final bool isNewUser;
  final String userName;

  const OtpScreen({
    super.key,
    required this.mobileNumber,
    required this.isNewUser,
    required this.userName,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;

  // --- MAIN VERIFICATION LOGIC ---
  Future<void> _handleVerifyOTP(String pin) async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.4:8000/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'mobile_number': widget.mobileNumber,
          'otp': pin,
        }),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String role = data['role'];
        final String accessToken = data['access_token'];
        final String name = data['full_name'] ?? "User";

        // Save Token & Role (You might want to use SharedPreferences here for persistence)
        // await AuthService.saveToken(accessToken); 

        if (!mounted) return;

        // --- NEW FLOW: IF NEW USER -> GO TO ROLE SELECTION ---
        if (widget.isNewUser) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => RoleSelectionScreen(
                userName: name,
                mobileNumber: widget.mobileNumber,
                accessToken: accessToken, // Pass Token
              ),
            ),
          );
          return;
        }

        // --- EXISTING FLOW (LOGIN) ---
        if (role == "teacher") {
          // Fetch Teacher ID if needed or pass from response if available
          // For now, we might need to fetch user details or assume ID is handled
          // Ideally, the verify-otp response should include the user ID.
          // Let's assume we can get it or just navigate.
          // Since the previous code used AuthService to save teacher data, let's try to keep it consistent if possible,
          // but for now, direct navigation based on role is the priority.
          
           await AuthService.saveTeacherData(
            id: "1", // Placeholder, ideally get from backend response
            name: name, 
            subject: "Science", // Placeholder
            token: accessToken
          );
          
          // --- SYNC TO LOCAL DB ---
          await DatabaseHelper.instance.saveUser(widget.mobileNumber, name, role, accessToken);

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => TeacherDashboard(
                teacherId: "1", // Placeholder, ideally get from backend response
                teacherName: name, 
                teacherSubject: "Science" // Placeholder
              )
            ), 
            (route) => false
          );
        } else if (role == "student") {
          await AuthService.saveStudentData(name: name, token: accessToken);
          
          // --- SYNC TO LOCAL DB ---
          await DatabaseHelper.instance.saveUser(widget.mobileNumber, name, role, accessToken);

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainLayout()), 
            (route) => false
          );
        } else {
           _showErrorSnackBar("Unknown role: $role");
        }

      } else {
        final body = json.decode(response.body);
        _showErrorSnackBar(body['detail'] ?? "Verification failed.");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar("Connection error: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()), 
        backgroundColor: Colors.red.shade700
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultPinTheme = PinTheme(
      width: 56, height: 60,
      textStyle: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: Theme.of(context).primaryColor, width: 2),
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text('Verify your number', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(
              'Enter the 6-digit code sent to',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6), 
                fontSize: 16
              ),
            ),
            Text(
              widget.mobileNumber, 
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold, 
                fontSize: 16
              )
            ),
            const SizedBox(height: 40),
            
            // --- PIN PUT ---
            Pinput(
              controller: _pinController,
              length: 6,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: focusedPinTheme,
              onCompleted: (pin) {
                if (pin == '123456') {
                   _handleVerifyOTP(pin);
                } else {
                   _showErrorSnackBar("Invalid OTP. (Hint: 123456)");
                }
              },
            ),
            
            const SizedBox(height: 40),
            
            // --- VERIFY BUTTON ---
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () {
                  final pin = _pinController.text;
                  if (pin.length == 6) {
                     // Hardcoded check for demo
                     if(pin == '123456') { 
                        _handleVerifyOTP(pin); 
                     } else {
                        _showErrorSnackBar("Invalid OTP. (Hint: 123456)");
                     }
                  } else {
                    _showErrorSnackBar("Please enter a valid 6-digit OTP.");
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
                  : const Text('VERIFY & CONTINUE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive code? ", 
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6), 
                    fontSize: 15
                  )
                ),
                InkWell(
                  onTap: () {
                    _showErrorSnackBar("Resend feature coming soon!");
                  },
                  child: Text(
                    'Resend OTP', 
                    style: TextStyle(
                      color: Theme.of(context).primaryColor, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 15
                    )
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}