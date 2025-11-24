import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class QuizScreen extends StatefulWidget {
  final String chapterName;
  final List<dynamic> quizData;
  final Color color;

  const QuizScreen({
    super.key,
    required this.chapterName,
    required this.quizData,
    required this.color,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedOption;
  bool _isSubmitted = false;

  void _submitAnswer() {
    if (_selectedOption == null) return;

    // Check Answer
    if (_selectedOption == widget.quizData[_currentIndex]['answer']) {
      _score++;
    }

    setState(() {
      _isSubmitted = true;
    });

    // Wait 1 sec then Next Question
    Future.delayed(const Duration(seconds: 1), () {
      if (_currentIndex < widget.quizData.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedOption = null;
          _isSubmitted = false;
        });
      } else {
        // Quiz Over - Show Result
        _showResultDialog();
      }
    });
  }

  void _showResultDialog() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(30),
        height: 300,
        child: Column(
          children: [
            const Icon(Iconsax.cup, size: 60, color: Colors.orange),
            const SizedBox(height: 20),
            Text("Quiz Completed!", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("You scored $_score out of ${widget.quizData.length}", style: GoogleFonts.poppins(fontSize: 18)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close Dialog
                  Navigator.pop(context); // Close Quiz Screen (Returns to Quiz List)
                },
                style: ElevatedButton.styleFrom(backgroundColor: widget.color),
                child: const Text("Back to Quiz List", style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.quizData[_currentIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        title: Text("Quiz: ${widget.chapterName}", style: GoogleFonts.poppins(color: Theme.of(context).appBarTheme.foregroundColor, fontSize: 16)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.quizData.length,
              color: widget.color,
              backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
            const SizedBox(height: 20),
            
            // Question Number
            Text(
              "Question ${_currentIndex + 1}/${widget.quizData.length}",
              style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            
            // Question Text
            Text(
              question['question'],
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Options
            ...List.generate(4, (index) {
              bool isSelected = _selectedOption == index;
              bool isCorrect = index == question['answer'];
              
              Color tileColor = isDark ? Theme.of(context).cardColor : Colors.white;
              Color borderColor = isDark ? Colors.white10 : Colors.grey.shade300;

              if (_isSubmitted) {
                if (isCorrect) {
                  tileColor = Colors.green.shade50;
                  borderColor = Colors.green;
                  if (isDark) tileColor = Colors.green.withOpacity(0.2);
                } else if (isSelected) {
                  tileColor = Colors.red.shade50;
                  borderColor = Colors.red;
                  if (isDark) tileColor = Colors.red.withOpacity(0.2);
                }
              } else if (isSelected) {
                borderColor = widget.color;
                tileColor = widget.color.withOpacity(0.05);
              }

              return GestureDetector(
                onTap: _isSubmitted ? null : () => setState(() => _selectedOption = index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tileColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "${String.fromCharCode(65 + index)}.",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          question['options'][index],
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                      ),
                      if (_isSubmitted && isCorrect)
                        const Icon(Iconsax.tick_circle, color: Colors.green),
                    ],
                  ),
                ),
              );
            }),

            const Spacer(),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitted || _selectedOption == null ? null : _submitAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("Submit Answer", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}