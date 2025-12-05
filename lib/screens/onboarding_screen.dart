import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // JSON decode ke liye zaroori hai

import 'package:eduthon/services/auth_service.dart'; // Ensure correct path
import 'package:eduthon/services/database_helper.dart';
import 'package:eduthon/screens/main_layout.dart';

class OnboardingScreen extends StatefulWidget {
  final String selectedLanguage;

  const OnboardingScreen({
    super.key,
    required this.selectedLanguage,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? _selectedBoard;
  String? _selectedClass;
  final Set<String> _selectedSubjects = {};
  bool _isLoading = false;
  
  // Ensure this URL is correct for your emulator/device
  final String _baseUrl = "http://192.168.1.4:8000"; 

  // --- API CALL: Onboarding Complete ---
  Future<void> _handleOnboardingComplete() async {
    if (_selectedBoard == null || _selectedClass == null || _selectedSubjects.isEmpty) {
      _showErrorSnackBar("Please select your board, class, and at least one subject.");
      return;
    }
    
    setState(() { _isLoading = true; });

    // Token Fetch from AuthService
    // Note: Agar AuthService.authToken null hai, toh hum SharedPreferences se check kar sakte hain
    // Lekin ideally login ke waqt set ho jana chahiye tha.
    String? token = AuthService.authToken;
    
    // Fallback: Agar static variable null hai (app restart hua ho), toh SharedPreferences se lo
    /* if (token == null) {
       final prefs = await SharedPreferences.getInstance();
       token = prefs.getString('auth_token');
    }
    */

    if (token == null) {
      _showErrorSnackBar("Session expired. Please login again.");
      setState(() { _isLoading = false; });
      // TODO: Redirect to Login Screen here if needed
      return;
    }

    try {
      // Data jo hum bhejne wale hain
      final Map<String, dynamic> requestBody = {
        "board": _selectedBoard,
        "grade": _selectedClass,
        "subjects": _selectedSubjects.toList(),
        "language": widget.selectedLanguage
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/users/complete-onboarding'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      setState(() { _isLoading = false; });

      if (response.statusCode == 200) {
        // Success! Backend updated user status.
        
        // --- FIX: Save Student to Local DB for Persistence ---
        final rawMobile = await AuthService.getTempMobile();
        final name = AuthService.userName ?? "Student";
        
        if (rawMobile != null) {
          // Normalize here too!
          String normalizedMobile = rawMobile.replaceAll(RegExp(r'\D'), '');
          if (normalizedMobile.length > 10) {
            normalizedMobile = normalizedMobile.substring(normalizedMobile.length - 10);
          }

          await DatabaseHelper.instance.registerStudent(normalizedMobile, name);
          print("DEBUG: Student Registered Locally: $normalizedMobile - $name");
        }

        // Update Session Data
        await AuthService.saveUserData(
            token: token, 
            name: name, 
            onboarded: true
        );
        
        // Save Class Persistence
        if (_selectedClass != null) {
          await AuthService.saveClass("Class $_selectedClass");
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainLayout()),
          );
        }
      } else {
        print("API Error: ${response.body}");
        _showErrorSnackBar("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Network Error: $e");
      setState(() { _isLoading = false; });
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

  // --- Dummy Data ---
  final List<Map<String, dynamic>> boards = [
    {'id': 'CBSE', 'title': 'CBSE', 'icon': Icons.school_outlined},
    {'id': 'ICSE', 'title': 'ICSE', 'icon': Icons.book_outlined},
    {'id': 'MH', 'title': 'Maharashtra Board', 'icon': Icons.location_city_outlined},
  ];
  final List<String> classes = ['6', '7', '8', '9', '10', '11', '12'];
  final List<Map<String, dynamic>> subjects = [
    {'id': 'MATHS', 'title': 'Maths', 'icon': Icons.calculate_outlined},
    {'id': 'SCIENCE', 'title': 'Science', 'icon': Icons.science_outlined},
    {'id': 'PHYSICS', 'title': 'Physics', 'icon': Icons.lightbulb_outline},
    {'id': 'CHEMISTRY', 'title': 'Chemistry', 'icon': Icons.science},
    {'id': 'BIOLOGY', 'title': 'Biology', 'icon': Icons.biotech},
    {'id': 'ENGLISH', 'title': 'English', 'icon': Icons.language},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildSection(
                  title: '1. Select Your Board',
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5, // Adjusted aspect ratio for better look
                    children: boards.map((board) {
                      return _buildBoardCard(
                        title: board['title'],
                        icon: board['icon'],
                        id: board['id'],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: '2. Choose Your Class',
                  child: Wrap(
                    spacing: 12.0,
                    runSpacing: 12.0,
                    children: classes.map((classNum) {
                      return _buildClassChip(classNum);
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: '3. Pick Your Subjects',
                  child: GridView.count(
                    crossAxisCount: 3, // 4 was too cramped, changed to 3
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                    children: subjects.map((subject) {
                      return _buildSubjectCard(
                        title: subject['title'],
                        icon: subject['icon'],
                        id: subject['id'],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 32),
                _buildStartButton(),
                const SizedBox(height: 16),
                _buildFooterText(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    final bool isEnabled = _selectedBoard != null &&
                           _selectedClass != null &&
                           _selectedSubjects.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: (isEnabled && !_isLoading) ? _handleOnboardingComplete : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: isEnabled ? 4 : 0,
        ),
        child: _isLoading
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
            : Text(
                "Let's Start Learning",
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildHeader() { 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Let's Personalize\nYour Journey",
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Language: ${widget.selectedLanguage}',
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required Widget child}) { 
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildBoardCard({ required String title, required IconData icon, required String id, }) { 
    final bool isSelected = _selectedBoard == id;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedBoard = id;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
            width: 2.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade600, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassChip(String classNum) { 
    final bool isSelected = _selectedClass == classNum;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedClass = classNum;
        });
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
          border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
        ),
        alignment: Alignment.center,
        child: Text(
          classNum,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectCard({ required String title, required IconData icon, required String id, }) { 
    final bool isSelected = _selectedSubjects.contains(id);
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedSubjects.remove(id);
          } else {
            _selectedSubjects.add(id);
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade600, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterText() { 
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Text(
          'All content is pre-installed. This setup helps us customize your offline experience.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}