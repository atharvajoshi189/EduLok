import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eduthon/services/history_service.dart';
import 'package:intl/intl.dart';

class HistoryDrawer extends StatefulWidget {
  final Function(String sessionId, String type) onSessionSelected;

  const HistoryDrawer({super.key, required this.onSessionSelected});

  @override
  State<HistoryDrawer> createState() => _HistoryDrawerState();
}

class _HistoryDrawerState extends State<HistoryDrawer> {
  late Future<List<Map<String, dynamic>>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _refreshSessions();
  }

  void _refreshSessions() {
    setState(() {
      _sessionsFuture = HistoryService().getSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFFF0F4F9),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.clock, size: 40, color: Color(0xFF4285F4)),
                  const SizedBox(height: 10),
                  Text(
                    "Recent Activity",
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _sessionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.box_remove, size: 40, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text(
                          "No history yet",
                          style: GoogleFonts.outfit(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final sessions = snapshot.data!;
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: sessions.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final isChat = session['type'] == 'chat';
                    final date = DateTime.fromMillisecondsSinceEpoch(session['timestamp']);
                    final dateString = DateFormat('MMM d, h:mm a').format(date);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isChat ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        child: Icon(
                          isChat ? Iconsax.message : Iconsax.camera,
                          color: isChat ? Colors.blue : Colors.orange,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        session['title'] ?? 'Untitled',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w500, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        dateString,
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                      ),
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        widget.onSessionSelected(session['id'], session['type']);
                      },
                      trailing: IconButton(
                        icon: const Icon(Iconsax.trash, size: 18, color: Colors.redAccent),
                        onPressed: () async {
                          await HistoryService().deleteSession(session['id']);
                          _refreshSessions();
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
