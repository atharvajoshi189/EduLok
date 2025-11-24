import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eduthon/screens/splash_screen.dart';
import 'package:eduthon/services/ai_service.dart';
import 'package:eduthon/screens/theme/theme_manager.dart'; // Theme Manager Import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AIService().init();
  runApp(const EduLokApp());
}

class EduLokApp extends StatelessWidget {
  const EduLokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeManager(), // Theme change sunne ke liye
      builder: (context, child) {
        return MaterialApp(
          title: 'EduLok',
          debugShowCheckedModeBanner: false,
          
          // --- 1. CURRENT MODE ---
          themeMode: ThemeManager().themeMode,

          // --- 2. LIGHT THEME (Day Mode) ---
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Light Grey
            cardColor: Colors.white, // Cards White honge
            primaryColor: const Color(0xFF2554A3),
            
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2554A3),
              brightness: Brightness.light,
            ),
            
            // Text Theme
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
            
            // AppBar Theme
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87, // Icons black honge
              elevation: 0,
            ),
            
            // Drawer Theme
            drawerTheme: const DrawerThemeData(
              backgroundColor: Colors.white,
            ),
          ),

          // --- 3. DARK THEME (Premium Night Mode) 🔥 ---
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212), // Matte Black (Not Pitch Black)
            cardColor: const Color(0xFF1E1E1E), // Dark Cards
            primaryColor: const Color(0xFF458FEA), // Thoda Bright Blue
            
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2554A3),
              brightness: Brightness.dark,
              primary: const Color(0xFF458FEA), // Dark mode mein primary color
              surface: const Color(0xFF1E1E1E), // Cards ka color
            ),

            // Text Theme (White Text)
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
              bodyColor: const Color(0xFFE0E0E0), // Off-White text (aankhon ko shubh)
              displayColor: Colors.white,
            ),

            // AppBar Theme
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121212),
              foregroundColor: Colors.white, // Icons white honge
              elevation: 0,
            ),

            // Drawer Theme
            drawerTheme: const DrawerThemeData(
              backgroundColor: Color(0xFF1E1E1E), // Drawer bhi dark grey hoga
            ),
            
            // Icon Theme
            iconTheme: const IconThemeData(color: Colors.white70),
          ),

          // Start Screen
          home: const SplashScreen(),
        );
      },
    );
  }
}