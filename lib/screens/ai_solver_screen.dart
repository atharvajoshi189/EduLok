import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eduthon/theme/app_colors.dart';
import 'package:eduthon/services/ai_service.dart'; // AI Service Import

class AiSolverScreen extends StatefulWidget {
  const AiSolverScreen({super.key});

  @override
  State<AiSolverScreen> createState() => _AiSolverScreenState();
}

class _AiSolverScreenState extends State<AiSolverScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Chat Messages List (Initial greeting)
  final List<Map<String, String>> _messages = [
    {
      'role': 'bot', 
      'text': 'Hello! I am EduLok AI. Ask me anything from your downloaded textbooks, or just say Hi!'
    }
  ];

  bool _isSearching = false;

  // --- Send Message Function (Connected to Smart Brain) ---
  Future<void> _sendMessage() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    // 1. User ka message add karein
    setState(() {
      _messages.add({'role': 'user', 'text': query});
      _isSearching = true; // Loading start
    });
    
    _controller.clear();
    _scrollToBottom(); 

    try {
      // 2. AI Service se "Chat" karein (UPDATED FUNCTION NAME)
      // Humne 'getChatResponse' ko 'askEduLok' se replace kiya hai
      final String response = await AIService().askEduLok(query);

      // 3. Bot ka response add karein
      if (mounted) {
        setState(() {
          _messages.add({'role': 'bot', 'text': response});
        });
      }

    } catch (e) {
      print("❌ Error in UI: $e");
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'bot', 
            'text': "My brain feels a bit fuzzy (Error). Please try asking again."
          });
        });
      }
    } finally {
      // 4. Loading band karein
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        _scrollToBottom();
      }
    }
  }

  // Helper: Auto-scroll to newest message
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      
      // --- Top Bar ---
      appBar: AppBar(
        title: Text(
          'AI Doubt Solver', 
          style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 1,
        iconTheme: Theme.of(context).iconTheme,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),

      body: Column(
        children: [
          // --- Chat List Area ---
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.teal : (isDark ? Theme.of(context).cardColor : Colors.white),
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isUser ? const Radius.circular(0) : null,
                        bottomLeft: !isUser ? const Radius.circular(0) : null,
                      ),
                      boxShadow: [
                        if (!isUser)
                          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))
                      ],
                    ),
                    child: Text(
                      msg['text']!,
                      style: GoogleFonts.poppins(
                        color: isUser ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 15,
                        height: 1.4, 
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // --- Thinking Indicator ---
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal)),
                  const SizedBox(width: 10),
                  Text("EduLok is checking books...", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ),
            ),

          // --- Input Field Area ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences, 
                    style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: 'Ask a doubt...',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: isDark ? Theme.of(context).scaffoldBackgroundColor : AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Send Button
                CircleAvatar(
                  backgroundColor: AppColors.indigo,
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Iconsax.send_1, color: Colors.white, size: 22),
                    onPressed: _isSearching ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}