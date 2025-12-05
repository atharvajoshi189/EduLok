import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eduthon/services/auth_service.dart';
import 'package:eduthon/screens/login_screen.dart';
import 'package:eduthon/services/database_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TeacherDashboard extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final String teacherSubject;

  const TeacherDashboard({
    super.key, 
    required this.teacherId, 
    required this.teacherName, 
    required this.teacherSubject
  });

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  List<Map<String, dynamic>> myRequests = [];
  List<Map<String, dynamic>> myStudents = [];
  final String _baseUrl = "http://192.168.1.4:8000";

  @override
  void initState() {
    super.initState();
    _refreshDashboard();
  }

  Future<void> _refreshDashboard() async {
    final token = await AuthService.getAuthToken();
    if (token == null) return;

    try {
      // 1. Fetch Pending Requests
      final reqResponse = await http.get(
        Uri.parse('$_baseUrl/mentorship/requests/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      // 2. Fetch My Students
      final stuResponse = await http.get(
        Uri.parse('$_baseUrl/mentorship/students'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (reqResponse.statusCode == 200 && stuResponse.statusCode == 200) {
        final List<dynamic> reqData = json.decode(reqResponse.body);
        final List<dynamic> stuData = json.decode(stuResponse.body);

        if (mounted) {
          setState(() {
            myRequests = reqData.cast<Map<String, dynamic>>();
            
            // Map backend User objects to UI expected format
            myStudents = stuData.map((s) => {
              'student_name': s['full_name'],
              'mobile': s['mobile_number']
            }).toList().cast<Map<String, dynamic>>();
          });
        }
      } else {
        print("Failed to fetch data: ${reqResponse.statusCode} / ${stuResponse.statusCode}");
      }
    } catch (e) {
      print("Error fetching dashboard data: $e");
    }
  }

  Future<void> _acceptRequest(int index) async {
    final req = myRequests[index];
    final requestId = req['id'];

    // 1. Optimistic UI Update
    setState(() {
      myRequests.removeAt(index);
    });

    try {
      // 2. Check Connectivity
      bool isOnline = true; 
      try {
        await http.get(Uri.parse('$_baseUrl/'));
      } catch (_) {
        isOnline = false;
      }

      if (isOnline) {
        // --- ONLINE MODE ---
        final token = await AuthService.getAuthToken();
        if (token != null) {
          await http.post(
            Uri.parse('$_baseUrl/mentorship/requests/approve/$requestId'),
            headers: {'Authorization': 'Bearer $token'},
          );
          _refreshDashboard(); // Refresh to get updated lists
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Student Accepted!"), backgroundColor: Colors.green));
          }
        }
      } else {
        // --- OFFLINE MODE ---
        await DatabaseHelper.instance.addPendingAction(
          'APPROVE_REQUEST', 
          json.encode({'request_id': requestId})
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Offline: Request approved locally. Will sync when online.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- LOGOUT FUNCTION ---
  void _handleLogout() async {
    await AuthService.clearUserData();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen(onSignupTap: () {})),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Dashboard', style: GoogleFonts.poppins(color: Theme.of(context).appBarTheme.foregroundColor, fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
        actions: [
          // Requests Icon
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(icon: const Icon(Iconsax.notification), onPressed: _showRequestsDialog),
                if (myRequests.isNotEmpty)
                  CircleAvatar(radius: 8, backgroundColor: Colors.red, child: Text("${myRequests.length}", style: const TextStyle(fontSize: 10, color: Colors.white)))
              ],
            ),
          )
        ],
      ),
      // --- DRAWER WITH LOGOUT ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.orange),
              accountName: Text(widget.teacherName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              accountEmail: Text(widget.teacherSubject, style: GoogleFonts.poppins()),
              currentAccountPicture: CircleAvatar(backgroundColor: Theme.of(context).cardColor, child: const Icon(Iconsax.teacher, color: Colors.orange, size: 30)),
            ),
            ListTile(
              leading: const Icon(Iconsax.logout, color: Colors.red),
              title: Text('Logout', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hello, ${widget.teacherName}! 👋", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
            Text("${widget.teacherSubject} Mentor", style: GoogleFonts.poppins(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6))),
            const SizedBox(height: 25),
            Row(children: [
                _buildAnalyticsCard(title: 'My Students', count: '${myStudents.length}', color: Colors.blueAccent, icon: Iconsax.people),
                const SizedBox(width: 15),
                _buildAnalyticsCard(title: 'Pending Requests', count: '${myRequests.length}', color: Colors.orangeAccent, icon: Iconsax.user_add),
            ]),
            const SizedBox(height: 30),
            if (myStudents.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.orange.shade900.withOpacity(0.2) : Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade100)),
                child: Row(children: [
                    const Icon(Iconsax.info_circle, color: Colors.orange),
                    const SizedBox(width: 15),
                    Expanded(child: Text("You are live! Wait for students to send requests.", style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange.shade900))),
                ]),
              ),
            const SizedBox(height: 30),
            Text("Manage Content", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 15),
            GridView.count(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15,
              children: [
                 _buildActionCard(Icons.note_add_rounded, "Upload Notes", Colors.purple.shade400),
                 _buildActionCard(Icons.video_call_rounded, "Upload Video", Colors.redAccent),
                 _buildActionCard(Icons.quiz_rounded, "Create Quiz", Colors.teal),
                 _buildActionCard(Icons.settings_rounded, "Settings", Colors.grey.shade700),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Helper Widgets (Dialogs etc.)
  void _showRequestsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Requests (${myRequests.length})"),
        content: SizedBox(width: double.maxFinite, child: myRequests.isEmpty ? const Text("No pending requests.") : ListView.builder(shrinkWrap: true, itemCount: myRequests.length, itemBuilder: (context, index) { final req = myRequests[index]; return ListTile(leading: const CircleAvatar(child: Icon(Iconsax.user)), title: Text(req['student_name'] ?? "Unknown"), subtitle: Text("Status: ${req['status']}"), trailing: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), onPressed: () { Navigator.pop(ctx); _acceptRequest(index); }, child: const Text("Accept"))); })), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))],
      ),
    );
  }

  Widget _buildAnalyticsCard({required String title, required String count, required Color color, required IconData icon}) { return Expanded(child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color, size: 28), const SizedBox(height: 10), Text(count, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)), Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)))]))); }
  
  Widget _buildActionCard(IconData icon, String label, Color color) { return Container(decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircleAvatar(radius: 25, backgroundColor: color.withOpacity(0.1), child: Icon(icon, size: 30, color: color)), const SizedBox(height: 12), Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500))])); }
}