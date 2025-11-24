import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eduthon/services/syllabus_service.dart';
import 'package:eduthon/screens/quiz_screen.dart';

class QuizListScreen extends StatefulWidget {
  final String className;
  const QuizListScreen({super.key, required this.className});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  List<Map<String, dynamic>> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void didUpdateWidget(QuizListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.className != widget.className) {
      _loadSubjects();
    }
  }

  void _loadSubjects() {
    setState(() {
      _subjects = SyllabusService().getSubjectsForClass(widget.className);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text("My Quizzes", style: GoogleFonts.poppins(color: Theme.of(context).appBarTheme.foregroundColor, fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _subjects.length,
        itemBuilder: (context, index) {
          final subject = _subjects[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(subject['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              ...subject['chapters'].map<Widget>((chapter) {
                // Check karo quiz hai ya nahi
                bool hasQuiz = chapter['quiz'] != null && (chapter['quiz'] as List).isNotEmpty;
                
                if (!hasQuiz) return const SizedBox(); // Quiz nahi hai to chupao

                return Card(
                  elevation: 0,
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: subject['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Icon(Iconsax.task_square, color: subject['color']),
                    ),
                    title: Text(chapter['title'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    subtitle: Text("3 Questions • 5 Mins", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(
                          chapterName: chapter['title'],
                          quizData: chapter['quiz'],
                          color: subject['color'],
                        )));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: subject['color'], 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        minimumSize: const Size(80, 30)
                      ),
                      child: const Text("Start", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }
}