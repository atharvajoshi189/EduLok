import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

// --- SCREEN IMPORTS ---
import 'package:eduthon/screens/dashboard_screen.dart';
import 'package:eduthon/screens/quiz_list_screen.dart';
import 'package:eduthon/screens/mentor_screen.dart'; // Mentor Screen (Lock/Unlock logic isme hai)

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  final String _userClass = "Class 10"; 

  // --- MENTOR STATE (App-wide State) ---
  Map<String, dynamic>? _selectedMentor;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Dashboard se Mentor update hoga to yahan state change hogi
  void _updateMentor(Map<String, dynamic>? newMentor) {
    setState(() {
      _selectedMentor = newMentor;
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- LIST OF SCREENS ---
    final List<Widget> widgetOptions = <Widget>[
      // 1. Dashboard (Pass State & Updater)
      DashboardScreen(
        selectedMentor: _selectedMentor,
        onMentorChanged: _updateMentor,
      ),
      
      // 2. Quizzes
      QuizListScreen(className: _userClass), 
      
      // 3. My Mentor Tab (Bottom Nav wala)
      // Ye automatically check karega ki _selectedMentor null hai ya nahi
      // Null hua to Lock dikhayega, Data hua to Dashboard dikhayega.
      MentorScreen(currentMentor: _selectedMentor), 
      
      // 4. Profile
      const Center(child: Text('Profile Settings Coming Soon')),
    ];

    return Scaffold(
      body: widgetOptions.elementAt(_selectedIndex),
      
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          // Tab 0
          BottomNavigationBarItem(
            icon: Icon(Iconsax.home_2),
            activeIcon: Icon(Iconsax.home_25),
            label: 'Study',
          ),
          
          // Tab 1
          BottomNavigationBarItem(
            icon: Icon(Iconsax.task_square),
            activeIcon: Icon(Iconsax.task_square5),
            label: 'Quizzes',
          ),
          
          // Tab 2: MENTOR SECTION (Yahan chahiye tha aapko)
          BottomNavigationBarItem(
            icon: Icon(Iconsax.teacher),
            activeIcon: Icon(Iconsax.teacher5),
            label: 'My Mentor',
          ),
          
          // Tab 3
          BottomNavigationBarItem(
            icon: Icon(Iconsax.user),
            activeIcon: Icon(Iconsax.user5),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF2554A3),
        unselectedItemColor: Colors.grey.shade600,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
      ),
    );
  }
}