import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eduthon/services/ai_service.dart';
import 'package:eduthon/services/voice_service.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:eduthon/services/auth_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:eduthon/services/history_service.dart';
import 'package:eduthon/widgets/history_drawer.dart';
import 'package:eduthon/services/tutor_engine.dart';
import 'package:eduthon/services/offline_chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String? initialSessionId;
  const ChatScreen({super.key, this.initialSessionId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _isAutoSpeak = false;
  bool _isListening = false;
  String _userName = "Student";
  String? _sessionId;
  bool _engineReady = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    VoiceService().init();
    _initializeEngines(); // Initialize both engines
    if (widget.initialSessionId != null) {
      _loadHistory(widget.initialSessionId!);
    }
  }

  Future<void> _initializeEngines() async {
    // Initialize both engines in parallel
    await Future.wait([
      TutorEngine().init(),
      OfflineChatService.init(),
    ]);
    setState(() {
      _engineReady = true;
    });
  }

  Future<void> _loadUserName() async {
    final name = await AuthService.getName();
    if (name != null) {
      setState(() {
        _userName = name.split(' ')[0]; // First name only
      });
    }
  }

  Future<void> _loadHistory(String sessionId) async {
    final messages = await HistoryService().getMessages(sessionId);
    setState(() {
      _sessionId = sessionId;
      _messages = messages.map((m) => {
        "role": m['role'],
        "message": m['content'],
        "timestamp": DateTime.now() // Timestamp not stored in msg table, using now
      }).toList();
    });
    _scrollToBottom();
  }

  Future<void> _startNewChat() async {
    setState(() {
      _sessionId = null;
      _messages = [];
    });
  }

  Future<void> _ensureSession() async {
    if (_sessionId == null) {
      // Create new session with title as first message (truncated)
      String title = _messages.isNotEmpty ? _messages.first['message'] : "New Chat";
      if (title.length > 30) title = "${title.substring(0, 30)}...";
      
      _sessionId = await HistoryService().createSession(title, 'chat');
      
      // Save existing messages if any (though usually this is called on first message)
      for (var msg in _messages) {
        await HistoryService().addMessage(_sessionId!, msg['role'], msg['message']);
      }
    }
  }

  void _addBotMessage(String text) async {
    setState(() {
      _messages.add({
        "role": "bot",
        "message": text,
        "timestamp": DateTime.now()
      });
    });
    _scrollToBottom();

    await _ensureSession();
    await HistoryService().addMessage(_sessionId!, 'bot', text);
  }

  void _addUserMessage(String text) async {
    setState(() {
      _messages.add({
        "role": "user",
        "message": text,
        "timestamp": DateTime.now()
      });
    });
    _scrollToBottom();
    
    await _ensureSession();
    await HistoryService().addMessage(_sessionId!, 'user', text);

    _processQuery(text);
  }

  Future<void> _processQuery(String query) async {
    setState(() {
      _isTyping = true;
    });

    // Simulate thinking delay for better UX
    await Future.delayed(const Duration(milliseconds: 600));

    String responseText = "";
    
    try {
      // Try TutorEngine first (vector search)
      if (_engineReady && TutorEngine().isInitialized) {
        responseText = await TutorEngine().search(query);
        
        // If TutorEngine returns an error or low-quality response, try fallback
        if (responseText.startsWith("Error:") || 
            responseText.startsWith("Sorry, I couldn't find") ||
            responseText.contains("not ready")) {
          // Fallback to OfflineChatService
          final fallbackResponse = await OfflineChatService.getResponse(query);
          responseText = fallbackResponse['message'] ?? responseText;
        }
      } else {
        // If TutorEngine is not ready, use OfflineChatService
        final fallbackResponse = await OfflineChatService.getResponse(query);
        responseText = fallbackResponse['message'] ?? "Sorry, I'm still loading. Please try again in a moment.";
      }
    } catch (e) {
      print("Error processing query: $e");
      // Final fallback
      try {
        final fallbackResponse = await OfflineChatService.getResponse(query);
        responseText = fallbackResponse['message'] ?? "Sorry, I encountered an error. Please try asking your question differently.";
      } catch (e2) {
        responseText = "Sorry, I'm having trouble right now. Please try again later or restart the app.";
      }
    }

    setState(() {
      _isTyping = false;
    });

    _addBotMessage(responseText);
    
    if (_isAutoSpeak) {
      VoiceService().speak(responseText);
    }
  }

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
    return Scaffold(
      backgroundColor: Colors.white, // Force Light Theme
      drawer: HistoryDrawer(
        onSessionSelected: (sessionId, type) {
          if (type == 'chat') {
            _loadHistory(sessionId);
          } else {
            // Handle scan history if needed, or navigate to scan screen
            // For now, we only handle chat history here.
            // Ideally, we should navigate to the appropriate screen.
            // But since we are in ChatScreen, let's just load chat.
            // If it's a scan, we might want to pop and push AiSolverScreen
            // But that requires access to context and routes.
            // Let's assume HistoryDrawer handles navigation or we handle it here.
            // For simplicity, let's just show a snackbar for now if it's not chat
            // OR better, navigate to AiSolverScreen with arguments.
            // Since I don't have named routes set up for arguments easily, 
            // I'll leave it as is for now, assuming user clicks chat items in chat screen.
            // Wait, the requirement says "return the sessionId to the parent screen".
            // If I am in ChatScreen and click a Scan item, I should probably go to Scan screen.
            // But let's stick to loading chat for now.
          }
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Iconsax.menu_1, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Text("AI GURU", style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text("Offline", style: GoogleFonts.outfit(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        actions: [
          IconButton(
            onPressed: _startNewChat,
            tooltip: 'New Chat',
            icon: const Icon(Iconsax.add_circle, color: Colors.black54),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _isAutoSpeak = !_isAutoSpeak;
              });
              if (!_isAutoSpeak) VoiceService().stopSpeaking();
            },
            icon: Icon(_isAutoSpeak ? Iconsax.volume_high : Iconsax.volume_cross, color: Colors.black54)
          ),
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.redAccent),
            tooltip: 'Debug DB',
            onPressed: _showDebugDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcomeScreen()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      final msg = _messages[index];
                      return _buildMessageBubble(msg);
                    },
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF4285F4), Color(0xFF9B72CB), Color(0xFFD96570)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                "Hello, $_userName",
                style: GoogleFonts.outfit(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Required for ShaderMask
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "How can I help you today?",
              style: GoogleFonts.outfit(
                fontSize: 24,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isUser = msg['role'] == 'user';
    final isLastBotMessage = !isUser && msg == _messages.last && !_isTyping;

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 24, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F9), // Soft Grey
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            msg['message'],
            style: GoogleFonts.outfit(color: Colors.black87, fontSize: 16, height: 1.5),
          ),
        ),
      );


    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24, right: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              child: const Icon(Iconsax.magic_star, color: Color(0xFF4285F4), size: 24), // Gemini Blue
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F9), // Subtle Grey/Blue
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: MarkdownBody(
                  data: msg['message'],
                  styleSheet: MarkdownStyleSheet(
                    // Paragraph styling
                    p: GoogleFonts.outfit(color: Colors.black87, fontSize: 16, height: 1.5),
                    // Headings
                    h1: GoogleFonts.outfit(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold, height: 1.3),
                    h2: GoogleFonts.outfit(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold, height: 1.3),
                    h3: GoogleFonts.outfit(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold, height: 1.3),
                    // Bold text
                    strong: GoogleFonts.outfit(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold, height: 1.5),
                    // Italic text
                    em: GoogleFonts.outfit(color: Colors.black87, fontSize: 16, fontStyle: FontStyle.italic, height: 1.5),
                    // Lists
                    listBullet: GoogleFonts.outfit(color: Colors.black87, fontSize: 16),
                    listIndent: 24.0,
                    // Code blocks
                    code: const TextStyle(color: Colors.black87, fontSize: 14, fontFamily: 'monospace'),
                    codeblockDecoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    codeblockPadding: const EdgeInsets.all(8),
                    // Block quotes
                    blockquote: GoogleFonts.outfit(color: Colors.grey[700], fontSize: 16, fontStyle: FontStyle.italic),
                    blockquoteDecoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border(left: BorderSide(color: Colors.blue, width: 3)),
                    ),
                    blockquotePadding: const EdgeInsets.all(8),
                    // Horizontal rule
                    horizontalRuleDecoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            child: const Icon(Iconsax.magic_star, color: Color(0xFF4285F4), size: 24),
          ),
          const SizedBox(width: 16),
          Text("Thinking...", style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F9), // Soft Grey Input
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: GoogleFonts.outfit(color: Colors.black87, fontSize: 16),
                decoration: InputDecoration(
                  hintText: "Ask anything...",
                  hintStyle: GoogleFonts.outfit(color: Colors.grey[500]),
                  border: InputBorder.none,
                ),
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    _addUserMessage(val.trim());
                    _controller.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onLongPressStart: (_) async {
                setState(() => _isListening = true);
                await VoiceService().startListening((text) {
                  setState(() {
                    _controller.text = text;
                  });
                });
              },
              onLongPressEnd: (_) async {
                setState(() => _isListening = false);
                await VoiceService().stopListening();
              },
              child: Icon(
                Iconsax.microphone, 
                color: _isListening ? Colors.redAccent : Colors.grey[600], 
                size: 24
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () {
                if (_controller.text.trim().isNotEmpty) {
                  _addUserMessage(_controller.text.trim());
                  _controller.clear();
                }
              },
              child: const Icon(Iconsax.send_1, color: Color(0xFF4285F4), size: 24),
            ),
          ],
        ),
      ),
    );
  }

  void _showDebugDialog() async {
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator())
    );

    final status = await TutorEngine().checkDatabaseStatus();
    Navigator.pop(context); // Pop loading

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Database Status"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Total BookChunks: ${status['count']}"),
                const SizedBox(height: 8),
                Text("Asset JSON Size: ${status['jsonSize']} bytes"),
                const SizedBox(height: 8),
                const Text("First 5 Chunks:", style: TextStyle(fontWeight: FontWeight.bold)),
                if (status['firstChunks'] != null)
                  ...(status['firstChunks'] as List).map((s) => Text("• $s")),
                
                if (status['status'] != 'OK')
                  Text("Error: ${status['status']}", style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
          actions: [
            if ((status['count'] ?? 0) == 0)
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Forcing Seed... Please wait."))
                  );
                  await TutorEngine().forceSeed();
                  if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Seed Complete. Check Log."))
                    );
                    _showDebugDialog(); // Re-open to verify
                  }
                },
                child: const Text("FORCE SEED", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      }
    );
  }
}
