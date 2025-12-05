import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:http/http.dart' as http;

// SERVICES
import 'package:eduthon/services/auth_service.dart';
import 'package:eduthon/services/language_service.dart';

// SCREENS
import 'package:eduthon/screens/find_mentor_screen.dart';
import 'package:eduthon/screens/mentor_resources_screen.dart';

class MentorScreen extends StatefulWidget {
  final List<dynamic> myMentors;
  final List<dynamic> sentRequests;
  final VoidCallback onRefresh; 

  const MentorScreen({
    super.key,
    required this.myMentors,
    required this.sentRequests,
    required this.onRefresh,
  });

  @override
  State<MentorScreen> createState() => _MentorScreenState();
}

class _MentorScreenState extends State<MentorScreen> {
  
  Future<void> _disconnectMentor(int mentorId) async {
    // Placeholder for API call to disconnect mentor
    // In a real app, this would call DELETE /mentorship/mentors/$mentorId
    
    // Optimistic update
    setState(() {
      widget.myMentors.removeWhere((m) => m['id'] == mentorId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)?.translate('mentorDisconnected') ?? "Mentor disconnected successfully")),
    );
    widget.onRefresh();
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
            SnackBar(content: Text(AppLocalizations.of(context)?.translate('requestWithdrawn') ?? "Request withdrawn successfully")),
          );
          widget.onRefresh(); 
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _startMeeting(String mentorName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.translate('startMeeting') ?? "Start 1:1 Meeting", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("${AppLocalizations.of(context)?.translate('initiatingCall') ?? 'Initiating video call...'} ($mentorName)", style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)?.translate('close') ?? "Close"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // CASE 1: NO MENTOR (LOCKED STATE)
    if (widget.myMentors.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)?.translate('mentorship') ?? "Mentorship", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Theme.of(context).appBarTheme.foregroundColor)),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          iconTheme: Theme.of(context).iconTheme,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Theme.of(context).disabledColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Iconsax.lock, size: 60, color: Theme.of(context).disabledColor),
                ),
                const SizedBox(height: 30),
                Text(
                  AppLocalizations.of(context)?.translate('mentorshipLocked') ?? "Mentorship Locked",
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context)?.translate('unlockMentorship') ?? "Find a mentor to unlock exclusive features like 1:1 meetings, doubt solving, and more.",
                  style: GoogleFonts.poppins(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FindMentorScreen()),
                      );
                      widget.onRefresh(); 
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 5,
                    ),
                    child: Text(AppLocalizations.of(context)?.translate('findMentor') ?? "Find a Mentor", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                if (widget.sentRequests.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    "${AppLocalizations.of(context)?.translate('pendingRequests') ?? 'You have pending request(s)'} (${widget.sentRequests.length})",
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange),
                  ),
                  const SizedBox(height: 10),
                  // Show pending requests list briefly or just the count
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.sentRequests.length,
                    itemBuilder: (ctx, i) {
                      final req = widget.sentRequests[i];
                      final teacher = req['teacher'];
                      return ListTile(
                        leading: const Icon(Iconsax.clock, color: Colors.orange, size: 20),
                        title: Text(teacher['full_name'] ?? "Teacher", style: GoogleFonts.poppins(fontSize: 14)),
                        trailing: TextButton(
                          onPressed: () => _withdrawRequest(req['id']),
                          child: Text(AppLocalizations.of(context)?.translate('withdraw') ?? "Withdraw", style: const TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                      );
                    },
                  )
                ]
              ],
            ),
          ),
        ),
      );
    }

    // CASE 2: HAS MENTOR (ACTIVE STATE)
    // Assuming usually one mentor, but handling list just in case
    final mentor = widget.myMentors.first; 
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.translate('myMentor') ?? "My Mentor", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Theme.of(context).appBarTheme.foregroundColor)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.search_normal),
            tooltip: "Browse Mentors",
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FindMentorScreen()),
              );
              widget.onRefresh();
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Mentor Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Text(mentor['full_name'][0], style: GoogleFonts.poppins(fontSize: 30, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                  ),
                  const SizedBox(height: 15),
                  Text(mentor['full_name'], style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  Text(AppLocalizations.of(context)?.translate('subjectExpert') ?? "Subject Expert", style: GoogleFonts.poppins(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6))),
                  
                  const SizedBox(height: 20),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _startMeeting(mentor['full_name']),
                          icon: const Icon(Iconsax.video, size: 18),
                          label: Text(AppLocalizations.of(context)?.translate('meeting') ?? "1:1 Meeting"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                             Navigator.push(context, MaterialPageRoute(builder: (_) => MentorResourcesScreen(mentor: mentor)));
                          },
                          icon: const Icon(Iconsax.folder_open, size: 18),
                          label: Text(AppLocalizations.of(context)?.translate('resources') ?? "Resources"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Theme.of(context).dividerColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(AppLocalizations.of(context)?.translate('disconnectMentor') ?? "Disconnect Mentor?"),
                            content: Text(AppLocalizations.of(context)?.translate('disconnectConfirm') ?? "Are you sure you want to disconnect? You will lose access to their resources."),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)?.translate('cancel') ?? "Cancel")),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _disconnectMentor(mentor['id'] ?? 0);
                                }, 
                                child: Text(AppLocalizations.of(context)?.translate('disconnect') ?? "Disconnect", style: const TextStyle(color: Colors.red))
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Iconsax.user_minus, size: 18, color: Colors.red),
                      label: Text(AppLocalizations.of(context)?.translate('disconnectMentor') ?? "Disconnect Mentor", style: const TextStyle(color: Colors.red)),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}