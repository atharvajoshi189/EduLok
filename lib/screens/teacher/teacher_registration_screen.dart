import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eduthon/services/auth_service.dart';
import 'package:eduthon/services/database_helper.dart';
import 'package:eduthon/screens/teacher/teacher_dashboard.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TeacherRegistrationScreen extends StatefulWidget {
  const TeacherRegistrationScreen({super.key});

  @override
  State<TeacherRegistrationScreen> createState() => _TeacherRegistrationScreenState();
}

class _TeacherRegistrationScreenState extends State<TeacherRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  final String _baseUrl = "http://192.168.1.4:8000";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMobile();
  }

  Future<void> _loadMobile() async {
    String? mobile = await AuthService.getTempMobile();
    if (mobile != null && mobile.isNotEmpty) {
      setState(() {
        _mobileController.text = mobile;
      });
    }
  }

  Future<void> _registerTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final subject = _subjectController.text.trim();
    final experience = _experienceController.text.trim();
    final mobile = _mobileController.text.trim();

    try {
      // 1. Save Locally (Offline First)
      final token = await AuthService.getAuthToken();
      
      // Save to AuthService for session
      await AuthService.saveTeacherData(
        id: "TEMP_ID", 
        name: name, 
        subject: subject, 
        token: token ?? "OFFLINE_TOKEN"
      );
      
      // Save to DatabaseHelper for offline login
      await DatabaseHelper.instance.saveUser(mobile, name, 'teacher', token ?? "OFFLINE_TOKEN");

      // FIX: Add to local 'teachers' table so it appears in Find Mentor immediately (on this device)
      await DatabaseHelper.instance.saveTeachers([{
        'id': "TEMP_${DateTime.now().millisecondsSinceEpoch}", // Temp ID until synced
        'full_name': name,
        'subject': subject,
        'experience': experience,
        'rating': 0.0,
        'mobile_number': mobile
      }]);

      // 2. Sync with Backend (if online)
      if (token != null) {
        try {
          final response = await http.put(
            Uri.parse('$_baseUrl/teachers/update-profile'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'full_name': name,
              'subject': subject,
              'experience': experience,
            }),
          );

          if (response.statusCode == 200) {
            print("Teacher profile synced with backend.");
          } else {
            print("Failed to sync profile: ${response.body}");
          }
        } catch (e) {
          print("Offline or API error: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Offline: Profile saved locally.")),
            );
          }
        }
      }

      // 3. Navigate to Dashboard
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => TeacherDashboard(
              teacherId: "TEMP_ID", // This will be updated on next login/sync
              teacherName: name,
              teacherSubject: subject,
            ),
          ),
          (route) => false,
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Teacher Profile", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Let's set up your profile", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Please ensure your mobile number is correct.", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 30),

              Text("Registered Mobile Number", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                readOnly: true, // Should be read-only as it comes from OTP
                decoration: InputDecoration(
                  hintText: "Enter Mobile Number",
                  prefixIcon: const Icon(Iconsax.call, color: Colors.orange),
                  filled: true, fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              
              const SizedBox(height: 20),
              _buildTextField(controller: _nameController, label: "Full Name", icon: Iconsax.user, hint: "e.g. Rahul Sharma"),
              const SizedBox(height: 20),
              _buildTextField(controller: _educationController, label: "Education", icon: Iconsax.teacher, hint: "e.g. M.Sc. Physics"),
              const SizedBox(height: 20),
              _buildTextField(controller: _subjectController, label: "Primary Subject", icon: Iconsax.book, hint: "e.g. Mathematics"),
              const SizedBox(height: 20),
              _buildTextField(controller: _experienceController, label: "Experience (Years)", icon: Iconsax.timer_1, hint: "e.g. 5", isNumber: true),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _isLoading ? null : _registerTeacher,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("Register & Continue", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, required String hint, bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          validator: (value) => (value == null || value.isEmpty) ? "Required" : null,
          decoration: InputDecoration(
            hintText: hint, prefixIcon: Icon(icon, color: Colors.orange), filled: true, fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
        ),
      ],
    );
  }
}