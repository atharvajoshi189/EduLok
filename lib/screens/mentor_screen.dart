import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eduthon/screens/find_mentor_screen.dart';
import 'package:eduthon/services/database_helper.dart';
import 'package:eduthon/services/auth_service.dart';

class MentorScreen extends StatefulWidget {
  final Map<String, dynamic>? currentMentor;

  const MentorScreen({super.key, this.currentMentor});

  @override
  State<MentorScreen> createState() => _MentorScreenState();
}

class _MentorScreenState extends State<MentorScreen> {
  Map<String, dynamic>? _mentorData;
  String _status = "Locked"; // Possible values: Locked, Pending, Accepted
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _mentorData = widget.currentMentor;
    _checkStatus();
  }

  // Check Database for current relationship status
  Future<void> _checkStatus() async {
    if (_mentorData == null) {
      setState(() { _status = "Locked"; _isLoading = false; });
      return;
    }

    String? studentName = await AuthService.getName();
    
    // Database se check karo
    String? status = await DatabaseHelper.instance.getRequestStatus(
      _mentorData!['id'], 
      studentName ?? "Unknown"
    );

    if (mounted) {
      setState(() {
        _status = status ?? "Locked"; 
        // Agar DB mein 'Locked' (no request) hai par UI mein mentor data hai, toh clear karo
        if (_status == "Locked") _mentorData = null;
        _isLoading = false;
      });
    }
  }

  // Logic to Withdraw Request
  Future<void> _withdrawRequest() async {
    String? studentName = await AuthService.getName();
    await DatabaseHelper.instance.withdrawRequest(
      _mentorData!['id'], 
      studentName ?? "Unknown"
    );
    
    setState(() {
      _mentorData = null;
      _status = "Locked";
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Request Withdrawn"))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Mentor", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: const SizedBox(), // Hide default back button for main tab
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_status == "Locked") return _buildLockedView();
    if (_status == "Pending") return _buildPendingView();
    return _buildAcceptedView();
  }

  // --- VIEW 1: LOCKED ---
  Widget _buildLockedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: const Icon(Iconsax.lock, size: 60, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Text("No Mentor Selected", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("Connect with a teacher to start learning.", style: GoogleFonts.poppins(color: Colors.grey)),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2554A3),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12)
            ),
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const FindMentorScreen()));
              // Optimistic update: If returning from selection, assume pending until verify
              if (result != null) {
                setState(() { _mentorData = result; _status = "Pending"; });
                _checkStatus(); // Double check with DB
              }
            },
            child: const Text("Find a Mentor", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --- VIEW 2: PENDING ---
  Widget _buildPendingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.orange.withOpacity(0.2),
              child: const Icon(Iconsax.timer_1, size: 40, color: Colors.orange),
            ),
            const SizedBox(height: 30),
            Text("Request Sent!", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              "Waiting for ${_mentorData!['name']} to accept your request.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            OutlinedButton.icon(
              onPressed: _withdrawRequest,
              icon: const Icon(Icons.close, color: Colors.red),
              label: Text("Withdraw Request", style: GoogleFonts.poppins(color: Colors.red)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
            )
          ],
        ),
      ),
    );
  }

  // --- VIEW 3: ACCEPTED (TEACHER DASHBOARD) ---
  Widget _buildAcceptedView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Teacher Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue.shade800, Colors.blue.shade500]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    _mentorData!['name'][0],
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _mentorData!['name'],
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        "${_mentorData!['subject']} Expert",
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Options Grid
          Text("Classroom Actions", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            children: [
              _buildActionCard(Iconsax.message_question, "Ask Doubt", Colors.orange),
              _buildActionCard(Iconsax.document_text, "Notes", Colors.purple),
              _buildActionCard(Iconsax.video_play, "Video Lectures", Colors.red),
              _buildActionCard(Iconsax.task_square, "Assignments", Colors.green),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String title, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 15),
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}