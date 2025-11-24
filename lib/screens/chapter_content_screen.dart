import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:video_player/video_player.dart'; // Native Player (Cloud)
import 'package:chewie/chewie.dart'; // UI for Native Player
import 'package:youtube_player_flutter/youtube_player_flutter.dart'; // YouTube Backup
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:eduthon/services/syllabus_service.dart'; 
import 'package:eduthon/screens/ai_solver_screen.dart'; 

class ChapterContentScreen extends StatefulWidget {
  final String chapterId;
  final String chapterName;
  final String videoId; // Ye variable ab URL ya ID dono ho sakta hai
  final String notesMarkdown;
  final Color color;

  const ChapterContentScreen({
    super.key,
    required this.chapterId,
    required this.chapterName,
    required this.videoId, // Purana naam rakha hai taaki baki files me error na aaye
    required this.notesMarkdown,
    required this.color,
  });

  @override
  State<ChapterContentScreen> createState() => _ChapterContentScreenState();
}

class _ChapterContentScreenState extends State<ChapterContentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Players
  VideoPlayerController? _cloudVideoController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubeController;
  
  bool _isYoutube = false;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializePlayer();
  }

  // --- SMART PLAYER LOGIC ---
  Future<void> _initializePlayer() async {
    // Check karo: Kya ye poora URL hai? (http...)
    if (widget.videoId.startsWith('http')) {
      _isYoutube = false;
      await _initCloudPlayer();
    } else {
      // Agar nahi, toh ye YouTube ID hai
      _isYoutube = true;
      _initYoutube();
    }
  }

  // 1. Cloud Player Init
  Future<void> _initCloudPlayer() async {
    try {
      _cloudVideoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoId));
      await _cloudVideoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _cloudVideoController!,
        autoPlay: false,
        looping: false,
        aspectRatio: 16 / 9,
        materialProgressColors: ChewieProgressColors(
          playedColor: widget.color,
          handleColor: widget.color,
          backgroundColor: Colors.grey,
          bufferedColor: widget.color.withOpacity(0.3),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(child: Text("Error: $errorMessage", style: const TextStyle(color: Colors.white)));
        },
      );

      // Resume Logic
      double savedSeconds = await SyllabusService().getProgress(widget.chapterId);
      if (savedSeconds > 5.0) {
        _cloudVideoController!.seekTo(Duration(seconds: savedSeconds.toInt()));
      }

      if (mounted) setState(() => _isPlayerReady = true);
    } catch (e) {
      print("Cloud Player Error: $e");
    }
  }

  // 2. YouTube Player Init
  void _initYoutube() {
    _youtubeController = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(autoPlay: false, enableCaption: true),
    );
    
    // Resume Logic YouTube ke liye abhi simple rakha hai
    // Future enhancement: Use seekTo() here too
    
    if (mounted) setState(() => _isPlayerReady = true);
  }

  @override
  void deactivate() {
    _saveProgress();
    _cloudVideoController?.pause();
    _youtubeController?.pause();
    super.deactivate();
  }

  // Save only for Cloud Player (Reliable)
  void _saveProgress() {
    if (!_isYoutube && _cloudVideoController != null && _cloudVideoController!.value.isInitialized) {
      Duration pos = _cloudVideoController!.value.position;
      if (pos.inSeconds > 5) {
        SyllabusService().saveProgress(widget.chapterId, pos.inSeconds.toDouble());
      }
    }
  }

  @override
  void dispose() {
    _cloudVideoController?.dispose();
    _chewieController?.dispose();
    _youtubeController?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.chapterName, style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: widget.color,
          indicatorColor: widget.color,
          unselectedLabelColor: Colors.grey,
          tabs: const [Tab(text: "Video Class"), Tab(text: "Smart Notes")],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: widget.color,
        icon: const Icon(Iconsax.message_question, color: Colors.white),
        label: Text("Ask AI Doubt", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiSolverScreen())),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          // --- TAB 1: DUAL MODE VIDEO PLAYER ---
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 240, 
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _isPlayerReady
                        ? (_isYoutube 
                            ? YoutubePlayer(controller: _youtubeController!) // YouTube Mode
                            : Chewie(controller: _chewieController!))        // Cloud Mode
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mode Badge
                      if (!_isYoutube)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Iconsax.cloud_connection, size: 14, color: Colors.green),
                              const SizedBox(width: 6),
                              Text("EduLok Cloud • Low Data Mode", style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),
                      
                      Text("Chapter Overview", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        "This video covers the core concepts of ${widget.chapterName}. Your progress is tracked automatically.",
                        style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7), height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),

          // --- TAB 2: NOTES (Same as before) ---
          Markdown(
            data: widget.notesMarkdown,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
            styleSheet: MarkdownStyleSheet(
              h1: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
              h2: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: widget.color),
              p: GoogleFonts.poppins(fontSize: 15, height: 1.6, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8)),
              listBullet: TextStyle(color: widget.color, fontSize: 16),
              blockquoteDecoration: BoxDecoration(
                color: isDark ? Theme.of(context).cardColor : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border(left: BorderSide(color: widget.color, width: 4)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}