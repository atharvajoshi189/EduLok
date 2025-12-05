import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// SERVICES
import 'package:eduthon/services/auth_service.dart';
import 'package:eduthon/services/database_helper.dart';
import 'package:eduthon/services/language_service.dart';

// SCREENS
import 'package:eduthon/screens/dashboard_screen.dart';
import 'package:eduthon/screens/quiz_list_screen.dart';
import 'package:eduthon/screens/mentor_screen.dart';
import 'package:eduthon/screens/ai_hub_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  String _userClass = "Class 10"; 

  // --- MENTOR STATE ---
  List<dynamic> _myMentors = [];
  List<dynamic> _sentRequests = [];
  
  @override
  void initState() {
    super.initState();
    _loadUserClass();
    _fetchMentorData();
  }

  Future<void> _loadUserClass() async {
    final savedClass = await AuthService.getClass();
    if (savedClass != null) {
      setState(() {
        _userClass = savedClass;
      });
    }
  }

  Future<void> _fetchMentorData() async {
    try {
      final token = await AuthService.getAuthToken();
      if (token != null) {
        final responseMentors = await http.get(
          Uri.parse('http://192.168.1.4:8000/mentorship/mentors'),
          headers: {'Authorization': 'Bearer $token'},
        );
        final responseRequests = await http.get(
          Uri.parse('http://192.168.1.4:8000/mentorship/requests/sent'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (responseMentors.statusCode == 200) {
          final List<dynamic> data = json.decode(responseMentors.body);
          await DatabaseHelper.instance.saveMyMentors(data);
          setState(() => _myMentors = data);
        }
        if (responseRequests.statusCode == 200) {
          setState(() => _sentRequests = json.decode(responseRequests.body));
        }
      }
    } catch (e) {
      print("Network Error: $e");
    }

    // Offline Fallback
    final localMentors = await DatabaseHelper.instance.getMyMentors();
    if (mounted && _myMentors.isEmpty) {
      setState(() => _myMentors = localMentors);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool hasActiveMentor = _myMentors.isNotEmpty;

    final List<Widget> widgetOptions = <Widget>[
      // 0. Dashboard
      DashboardScreen(
        onClassChanged: (newClass) {
          setState(() {
            _userClass = newClass;
          });
        },
      ),
      
      // 1. Quizzes
      QuizListScreen(className: _userClass), 
      
      // 2. Mentor Tab
      MentorScreen(
        myMentors: _myMentors, 
        sentRequests: _sentRequests, 
        onRefresh: _fetchMentorData
      ), 
      
      // 3. AI Hub
      const AIHubScreen(),
    ];

    return Scaffold(
      body: widgetOptions.elementAt(_selectedIndex),
      
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Iconsax.home_2),
            activeIcon: const Icon(Iconsax.home_25),
            label: AppLocalizations.of(context)?.translate('study') ?? 'Study',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Iconsax.task_square),
            activeIcon: const Icon(Iconsax.task_square5),
            label: AppLocalizations.of(context)?.translate('quizzes') ?? 'Quizzes',
          ),
          BottomNavigationBarItem(
            icon: hasActiveMentor 
                ? const Icon(Iconsax.teacher) 
                : const Icon(Iconsax.lock), 
            activeIcon: hasActiveMentor 
                ? const Icon(Iconsax.teacher5) 
                : const Icon(Iconsax.lock_1),
            label: AppLocalizations.of(context)?.translate('mentor') ?? 'Mentor',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Iconsax.magic_star),
            activeIcon: const Icon(Iconsax.magic_star5),
            label: "AI",
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Theme.of(context).iconTheme.color?.withOpacity(0.6),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 10,
      ),
    );
  }
}