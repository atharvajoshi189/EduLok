import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class QuizScreen extends StatefulWidget {
  final String chapterName;
  // quizData Format expected: 
  // [ { "question": "...", "options": ["A", "B", ...], "answer": 1 (Index as INT) } ]
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

    // Correct Answer Logic
    // Backend/AI gives index of correct option
    int correctIndex = widget.quizData[_currentIndex]['answer'];

    if (_selectedOption == correctIndex) {
      _score++;
    }

    setState(() {
      _isSubmitted = true;
    });

    // Wait 1.5 sec then Next Question
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return; // Check if user backed out
      
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
        height: 350,
        child: Column(
          children: [
             // Dynamic Icon based on Score
            Icon(
              _score > (widget.quizData.length / 2) ? Iconsax.cup : Iconsax.emoji_sad, 
              size: 60, 
              color: widget.color
            ),
            const SizedBox(height: 20),
            
            Text(
              _score > (widget.quizData.length / 2) ? "Great Job!" : "Keep Practicing!", 
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)
            ),
            
            const SizedBox(height: 10),
            Text("You scored $_score out of ${widget.quizData.length}", style: GoogleFonts.poppins(fontSize: 18)),
            
            const SizedBox(height: 30),
            
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem("Correct", "$_score", Colors.green),
                _buildStatItem("Wrong", "${widget.quizData.length - _score}", Colors.red),
              ],
            ),
            
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close Dialog
                  Navigator.pop(context); // Close Quiz Screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                child: const Text("Back to Practice", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
      ],
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
        title: Text("Question ${_currentIndex + 1}/${widget.quizData.length}", style: GoogleFonts.poppins(color: Theme.of(context).appBarTheme.foregroundColor, fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / widget.quizData.length,
                color: widget.color,
                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 30),
            
            // Question Text
            Text(
              question['question'],
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, height: 1.4),
            ),
            const SizedBox(height: 30),

            // Options List
            Expanded(
              child: ListView.builder(
                itemCount: 4,
                itemBuilder: (ctx, index) {
                  // If options are less than 4 (safety)
                  if (index >= (question['options'] as List).length) return const SizedBox.shrink();

                  bool isSelected = _selectedOption == index;
                  int correctIndex = question['answer'];
                  bool isCorrect = index == correctIndex;
                  
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
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: tileColor,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? widget.color : Colors.transparent,
                              border: Border.all(color: isSelected ? widget.color : Colors.grey.shade400)
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, 
                                  color: isSelected ? Colors.white : Colors.grey
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              question['options'][index],
                              style: GoogleFonts.poppins(fontSize: 16),
                            ),
                          ),
                          if (_isSubmitted && isCorrect)
                            const Icon(Iconsax.tick_circle, color: Colors.green),
                          if (_isSubmitted && isSelected && !isCorrect)
                            const Icon(Iconsax.close_circle, color: Colors.red),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitted || _selectedOption == null ? null : _submitAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  shadowColor: widget.color.withOpacity(0.4)
                ),
                child: Text(
                  _isSubmitted ? "Checking..." : "Submit Answer", 
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}