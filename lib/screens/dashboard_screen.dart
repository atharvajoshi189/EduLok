import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- SERVICE IMPORTS ---
import 'package:eduthon/services/auth_service.dart';
import 'package:eduthon/services/syllabus_service.dart';
import 'package:eduthon/services/database_helper.dart';

// --- SCREEN IMPORTS ---
import 'package:eduthon/screens/ai_solver_screen.dart'; // Purple card ke liye
import 'package:eduthon/screens/find_mentor_screen.dart'; // Yellow card ke liye
import 'package:eduthon/screens/subject_details_screen.dart';
import 'package:eduthon/screens/login_screen.dart';
import 'package:eduthon/screens/theme/theme_manager.dart';
import 'package:eduthon/screens/mentor_resources_screen.dart';

class DashboardScreen extends StatefulWidget {
  // Data MainLayout se aa raha hai
  final Map<String, dynamic>? selectedMentor;
  final Function(Map<String, dynamic>?)? onMentorChanged;

  const DashboardScreen({
    super.key, 
    this.selectedMentor, 
    this.onMentorChanged
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // --- CONNECTIVITY STATE ---
  String _connectionStatus = "Checking...";
  Color _statusColor = Colors.grey;
  IconData _statusIcon = Iconsax.wifi;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  // --- USER DATA ---
  String userName = "Student";
  String userClass = "Class 10"; 
  String userBoard = "CBSE";
  int streakDays = 12;
  double lastChapterProgress = 0.65;

  // --- DYNAMIC CONTENT ---
  List<Map<String, dynamic>> _dynamicSubjects = [];
  List<dynamic> _myMentors = []; // Store fetched mentors
  List<dynamic> _sentRequests = []; // Store sent requests
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initSystem();
    _initConnectivity();
    _loadMentors(); // Fetch mentors on init
  }

  Future<void> _loadMentors() async {
    // 1. Try Fetching from API (Online First)
    try {
      final token = await AuthService.getAuthToken();
      if (token != null) {
        // Fetch Approved Mentors
        final responseMentors = await http.get(
          Uri.parse('http://192.168.1.4:8000/mentorship/mentors'),
          headers: {'Authorization': 'Bearer $token'},
        );

        // Fetch Sent Requests
        final responseRequests = await http.get(
          Uri.parse('http://192.168.1.4:8000/mentorship/requests/sent'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (responseMentors.statusCode == 200) {
          final List<dynamic> data = json.decode(responseMentors.body);
          await DatabaseHelper.instance.saveMyMentors(data);
        }

        if (responseRequests.statusCode == 200) {
          if (mounted) {
            setState(() {
              _sentRequests = json.decode(responseRequests.body);
            });
          }
        }
      }
    } catch (e) {
      print("Error loading mentors from API: $e");
    }

    // 3. Load from Local DB (Always source of truth for UI)
    final localMentors = await DatabaseHelper.instance.getMyMentors();
    
    if (mounted) {
      setState(() {
        _myMentors = localMentors;
      });
    }
  }

  Future<void> _withdrawRequest(int requestId) async {
    try {
      final token = await AuthService.getAuthToken();
      if (token != null) {
        final response = await http.delete(
          Uri.parse('http://192.168.1.4:8000/mentorship/requests/$requestId'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 204) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Request withdrawn successfully")),
          );
          _loadMentors(); // Refresh list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to withdraw request")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _initSystem() async {
    await SyllabusService().init(); 
    _loadUserData();
  }

  void _loadUserData() {
    setState(() {
      userName = AuthService.userName ?? "Student";
      _refreshSubjects(); 
    });
  }

  void _refreshSubjects() {
    setState(() {
      _dynamicSubjects = SyllabusService().getSubjectsForClass(userClass);
      _isLoading = false;
    });
  }

  void _initConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      _updateConnectionStatus(results.first);
    });
    Connectivity().checkConnectivity().then((results) {
      _updateConnectionStatus(results.first);
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    if (mounted) {
      setState(() {
        if (result == ConnectivityResult.none) {
          _connectionStatus = "Offline Mode";
          _statusColor = Colors.green.shade600;
          _statusIcon = Iconsax.flash_circle;
        } else {
          _connectionStatus = "Cloud Sync";
          _statusColor = const Color(0xFF2554A3);
          _statusIcon = Iconsax.cloud_connection;
        }
      });
    }
  }

  void _handleLogout() {
    AuthService.clearUserData();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen(onSignupTap: () {})),
      (route) => false,
    );
  }

  void _showSelectionDialog(String title, List<String> options, Function(String) onSelected) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Change $title", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (ctx, i) => ListTile(
              title: Text(options[i], style: GoogleFonts.poppins()),
              onTap: () {
                onSelected(options[i]);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("$title updated to ${options[i]}"))
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      
      // --- APP BAR ---
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _statusColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(_statusIcon, color: _statusColor, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    _connectionStatus, 
                    style: GoogleFonts.poppins(color: _statusColor, fontSize: 12, fontWeight: FontWeight.w600)
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
           IconButton(
             icon: Icon(Iconsax.notification, color: Theme.of(context).iconTheme.color), 
             onPressed: () {}
           ),
           Padding(
             padding: const EdgeInsets.only(right: 16.0),
             child: InkWell(
               onTap: () => Scaffold.of(context).openDrawer(),
               child: CircleAvatar(
                 radius: 18,
                 backgroundColor: Colors.grey.shade200,
                 child: const Icon(Iconsax.user, color: Colors.black, size: 20),
               ),
             ),
           )
        ],
      ),

      // --- DRAWER ---
      drawer: Drawer(
        backgroundColor: Theme.of(context).drawerTheme.backgroundColor,
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF2554A3)),
              accountName: Text(userName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
              accountEmail: Text("$userBoard | $userClass", style: GoogleFonts.poppins(color: Colors.white70)),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white, 
                child: Icon(Iconsax.user, color: Color(0xFF2554A3), size: 30)
              ),
            ),
            
            // Class Change
            ListTile(
              leading: const Icon(Iconsax.book_1),
              title: Text("Change Class", style: GoogleFonts.poppins()),
              trailing: Text(userClass, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              onTap: () {
                Navigator.pop(context);
                _showSelectionDialog("Class", 
                  ["Class 6", "Class 7", "Class 8", "Class 9", "Class 10", "Class 11", "Class 12"], 
                  (val) {
                    setState(() {
                      userClass = val;
                      _refreshSubjects(); 
                    });
                  }
                );
              },
            ),
            
            // Board Change
            ListTile(
              leading: const Icon(Iconsax.bank),
              title: Text("Change Board", style: GoogleFonts.poppins()),
              trailing: Text(userBoard, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              onTap: () {
                Navigator.pop(context);
                _showSelectionDialog("Board", ["CBSE", "ICSE", "State Board"], (val) => setState(() => userBoard = val));
              },
            ),

            const Divider(),

            // Dark Mode
            AnimatedBuilder(
              animation: ThemeManager(),
              builder: (context, _) {
                return SwitchListTile(
                  title: Text("Dark Mode", style: GoogleFonts.poppins()),
                  secondary: Icon(
                    ThemeManager().isDarkMode ? Iconsax.moon5 : Iconsax.sun_1, 
                    color: ThemeManager().isDarkMode ? Colors.white : Colors.orange
                  ),
                  value: ThemeManager().isDarkMode,
                  onChanged: (val) => ThemeManager().toggleTheme(val),
                  activeThumbColor: const Color(0xFF458FEA),
                );
              },
            ),

            ListTile(
              leading: const Icon(Iconsax.logout, color: Colors.red),
              title: Text("Logout", style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: _handleLogout,
            ),
          ],
        ),
      ),

      // --- BODY ---
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // 1. Header & Streak
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hi, $userName! 👋", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text("Let's learn today!", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.orange.shade300, Colors.deepOrange]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 8, offset: const Offset(0,4))]
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.flash, color: Colors.white, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          "$streakDays Day Streak", 
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
                        ),
                      ],
                    ),
                  )
                ],
              ),

              const SizedBox(height: 24),

              // 2. Continue Learning Card
              Text("Continue Learning", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2554A3), Color(0xFF458FEA)], 
                    begin: Alignment.topLeft, 
                    end: Alignment.bottomRight
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF2554A3).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2), 
                            borderRadius: BorderRadius.circular(8)
                          ), 
                          child: Text("LAST VIEWED", style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
                        ),
                        const Icon(Iconsax.play_circle, color: Colors.white, size: 28),
                    ]),
                    const SizedBox(height: 12),
                    Text(
                      "Chapter 1: Real Numbers", 
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                    ),
                    Text(
                      "Topic: Euclid's Division Lemma", 
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10), 
                            child: LinearProgressIndicator(
                              value: lastChapterProgress, 
                              backgroundColor: Colors.white.withOpacity(0.3), 
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), 
                              minHeight: 6
                            )
                          )
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "${(lastChapterProgress * 100).toInt()}%", 
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)
                        ),
                      ]
                    )
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. Recent Quizzes Section
              Text("Recent Quizzes", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildRecentQuizzesSection(),

              const SizedBox(height: 24),

              // 3.5 MY MENTORS & REQUESTS SECTION
              if (_myMentors.isNotEmpty || _sentRequests.isNotEmpty) ...[
                Text("My Mentors", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160, // Increased height for buttons
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // 1. Approved Mentors
                      ..._myMentors.map((mentor) {
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => MentorResourcesScreen(mentor: mentor)),
                            );
                          },
                          child: Container(
                            width: 130,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green.shade200, width: 2),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.green.shade100,
                                  child: Text(mentor['full_name'][0], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.green)),
                                ),
                                const SizedBox(height: 8),
                                Text(mentor['full_name'], style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(mentor['subject'] ?? 'General', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                                  child: Text("Approved", style: GoogleFonts.poppins(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                          ),
                        );
                      }).toList(),

                      // 2. Pending Requests
                      ..._sentRequests.map((request) {
                        final teacher = request['teacher'];
                        final name = teacher['full_name'] ?? 'Teacher';
                        final subject = teacher['subject'] ?? 'General';
                        
                        return Container(
                          width: 130,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange.shade200, width: 2),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.orange.shade100,
                                child: Text(name[0], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.orange)),
                              ),
                              const SizedBox(height: 8),
                              Text(name, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(subject, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _withdrawRequest(request['id']),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade100)),
                                  child: Text("Withdraw", style: GoogleFonts.poppins(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                                ),
                              )
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 4. QUICK ACTIONS (Updated as per request)
              Text("Quick Actions", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  // CARD 1: PURPLE (AI SOLVER - RESTORED)
                  Expanded(
                    child: _buildQuickActionCard(
                      context, 
                      "AI Doubt\nSolver", 
                      Iconsax.cpu_charge, 
                      Colors.purple, 
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiSolverScreen()))
                    )
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // CARD 2: YELLOW/ORANGE (DYNAMIC MENTOR BUTTON)
                  Expanded(
                    child: _buildQuickActionCard(
                      context, 
                      "Find a\nMentor", 
                      Iconsax.teacher, 
                      Colors.orange, 
                      () async {
                         // Click karne par FindMentorScreen par jao
                         await Navigator.push(
                           context, 
                           MaterialPageRoute(builder: (_) => const FindMentorScreen())
                         );
                         _loadMentors(); // Refresh mentors list on return
                      }
                    )
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 5. My Subjects (Dynamic List)
              Text("My Subjects", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _dynamicSubjects.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text("No subjects found for $userClass yet.", style: GoogleFonts.poppins(color: Colors.grey))))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _dynamicSubjects.length,
                      itemBuilder: (context, index) {
                        final subject = _dynamicSubjects[index];
                        return _buildSubjectRow(subject);
                      },
                    ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HELPER WIDGETS
  // ===========================================================================

  // 1. Subject Row Widget
  Widget _buildSubjectRow(Map<String, dynamic> subject) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
           Navigator.push(
             context, 
             MaterialPageRoute(builder: (_) => SubjectDetailsScreen(
               subjectName: subject['name'], 
               subjectIcon: subject['icon'],
               subjectColor: subject['color'],
               chapters: subject['chapters'],
             ))
           );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: subject['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(subject['icon'], size: 24, color: subject['color']),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject['name'], style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text("${(subject['chapters'] as List).length} Chapters", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Iconsax.arrow_right_3, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Recent Quizzes Widget
  Widget _buildRecentQuizzesSection() {
    final recentQuizzes = [
      {'title': 'Algebra Basics Quiz', 'subject': 'Mathematics', 'score': '8/10', 'color': Colors.blue},
      {'title': 'Science Chapter 2', 'subject': 'Science', 'score': '9/10', 'color': Colors.green},
      {'title': 'History Timeline', 'subject': 'History', 'score': '7/10', 'color': Colors.orange},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: recentQuizzes.map((quiz) {
          return Container(
            margin: const EdgeInsets.only(right: 12),
            width: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (quiz['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (quiz['color'] as Color).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Iconsax.task_square, color: quiz['color'] as Color, size: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (quiz['color'] as Color).withOpacity(0.2), 
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Text(
                        quiz['score'] as String, 
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: quiz['color'] as Color)
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  quiz['title'] as String, 
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold), 
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis
                ),
                const SizedBox(height: 4),
                Text(
                  quiz['subject'] as String, 
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // 3. Quick Action Card Widget
  Widget _buildQuickActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 120,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 32, color: color),
            Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}