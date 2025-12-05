import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class OfflineChatService {
  static Map<String, dynamic>? _syllabusData;
  static bool _isInitialized = false;

  // Initialize: Load JSON into memory
  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      final String response = await rootBundle.loadString('assets/ai/smart_syllabus.json');
      _syllabusData = json.decode(response);
      _isInitialized = true;
      print("🧠 Offline Chat Service Initialized");
    } catch (e) {
      print("❌ Error loading smart syllabus: $e");
    }
  }

  // Main Entry Point: Get Response
  static Future<Map<String, dynamic>> getResponse(String query) async {
    if (!_isInitialized) await init();

    query = query.toLowerCase();
    
    // 1. Detect Intent
    if (query.contains("roadmap") || query.contains("path") || query.contains("guide")) {
      return _generateRoadmapResponse(query);
    } else if (query.contains("pdf") || query.contains("document") || query.contains("file")) {
      return await _generateDocumentResponse(query);
    } else if (query.contains("quiz") || query.contains("test")) {
      return _generateQuizResponse(query);
    } else if (query.contains("image") || query.contains("diagram") || query.contains("picture") || query.contains("photo")) {
      return _generateImageResponse(query);
    } else {
      return _generateExplanationResponse(query);
    }
  }

  // --- Logic Helpers ---

  static Map<String, dynamic> _generateImageResponse(String query) {
    final topic = _findTopic(query);
    if (topic == null) {
      return {
        "type": "text",
        "message": "I couldn't find a diagram for that topic. Try 'Image of Food'."
      };
    }

    return {
      "type": "image",
      "message": "Here is a visual aid for **${topic['title']}**:",
      "data": {
        "title": topic['title'],
        "desc": topic['desc'],
        "icon": topic['icon'] ?? "image"
      }
    };
  }

  static Map<String, dynamic> _generateRoadmapResponse(String query) {
    final topic = _findTopic(query);
    if (topic == null) {
      return {
        "type": "text",
        "message": "I couldn't find a roadmap for that topic. \n\n**Try asking about:**\n- Food\n- Magnets\n- Gravitation\n- Plants\n\nExample: 'Roadmap for Gravitation'"
      };
    }

    // Procedural Generation of Roadmap
    final steps = [
      {"title": "Watch Video", "desc": "Start with the visual explanation.", "icon": "video", "status": "pending"},
      {"title": "Read Notes", "desc": "Go through the key concepts.", "icon": "book", "status": "locked"},
      {"title": "Take Quiz", "desc": "Test your knowledge.", "icon": "quiz", "status": "locked"},
    ];

    return {
      "type": "roadmap",
      "message": "Here is your personalized learning path for ${topic['title']}:",
      "data": {
        "title": topic['title'],
        "steps": steps
      }
    };
  }

  static Future<Map<String, dynamic>> _generateDocumentResponse(String query) async {
    final topic = _findTopic(query);
    if (topic == null) {
      return {
        "type": "text",
        "message": "I couldn't find content to generate a PDF for. Try 'PDF for Components of Food'."
      };
    }

    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(topic['title'], style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 20),
                  pw.Text(topic['desc']),
                  pw.SizedBox(height: 20),
                  pw.Text(topic['notes'] ?? "No notes available."),
                ]
              )
            );
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/${topic['id']}.pdf");
      await file.writeAsBytes(await pdf.save());

      return {
        "type": "file",
        "message": "I've generated a study guide for you. You can open it below.",
        "data": {
          "path": file.path,
          "filename": "${topic['title']}.pdf"
        }
      };
    } catch (e) {
      return {
        "type": "text",
        "message": "Sorry, I encountered an error generating the PDF."
      };
    }
  }

  static Map<String, dynamic> _generateQuizResponse(String query) {
    final topic = _findTopic(query);
    if (topic == null || topic['smart_content'] == null || topic['smart_content']['quiz'] == null) {
      return {
        "type": "text",
        "message": "I don't have a quiz ready for that topic yet."
      };
    }

    final List quizzes = topic['smart_content']['quiz'];
    if (quizzes.isEmpty) {
       return {
        "type": "text",
        "message": "No questions found for this chapter."
      };
    }

    // Return first 3 questions
    return {
      "type": "quiz",
      "message": "Ready to test your knowledge? Here's a quick quiz on ${topic['title']}.",
      "data": quizzes.take(3).toList()
    };
  }

  static Map<String, dynamic> _generateExplanationResponse(String query) {
    // First check for common educational topics not in syllabus
    final commonAnswers = _getCommonKnowledgeAnswer(query);
    if (commonAnswers != null) {
      return {
        "type": "text",
        "message": commonAnswers
      };
    }

    final topic = _findTopic(query);
    if (topic == null) {
      return {
        "type": "text",
        "message": "I'm not sure about that topic. Try asking about:\n\n• Topics from your syllabus\n• Specific chapters you're studying\n• Or rephrase your question\n\nExample: 'What is Photosynthesis?' or 'Explain Food Chain'"
      };
    }

    final summary = topic['smart_content']?['summary'] ?? topic['desc'];
    return {
      "type": "text",
      "message": "**${topic['title']}**\n\n$summary\n\n*Would you like a roadmap or a quiz for this?*"
    };
  }

  // Common knowledge answers for frequently asked questions
  static String? _getCommonKnowledgeAnswer(String query) {
    final q = query.toLowerCase();
    
    if (q.contains('pollination') || q.contains('pollinate')) {
      return """**What is Pollination?**

Pollination is the process by which pollen grains are transferred from the male part (anther) of a flower to the female part (stigma) of the same or another flower. This is essential for the reproduction of flowering plants.

**Types of Pollination:**
1. **Self-pollination**: Pollen from the same flower or plant
2. **Cross-pollination**: Pollen from a different plant

**Pollination Agents:**
- **Wind**: Light pollen grains carried by wind
- **Insects**: Bees, butterflies, and other insects
- **Birds**: Hummingbirds and other birds
- **Water**: For some aquatic plants

**Importance:**
Pollination helps plants produce fruits and seeds, which is crucial for:
- Plant reproduction
- Food production
- Ecosystem balance
- Biodiversity

Would you like to know more about any specific type of pollination?""";
    }
    
    if (q.contains('photosynthesis')) {
      return """**What is Photosynthesis?**

Photosynthesis is the process by which plants make their own food using sunlight, water, and carbon dioxide. It occurs mainly in the leaves.

**Process:**
- Plants take in **carbon dioxide** from air
- They absorb **water** from roots
- **Sunlight** provides energy
- **Chlorophyll** (green pigment) captures light
- Plants produce **glucose** (sugar) and release **oxygen**

**Equation:**
Carbon Dioxide + Water + Sunlight → Glucose + Oxygen

**Importance:**
- Produces food for plants
- Releases oxygen we breathe
- Maintains balance of gases in atmosphere""";
    }
    
    if (q.contains('food chain') || q.contains('food web')) {
      return """**Food Chain and Food Web**

A **food chain** shows how energy flows from one organism to another. It starts with producers (plants) and goes to consumers (animals).

**Example:**
Grass → Rabbit → Snake → Eagle

**Food Web** is a network of interconnected food chains showing complex feeding relationships in an ecosystem.

**Components:**
- **Producers**: Plants (make their own food)
- **Primary Consumers**: Herbivores (eat plants)
- **Secondary Consumers**: Carnivores (eat herbivores)
- **Decomposers**: Break down dead matter""";
    }
    
    return null;
  }

  // --- Search Engine ---
  static Map<String, dynamic>? _findTopic(String query) {
    if (_syllabusData == null) return null;

    // 1. Clean Query - improved stop words
    final stopWords = ['roadmap', 'for', 'give', 'me', 'the', 'chapter', 'about', 'explain', 'pdf', 'image', 'diagram', 'quiz', 'notes', 'of', 'to', 'learn', 'what', 'is', 'are', 'how', 'why', 'when', 'where', 'which', 'who'];
    final words = query.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ') // Remove punctuation
        .split(' ')
        .where((w) => !stopWords.contains(w) && w.length > 2)
        .toList();

    if (words.isEmpty) return null;

    // 2. Search with improved matching
    Map<String, dynamic>? bestMatch;
    int bestScore = 0;

    for (var classKey in _syllabusData!.keys) {
      final subjects = _syllabusData![classKey]['subjects'] as List;
      for (var subject in subjects) {
        final chapters = subject['chapters'] as List;
        for (var chapter in chapters) {
          final title = chapter['title'].toString().toLowerCase();
          final desc = chapter['desc'].toString().toLowerCase();
          final notes = chapter['notes']?.toString().toLowerCase() ?? '';
          
          int score = 0;
          
          // Check if ANY significant word matches (Fuzzy)
          for (var word in words) {
            // Exact match in title gets highest score
            if (title == word || title.contains(' $word ') || title.startsWith('$word ') || title.endsWith(' $word')) {
              score += 10;
            } else if (title.contains(word)) {
              score += 5;
            }
            
            // Match in description
            if (desc.contains(word)) {
              score += 3;
            }
            
            // Match in notes
            if (notes.contains(word)) {
              score += 2;
            }
          }
          
          if (score > bestScore) {
            bestScore = score;
            bestMatch = chapter;
          }
        }
      }
    }
    
    // Return match if score is reasonable
    return bestScore > 0 ? bestMatch : null;
  }
}
