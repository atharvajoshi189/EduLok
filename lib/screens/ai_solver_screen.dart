import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eduthon/services/offline_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:eduthon/services/language_service.dart';
import 'package:eduthon/services/history_service.dart';
import 'package:eduthon/widgets/history_drawer.dart';

class AiSolverScreen extends StatefulWidget {
  final String? initialSessionId;
  const AiSolverScreen({super.key, this.initialSessionId});

  @override
  State<AiSolverScreen> createState() => _AiSolverScreenState();
}

class _AiSolverScreenState extends State<AiSolverScreen> {
  String? _imagePath;
  String? _extractedText;
  String? _solution;
  bool _isLoading = false;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    if (widget.initialSessionId != null) {
      _loadHistory(widget.initialSessionId!);
    }
  }

  Future<void> _loadHistory(String sessionId) async {
    final messages = await HistoryService().getMessages(sessionId);
    if (messages.isNotEmpty) {
      final msg = messages.first; // Scan session has 1 message usually
      setState(() {
        _sessionId = sessionId;
        _extractedText = msg['content']; // We store question in content? Or solution?
        // Wait, the schema says: content (String), image_path (String).
        // For scan, we probably stored solution in content.
        // Let's assume content is solution, but we also need extracted text.
        // The current schema doesn't have a separate field for extracted text.
        // Maybe we can store extracted text in content, and solution in a second message?
        // Or store "Question: ... \n\n Solution: ..." in content.
        // Let's check how I plan to save it.
        
        // Plan: "Save Scan Results: ... save Image Path + Answer."
        // So content = Answer (Solution).
        // Where is extracted text?
        // Maybe I should append it to the answer or just rely on the image.
        // Let's store solution in content.
        _solution = msg['content'];
        _imagePath = msg['image_path'];
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);

      if (pickedFile != null) {
        _cropImage(pickedFile.path);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _cropImage(String path) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Question',
          toolbarColor: const Color(0xFF2554A3),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Question',
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _imagePath = croppedFile.path;
        _extractedText = null;
        _solution = null;
        _isLoading = true;
        _sessionId = null; // Reset session for new scan
      });
      _processImage(croppedFile.path);
    }
  }

  Future<void> _processImage(String path) async {
    try {
      // 1. Perform OCR
      final text = await OfflineService().performOCR(path);
      
      if (text.isEmpty) {
        setState(() {
          _isLoading = false;
          _extractedText = "Could not extract text. Please try again.";
        });
        return;
      }

      setState(() {
        _extractedText = text;
      });

      // 2. Solve Offline
      final solution = await OfflineService().solveOfflineDoubt(text);

      setState(() {
        _isLoading = false;
        _solution = solution;
      });

      // 3. Save to History
      await _saveToHistory(path, text, solution);

    } catch (e) {
      setState(() {
        _isLoading = false;
        _solution = "Error: $e";
      });
    }
  }

  Future<void> _saveToHistory(String imagePath, String question, String solution) async {
    // Title: "Scan: [Date]" or "Scan: [First few words of question]"
    String title = "Scan: ${question.length > 20 ? question.substring(0, 20) + '...' : question}";
    
    _sessionId = await HistoryService().createSession(title, 'scan');
    
    // We save the solution as content. We could prepend the question if we want.
    // Let's save: "Question: $question\n\nSolution:\n$solution"
    String content = "Question: $question\n\n$solution";
    
    await HistoryService().addMessage(_sessionId!, 'bot', content, imagePath: imagePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: HistoryDrawer(
        onSessionSelected: (sessionId, type) {
          if (type == 'scan') {
            _loadHistory(sessionId);
          } else {
            // Handle chat history if needed
          }
        },
      ),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.translate('aiDoubtSolver') ?? "AI Doubt Solver", 
          style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Iconsax.menu_1, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _imagePath == null 
          ? _buildPlaceholder()
          : _buildResultView(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickImage,
        backgroundColor: const Color(0xFF2554A3),
        icon: const Icon(Iconsax.camera),
        label: Text("Scan New", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF2554A3).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.camera, size: 60, color: Color(0xFF2554A3)),
          ),
          const SizedBox(height: 20),
          Text(
            "Tap Camera to Scan",
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            "Get instant offline solutions",
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Image Card
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: FileImage(File(_imagePath!)),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
              ]
            ),
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            // 2. Extracted Question Card (Only show if we have extracted text separately or parsed from content)
            if (_extractedText != null)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200)
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Iconsax.text_block, size: 18, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text("Extracted Question", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _extractedText ?? "...",
                      style: GoogleFonts.outfit(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Solution Card
            Card(
              elevation: 4,
              shadowColor: const Color(0xFF2554A3).withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Iconsax.magic_star, color: Color(0xFF2554A3)),
                        const SizedBox(width: 10),
                        Text("Solution", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2554A3))),
                      ],
                    ),
                    const Divider(height: 24),
                    if (_solution != null && _solution!.startsWith("Offline Solution"))
                      Text(
                        _solution!,
                        style: GoogleFonts.outfit(fontSize: 16, color: Colors.black87, height: 1.5),
                      )
                    else
                      TeXView(
                        child: TeXViewColumn(children: [
                          TeXViewDocument(_solution ?? "No solution found.", 
                            style: TeXViewStyle(
                              fontStyle: TeXViewFontStyle(fontFamily: 'Outfit', fontSize: 16),
                              contentColor: Colors.black87
                            )
                          )
                        ]),
                        style: const TeXViewStyle(
                          elevation: 0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80), // Space for FAB
          ]
        ],
      ),
    );
  }
}
