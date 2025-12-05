import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eduthon/screens/splash_screen.dart';
import 'package:eduthon/services/ai_service.dart';
import 'package:eduthon/services/theme_manager.dart';
import 'package:eduthon/services/data_manager.dart';
import 'package:eduthon/services/language_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AIService().init();
  await DataManager.loadSyllabus(); // Load AI Syllabus
  runApp(const EduLokApp());
}

class EduLokApp extends StatelessWidget {
  const EduLokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ThemeManager(), LanguageService()]),
      builder: (context, child) {
        return MaterialApp(
          title: 'EduLok',
          debugShowCheckedModeBanner: false,
          locale: LanguageService().currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('hi'),
            Locale('mr'),
            Locale('ta'),
            Locale('gu'),
            Locale('bn'),
            Locale('te'),
          ],
          themeMode: ThemeManager().themeMode,
          
          // Light Theme
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
            cardColor: Colors.white,
            primaryColor: const Color(0xFF2554A3),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2554A3),
              brightness: Brightness.light,
            ),
            textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 0,
            ),
          ),

          // Dark Theme
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            primaryColor: const Color(0xFF458FEA),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2554A3),
              brightness: Brightness.dark,
              primary: const Color(0xFF458FEA),
              surface: const Color(0xFF1E1E1E),
              onSurface: Colors.white,
              onPrimary: Colors.white,
            ),
            textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
              bodyColor: const Color(0xFFE0E0E0),
              displayColor: Colors.white,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121212),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            iconTheme: const IconThemeData(
              color: Colors.white70,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF2C2C2C),
              labelStyle: TextStyle(color: Colors.grey.shade400),
              hintStyle: TextStyle(color: Colors.grey.shade600),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          home: const SplashScreen(),
        );
      },
    );
  }
}