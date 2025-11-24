import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:eduthon/screens/onboarding_screen.dart';
import 'package:eduthon/screens/teacher/teacher_registration_screen.dart';
import 'package:eduthon/services/auth_service.dart';
import 'package:eduthon/services/database_helper.dart';

class RoleSelectionScreen extends StatefulWidget {
  final String userName;
  final String mobileNumber;
  final String accessToken;

  const RoleSelectionScreen({
    super.key,
    required this.userName,
    required this.mobileNumber,
    required this.accessToken,
  });

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _isLoading = false;
  final String _baseUrl = "http://192.168.1.4:8000";

  Future<void> _handleRoleSelection(String role) async {
    setState(() => _isLoading = true);

    try {
      // 1. Update Role in Backend
      final response = await http.put(
        Uri.parse('$_baseUrl/users/update-role'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.accessToken}',
        },
        body: json.encode({
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        // 2. Save Data Locally & Navigate
        if (role == 'student') {
          await AuthService.saveStudentData(name: widget.userName, token: widget.accessToken);
          await DatabaseHelper.instance.saveUser(widget.mobileNumber, widget.userName, role, widget.accessToken);
          
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => OnboardingScreen(selectedLanguage: "English"),
              ),
            );
          }
        } else {
          // Teacher Flow
          // Note: TeacherRegistrationScreen will save teacher data
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const TeacherRegistrationScreen(),
              ),
            );
          }
        }
      } else {
        final body = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(body['detail'] ?? "Failed to update role."), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not connect to server."), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text('Select your role', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(
              'Please tell us who you are to continue.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
            ),
            const SizedBox(height: 40),

            // --- STUDENT CARD ---
            _buildRoleCard(
              context: context,
              icon: Icons.school_rounded,
              title: 'I am a Student',
              subtitle: 'Start learning & solving doubts',
              onTap: () => _handleRoleSelection('student'),
            ),
            
            const SizedBox(height: 24),

            // --- TEACHER CARD ---
            _buildRoleCard(
              context: context,
              icon: Icons.person_search_rounded,
              title: 'I am a Teacher',
              subtitle: 'Mentor students & solve doubts',
              onTap: () => _handleRoleSelection('teacher'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget for Cards
  Widget _buildRoleCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}