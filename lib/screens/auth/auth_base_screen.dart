import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Ensure imports match your folder structure
import 'package:eduthon/screens/login_screen.dart'; 
import 'package:eduthon/screens/auth/signup_screen.dart'; // Check if this path is correct in your folders
import 'package:eduthon/theme/app_colors.dart'; // Ensure this file exists
import 'package:eduthon/widgets/galaxy_background.dart'; // Ensure this file exists

class AuthBaseScreen extends StatefulWidget {
  const AuthBaseScreen({super.key});

  @override
  State<AuthBaseScreen> createState() => _AuthBaseScreenState();
}

class _AuthBaseScreenState extends State<AuthBaseScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0; // 0 for Login, 1 for Signup

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.page != null) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Swipe karne ke liye helper function
  void _goToPage(int page) {
    _pageController.animateToPage(
      page, 
      duration: const Duration(milliseconds: 400), 
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ResizeToAvoidBottomInset false rakhne se keyboard aane par UI bigadta nahi hai
      resizeToAvoidBottomInset: false, 
      body: GalaxyBackground( 
        child: Stack(
          children: [
            // --- Top Logo (Hero Animation Target) ---
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Hero(
                  tag: 'edulokLogo', // Splash screen se yahan aata hai
                  child: Image.asset(
                    'assets/images/logo.png', // Logo image path check karein
                    height: 80, 
                  ),
                ),
              ),
            ),
            
            // --- Tagline ---
            Positioned(
              top: 150,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Your Offline AI Mentor',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),

            // --- Login/Signup Forms (Page View) ---
            Positioned.fill(
              top: 180, // Forms logo ke neeche shuru honge
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  // Page 0: Login - onSignupTap par Page 1 par jaata hai
                  LoginScreen(onSignupTap: () => _goToPage(1)), 
                  
                  // Page 1: Signup - onLoginTap par Page 0 par jaata hai
                  SignupScreen(onLoginTap: () => _goToPage(0)), 
                ],
              ),
            ),

            // --- Tab Indicators (Bottom Dots) ---
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTabIndicator(0),
                  const SizedBox(width: 8),
                  _buildTabIndicator(1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? const Color(0xFF009688) : Colors.white.withOpacity(0.5), // AppColors.teal ki jagah direct color safe side ke liye
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}