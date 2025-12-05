import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class MentorResourcesScreen extends StatefulWidget {
  final Map<String, dynamic> mentor;

  const MentorResourcesScreen({super.key, required this.mentor});

  @override
  State<MentorResourcesScreen> createState() => _MentorResourcesScreenState();
}

class _MentorResourcesScreenState extends State<MentorResourcesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.mentor['full_name'] ?? 'Mentor';
    final subject = widget.mentor['subject'] ?? 'General';

    return Scaffold(
      appBar: AppBar(
        title: Text(name, style: GoogleFonts.poppins(color: Theme.of(context).appBarTheme.foregroundColor, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.orange,
          tabs: const [
            Tab(text: "Notes"),
            Tab(text: "Lectures"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotesTab(),
          _buildLecturesTab(),
        ],
      ),
    );
  }

  Widget _buildNotesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Iconsax.document_text, color: Colors.orange),
            title: Text("Chapter ${index + 1} Notes", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            subtitle: Text("PDF • 2.5 MB", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            trailing: const Icon(Iconsax.import, color: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildLecturesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Iconsax.video_circle, color: Colors.blue),
            title: Text("Lecture ${index + 1}: Introduction", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            subtitle: Text("Video • 45 mins", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            trailing: const Icon(Iconsax.play_circle, color: Colors.blue),
          ),
        );
      },
    );
  }
}
