import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

// SERVICES
import 'package:eduthon/services/syllabus_service.dart';
import 'package:eduthon/services/database_helper.dart'; // To fetch last watched
import 'package:eduthon/services/data_manager.dart';   // To fetch chapter details
import 'package:eduthon/services/language_service.dart';

// SCREENS
import 'package:eduthon/screens/quiz_screen.dart';

class QuizListScreen extends StatefulWidget {
  final String className;

  const QuizListScreen({super.key, required this.className});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  // Data Variables
  List<Map<String, dynamic>> _subjects = [];
  Map<String, dynamic>? _recommendedChapter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. Load Subjects for current class
    final subjects = SyllabusService().getSubjectsForClass(widget.className);

    // 2. Load Last Studied Chapter from Database (Offline Sync)
    final lastStudied = await DatabaseHelper.instance.getLastStudiedChapter();
    
    Map<String, dynamic>? recChapter;
    if (lastStudied != null) {
      // DataManager se full details nikalo using ID
      // Assuming lastStudied returns {'chapter_id': '...', 'subject_name': '...'}
      // Note: Logic needs exact mapping, here we try to find it via ID
      String lastId = lastStudied['chapter_id'];
      
      // Helper function in DataManager to find chapter by ID
      recChapter = DataManager.getChapterById(widget.className, "Science", lastId) 
                ?? DataManager.getChapterById(widget.className, "Mathematics", lastId); 
                // (Simple search across main subjects)
    }

    if (mounted) {
      setState(() {
        _subjects = subjects;
        _recommendedChapter = recChapter;
        _isLoading = false;
      });
    }
  }

  // --- LOGIC: Start Quiz ---
  void _startQuiz(Map<String, dynamic> chapterData, Color subjectColor) {
    // 1. Check if AI Quiz data exists
    List<dynamic> rawQuiz = [];
    
    if (chapterData['smart_content'] != null && chapterData['smart_content']['quiz'] != null) {
      rawQuiz = chapterData['smart_content']['quiz'];
    } else {
      // Fallback: Agar AI quiz nahi hai to dummy show karo ya return karo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.translate('noQuizGenerated') ?? "No quiz generated for this chapter yet."))
      );
      return;
    }

    // 2. CONVERT AI DATA (String Answer) TO UI DATA (Index Answer)
    // AI Format: { "correct_answer": "Mitochondria", "options": ["A", "B", "Mitochondria"] }
    // UI Format: { "answer": 2 }
    List<Map<String, dynamic>> processedQuiz = [];

    for (var q in rawQuiz) {
      List<String> options = List<String>.from(q['options']);
      int ansIndex = options.indexOf(q['correct_answer']);
      
      // Shuffle options for better experience (Optional)
      // options.shuffle(); // Note: If you shuffle, recalculate index!

      processedQuiz.add({
        "question": q['question'],
        "options": options,
        "answer": ansIndex != -1 ? ansIndex : 0, // Safety check
      });
    }

    // 3. Navigate
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          chapterName: chapterData['title'],
          quizData: processedQuiz,
          color: subjectColor,
        ),
      ),
    );
  }

  // --- LOGIC: Show Chapter List Bottom Sheet ---
  void _showChapters(Map<String, dynamic> subject) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            // Handle Bar
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2))),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: subject['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(subject['icon'], color: subject['color']),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)?.translate(subject['name'].toString().toLowerCase()) ?? subject['name'], style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(AppLocalizations.of(context)?.translate('selectChapter') ?? "Select a chapter to practice", style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),
            const Divider(),

            // Chapter List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: subject['chapters'].length,
                itemBuilder: (ctx, i) {
                  final chapter = subject['chapters'][i];
                  final bool hasAiQuiz = chapter['smart_content'] != null;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    color: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: hasAiQuiz ? Colors.purple.shade50 : Theme.of(context).disabledColor.withOpacity(0.1),
                        child: Icon(
                          hasAiQuiz ? Iconsax.magic_star : Iconsax.document, 
                          color: hasAiQuiz ? Colors.purple : Colors.grey
                        ),
                      ),
                      title: Text(chapter['title'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        hasAiQuiz 
                          ? (AppLocalizations.of(context)?.translate('aiQuizAvailable') ?? "AI Quiz Available") 
                          : (AppLocalizations.of(context)?.translate('standardPractice') ?? "Standard Practice"), 
                        style: GoogleFonts.poppins(fontSize: 10, color: hasAiQuiz ? Colors.purple : Colors.grey)
                      ),
                      trailing: const Icon(Iconsax.arrow_right_3, size: 16),
                      onTap: () {
                        Navigator.pop(ctx); // Close Sheet
                        _startQuiz(chapter, subject['color']);
                      },
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.translate('practiceArena') ?? "Practice Arena", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // 1. RECOMMENDED SECTION (Dynamic)
            if (_recommendedChapter != null) ...[
              Text(AppLocalizations.of(context)?.translate('recommendedForYou') ?? "Recommended for You", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _startQuiz(_recommendedChapter!, Colors.orange), // Default color for recommended
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6A11CB), Color(0xFF2575FC)], // Purple-Blue Gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF2575FC).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                              child: Text(AppLocalizations.of(context)?.translate('basedOnActivity') ?? "BASED ON YOUR ACTIVITY", style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 10),
                            Text(_recommendedChapter!['title'], style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(AppLocalizations.of(context)?.translate('quickTest') ?? "Quick 10 min test • 10 Questions", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      const CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white,
                        child: Icon(Iconsax.play, color: Color(0xFF2575FC)),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],

            // 2. ALL SUBJECTS GRID
            Text(AppLocalizations.of(context)?.translate('browseBySubject') ?? "Browse by Subject", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: _subjects.length,
                itemBuilder: (ctx, i) {
                  final subject = _subjects[i];
                  return InkWell(
                    onTap: () => _showChapters(subject),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: subject['color'].withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(subject['icon'], size: 30, color: subject['color']),
                          ),
                          const SizedBox(height: 15),
                          Text(AppLocalizations.of(context)?.translate(subject['name'].toString().toLowerCase()) ?? subject['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text("${subject['chapters'].length} ${AppLocalizations.of(context)?.translate('chapters') ?? 'Chapters'}", style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}