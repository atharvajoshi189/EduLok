import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eduthon/screens/chapter_content_screen.dart';
import 'package:eduthon/services/language_service.dart';

class SubjectDetailsScreen extends StatefulWidget {
  final String subjectName;
  final IconData subjectIcon;
  final Color subjectColor;
  final List<dynamic> chapters; // 🔥 Data Dashboard se aayega

  const SubjectDetailsScreen({
    super.key,
    required this.subjectName,
    required this.subjectIcon,
    required this.subjectColor,
    required this.chapters, // 🔥 Constructor updated
  });

  @override
  State<SubjectDetailsScreen> createState() => _SubjectDetailsScreenState();
}

class _SubjectDetailsScreenState extends State<SubjectDetailsScreen> {
  
  @override
  Widget build(BuildContext context) {
    // Dashboard se jo chapters mile hain, unhe use karo
    final chapters = widget.chapters;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      
      appBar: AppBar(
        backgroundColor: widget.subjectColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.subjectName,
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: Column(
        children: [
          // --- HERO HEADER ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            decoration: BoxDecoration(
              color: widget.subjectColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.subjectIcon, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${chapters.length} ${AppLocalizations.of(context)?.translate('chapters') ?? 'Chapters'}",
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          AppLocalizations.of(context)?.translate('tapToStart') ?? "Tap to start learning",
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Text("Total Progress: 0%", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const LinearProgressIndicator(
                    value: 0.0,
                    backgroundColor: Colors.black12,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          // --- CHAPTER LIST ---
          Expanded(
            child: chapters.isEmpty 
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.book, size: 50, color: Colors.grey.shade300),
                    const SizedBox(height: 10),
                    Text(AppLocalizations.of(context)?.translate('noChapters') ?? "No chapters added yet.", style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5))),
                  ],
                ),
              )
            : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                return _buildChapterCard(chapter, index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterCard(Map<String, dynamic> chapter, int index) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => ChapterContentScreen(
            chapterId: chapter['id'],
            chapterName: chapter['title'],
            videoId: chapter['videoId'],
            notesMarkdown: chapter['notes'],
            color: widget.subjectColor,
          ))
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: widget.subjectColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  "$index",
                  style: GoogleFonts.poppins(
                    color: widget.subjectColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter['title'],
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  Text(
                    chapter['desc'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6), 
                      fontSize: 12
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Iconsax.play_circle5, color: widget.subjectColor, size: 28),
          ],
        ),
      ),
    );
  }
}