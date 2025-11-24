import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eduthon/screens/login_screen.dart';
import 'package:eduthon/services/auth_service.dart';
import 'package:eduthon/screens/dashboard_screen.dart';
import 'package:eduthon/screens/main_layout.dart';
import 'package:eduthon/screens/teacher/teacher_dashboard.dart';
import 'package:eduthon/services/sync_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // 1. Initialize Auth Service (Load Data from SharedPrefs)
    await AuthService.init();
    
    // 1.1 Sync Offline Actions
    SyncService().syncPendingActions();

    // 2. Artificial Delay (Logo dikhane ke liye)
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    // 3. Check Login Status
    if (AuthService.authToken != null) {
      // User is Logged In
      final role = await AuthService.getRole();
      
      if (role == 'teacher') {
        // Load Teacher Data
        final id = await AuthService.getId();
        final name = await AuthService.getName();
        final subject = await AuthService.getSubject();
        
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(
            builder: (_) => TeacherDashboard(
              teacherId: id ?? "Unknown", 
              teacherName: name ?? "Teacher", 
              teacherSubject: subject ?? "General"
            )
          )
        );
      } else {
        // Student -> Main Layout (Dashboard + Nav)
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainLayout()));
      }
    } else {
      // Not Logged In -> Login Screen
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen(onSignupTap: () {})));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ Pure White Background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- Logo Section ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2554A3).withOpacity(0.1), // Light Blue Circle
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.book_1, // EduLok Icon
                size: 60,
                color: Color(0xFF2554A3), // EduLok Blue
              ),
            ),
            const SizedBox(height: 20),
            
            // --- Brand Name ---
            Text(
              "EduLok",
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2554A3),
              ),
            ),
            Text(
              "Your Offline AI Mentor",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            
            const SizedBox(height: 50),
            
            // --- Loader ---
            const CircularProgressIndicator(
              color: Color(0xFF2554A3),
            ),
          ],
        ),
      ),
    );
  }
}