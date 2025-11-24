import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eduthon/screens/otp_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required void Function() onLoginTap});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  final String _baseUrl = "http://192.168.1.4:8000";

  Future<void> _handleSignup() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/signup-send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'full_name': _nameController.text,
          'mobile_number': _phoneController.text,
          'role': 'student', // Default role, will be updated later
        }),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpScreen(
                mobileNumber: _phoneController.text,
                isNewUser: true,
                userName: _nameController.text,
              ),
            ),
          );
        }
      } else {
        final body = json.decode(response.body);
        _showErrorSnackBar(body['detail'] ?? "Signup failed.");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar("Could not connect to server.");
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor, 
        elevation: 0, 
        iconTheme: Theme.of(context).iconTheme
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // --- CUSTOM LOGO ---
            SizedBox(
              height: 80,
              width: 80,
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: 20),
            
            Text(
              "Create Account", 
              style: GoogleFonts.poppins(
                fontSize: 26, 
                fontWeight: FontWeight.bold, 
                color: Theme.of(context).primaryColor
              )
            ),
            
            const SizedBox(height: 30),
            
            TextField(
              controller: _nameController,
              style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)),
                prefixIcon: Icon(Iconsax.user, color: Theme.of(context).primaryColor),
                filled: true, 
                fillColor: isDark ? Theme.of(context).cardColor : const Color(0xFFF8F9FA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
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
            
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _handleSignup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : Text('Verify & Continue', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}