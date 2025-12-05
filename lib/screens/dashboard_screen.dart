import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eduthon/services/syllabus_service.dart';
import 'package:eduthon/services/auth_service.dart';
import 'package:eduthon/screens/auth_screen.dart';
import 'package:eduthon/screens/subject_details_screen.dart';
import 'package:eduthon/screens/chat_screen.dart';
import 'package:eduthon/services/theme_manager.dart';
import 'package:eduthon/services/language_service.dart';
import 'package:eduthon/screens/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(String) onClassChanged;

  const DashboardScreen({super.key, required this.onClassChanged});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String userName = "Atharva"; // Default/Placeholder
  String userClass = "Class 10";
  String userBoard = "CBSE";
  int streakDays = 12;
  double lastChapterProgress = 0.65;
  
  // Dynamic Data
  List<Map<String, dynamic>> _dynamicSubjects = [];
  bool _isLoading = true;

  // Connection Status (Mock)
  String _connectionStatus = "Online";
  Color _statusColor = Colors.green;
  IconData _statusIcon = Iconsax.wifi;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _refreshSubjects();
  }

  Future<void> _loadUserData() async {
    final name = await AuthService.getName();
    final cls = await AuthService.getClass();
    if (name != null) setState(() => userName = name);
    if (cls != null) setState(() => userClass = cls);
  }

  void _refreshSubjects() {
    setState(() => _isLoading = true);
    // Simulate network delay for "refresh" feel
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        final subjects = SyllabusService().getSubjectsForClass(userClass);
        setState(() {
          _dynamicSubjects = subjects;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _handleLogout() async {
    await AuthService.clearUserData();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (_) => const AuthScreen()), 
        (route) => false
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      
      // --- APP BAR ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(Iconsax.book_1, color: Theme.of(context).primaryColor, size: 20),
            ),
            const SizedBox(width: 10),
            DropdownButton<String>(
              value: userClass,
              dropdownColor: Theme.of(context).cardColor,
              underline: const SizedBox(),
              icon: Icon(Iconsax.arrow_down_1, size: 16, color: Theme.of(context).appBarTheme.foregroundColor),
              style: GoogleFonts.poppins(color: Theme.of(context).appBarTheme.foregroundColor, fontWeight: FontWeight.bold, fontSize: 16),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    userClass = newValue;
                    _refreshSubjects();
                  });
                  widget.onClassChanged(newValue);
                }
              },
              items: <String>['Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.user),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _statusColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(_statusIcon, color: _statusColor, size: 16),
                const SizedBox(width: 6),
                Text(_connectionStatus, style: GoogleFonts.poppins(fontSize: 12, color: _statusColor, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),

      // --- DRAWER ---
      drawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              accountName: Text(AppLocalizations.of(context)?.getUserName(userName) ?? userName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              accountEmail: Text("$userClass • $userBoard", style: GoogleFonts.poppins()),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Theme.of(context).cardColor,
                child: Text(userName[0], style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
              ),
            ),
            ListTile(
              leading: Icon(Iconsax.setting_2, color: Theme.of(context).iconTheme.color),
              title: Text('Settings', style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodyLarge?.color)),
              onTap: () {
                Navigator.pop(context);
                // Navigate to Settings
              },
            ),
            ListTile(
              leading: Icon(Iconsax.language_square, color: Theme.of(context).iconTheme.color),
              title: Text(AppLocalizations.of(context)?.translate('language') ?? 'Language', style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodyLarge?.color)),
              trailing: DropdownButton<String>(
                value: LanguageService().currentLocale.languageCode,
                underline: const SizedBox(),
                dropdownColor: Theme.of(context).cardColor,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    LanguageService().changeLanguage(newValue);
                  }
                },
                items: [
                  {'code': 'en', 'name': 'English'},
                  {'code': 'hi', 'name': 'हिंदी'},
                  {'code': 'mr', 'name': 'मराठी'},
                  {'code': 'ta', 'name': 'தமிழ்'},
                  {'code': 'gu', 'name': 'ગુજરાતી'},
                  {'code': 'bn', 'name': 'বাংলা'},
                  {'code': 'te', 'name': 'తెలుగు'},
                ].map<DropdownMenuItem<String>>((Map<String, String> lang) {
                  return DropdownMenuItem<String>(
                    value: lang['code'],
                    child: Text(lang['name']!, style: GoogleFonts.poppins(fontSize: 14)),
                  );
                }).toList(),
              ),
            ),
            ListTile(
              leading: Icon(Iconsax.moon, color: Theme.of(context).iconTheme.color),
              title: Text(AppLocalizations.of(context)?.translate('darkMode') ?? 'Dark Mode', style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodyLarge?.color)),
              trailing: Switch(
                value: ThemeManager().isDarkMode,
                onChanged: (val) {
                  ThemeManager().toggleTheme(val);
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Iconsax.logout, color: Colors.red),
              title: Text(AppLocalizations.of(context)?.translate('logout') ?? 'Logout', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: _handleLogout,
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. WELCOME HEADER
            Text("${AppLocalizations.of(context)?.translate('welcome') ?? 'Welcome'},", style: GoogleFonts.poppins(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6))),
            Text(AppLocalizations.of(context)?.getUserName(userName) ?? userName, style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
            
            const SizedBox(height: 20),

            // 2. STREAK & PROGRESS CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Theme.of(context).primaryColor, const Color(0xFF6A11CB)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)?.translate('dailyStreak') ?? "Daily Streak 🔥", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                        Text("$streakDays ${AppLocalizations.of(context)?.translate('days') ?? 'Days'}", style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(value: lastChapterProgress, backgroundColor: Colors.white24, color: Colors.white, minHeight: 6),
                        ),
                        const SizedBox(height: 6),
                        Text(AppLocalizations.of(context)?.translate('lastChapter') ?? "Last Chapter: 65% Completed", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Iconsax.cup, color: Colors.white, size: 30),
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 3. RECENT QUIZZES
            Text(AppLocalizations.of(context)?.translate('recentActivity') ?? "Recent Activity", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
            const SizedBox(height: 15),
            _buildRecentQuizzesSection(),

            const SizedBox(height: 30),

            // 4. QUICK ACTIONS
            Text(AppLocalizations.of(context)?.translate('quickActions') ?? "Quick Actions", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
            const SizedBox(height: 15),
            _buildQuickActionCard(context, AppLocalizations.of(context)?.translate('askAiDoubt') ?? "Ask AI Doubt", Iconsax.message_question, Colors.purple, () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
            }),

            const SizedBox(height: 30),

            // 5. YOUR SUBJECTS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)?.translate('yourSubjects') ?? "Your Subjects", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                IconButton(icon: Icon(Iconsax.refresh, color: Theme.of(context).primaryColor), onPressed: _refreshSubjects),
              ],
            ),
            const SizedBox(height: 15),

            // DYNAMIC SUBJECTS LIST
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _dynamicSubjects.isEmpty 
                  ? Center(child: Text("${AppLocalizations.of(context)?.translate('noSubjects') ?? 'No subjects found'} $userClass", style: GoogleFonts.poppins()))
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: _dynamicSubjects.length,
                      itemBuilder: (context, index) {
                        final subject = _dynamicSubjects[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => SubjectDetailsScreen(
                              subjectName: AppLocalizations.of(context)?.translate(subject['name'].toString().toLowerCase()) ?? subject['name'],
                              chapters: subject['chapters'],
                              subjectColor: subject['color'],
                              subjectIcon: _getIconData(subject['icon']),
                            )));
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: (subject['color'] as Color).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getIconData(subject['icon']), 
                                    size: 32, 
                                    color: subject['color']
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(AppLocalizations.of(context)?.translate(subject['name'].toString().toLowerCase()) ?? subject['name'], style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                                Text("${(subject['chapters'] as List).length} ${AppLocalizations.of(context)?.translate('chapters') ?? 'Chapters'}", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(dynamic icon) {
    if (icon is IconData) return icon;
    // Fallback mapping if icon is string (though SyllabusService handles this)
    switch (icon.toString()) {
      case 'science': return Iconsax.element_3;
      case 'math': return Iconsax.calculator;
      case 'history': return Iconsax.book;
      case 'english': return Iconsax.language_circle;
      default: return Iconsax.book_1;
    }
  }

  Widget _buildRecentQuizzesSection() {
    final recentQuizzes = [
      {'title': 'algebraQuiz', 'subject': 'mathematics', 'score': '8/10', 'color': Colors.blue},
      {'title': 'scienceChapter', 'subject': 'science', 'score': '9/10', 'color': Colors.green},
      {'title': 'historyTimeline', 'subject': 'history', 'score': '7/10', 'color': Colors.orange},
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
                  AppLocalizations.of(context)?.translate(quiz['title'] as String) ?? quiz['title'] as String, 
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold), 
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)?.translate(quiz['subject'] as String) ?? quiz['subject'] as String, 
                  style: GoogleFonts.poppins(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7))
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        height: 100, 
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
             Container(
               padding: const EdgeInsets.all(10),
               decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(10)),
               child: Icon(icon, size: 30, color: color)
             ),
             const SizedBox(width: 15),
             Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
             const Spacer(),
             Icon(Iconsax.arrow_right_1, color: color)
          ],
        ),
      ),
    );
  }
}