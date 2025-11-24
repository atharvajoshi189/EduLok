import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:eduthon/models/text_chunk.dart';
import 'package:eduthon/objectbox.g.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  late Store _store;
  late Box<TextChunk> _box;
  bool _isReady = false;

  // AI Assets
  Interpreter? _interpreter;
  Map<String, List<dynamic>>? _wordMap;
  
  // Constants
  static const int MAX_SEQ_LENGTH = 128;

  Future<void> init() async {
    if (_isReady) return;
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final dbPath = join(docsDir.path, "edulok_db");
      
      // DEV MODE: Always clear DB to load fresh JSONs
      // In production, we would check versioning.
      try {
        if (Directory(dbPath).existsSync()) {
          Directory(dbPath).deleteSync(recursive: true);
        }
      } catch (e) {
        print("Error clearing DB: $e");
      }

      _store = await openStore(directory: dbPath);
      _box = _store.box<TextChunk>();

      // 1. Load Word Map (Vocabulary)
      final wordMapString = await rootBundle.loadString('assets/ai/word_map.json');
      _wordMap = Map<String, List<dynamic>>.from(json.decode(wordMapString));

      // 2. Load TFLite Model
      _interpreter = await Interpreter.fromAsset('assets/ai/LaBSE.tflite');

      // 3. Load Knowledge Base (Vectors)
      if (_box.isEmpty()) {
        print("Loading Knowledge Base...");
        final jsonString = await rootBundle.loadString('assets/ai/vectors.json');
        final List<dynamic> rawData = json.decode(jsonString);
        
        List<TextChunk> chunks = rawData.map((item) {
           return TextChunk(
             text: item['text'] ?? "", 
             metadata: "Textbook",
             vector: List<double>.from(item['vector'] ?? [])
           );
        }).toList();
        
        _box.putMany(chunks);
        print("Knowledge Base Loaded: ${chunks.length} chunks.");
      }
      
      _isReady = true;
      print("🧠 AI Service Ready!");
    } catch (e) {
      print("AI Init Error: $e");
    }
  }

  Future<String> askEduLok(String userQuery) async {
    if (!_isReady) return "My brain is still waking up... please wait!";
    
    try {
      print("AI Query: $userQuery");
      
      // 0. Greeting & Small Talk Check
      String cleanQuery = userQuery.trim().toLowerCase();
      
      if (_isGreeting(cleanQuery)) {
        return "Hello! I'm ready to help. Ask me about Gravity, Atoms, or anything in your syllabus!";
      }
      
      String? smallTalkResponse = _handleSmallTalk(cleanQuery);
      if (smallTalkResponse != null) {
        return smallTalkResponse;
      }

      List<Map<String, dynamic>> candidates = [];

      // --- STRATEGY A: VECTOR SEARCH (Semantic) ---
      // Only works if we have real vectors. Currently we might have random ones for testing.
      final queryVector = _encode(userQuery);
      final allChunks = _box.getAll();

      if (queryVector != null) {
        for (var chunk in allChunks) {
          if (chunk.vector == null || chunk.vector!.isEmpty) continue;
          double score = _cosineSimilarity(queryVector, chunk.vector!);
          if (score > 0.6) { // High threshold for "Exact Semantic Match"
            candidates.add({'chunk': chunk, 'score': score, 'method': 'vector'});
          }
        }
      }

      // --- STRATEGY B: KEYWORD SEARCH (Fallback) ---
      // If Vector search gave few/no results, use Keywords
      if (candidates.isEmpty) {
        print("Vector search failed/low confidence. Switching to Keywords.");
        List<String> keywords = cleanQuery.split(' ').where((w) => w.length > 3).toList();
        
        for (var chunk in allChunks) {
          int matches = 0;
          String textLower = chunk.text.toLowerCase();
          
          for (var k in keywords) {
            if (textLower.contains(k)) matches++;
          }
          
          if (matches > 0) {
            // Simple scoring: matches * 10
            candidates.add({'chunk': chunk, 'score': matches * 10.0, 'method': 'keyword'});
          }
        }
      }

      // 3. Sort & Select
      candidates.sort((a, b) => b['score'].compareTo(a['score']));

      if (candidates.isNotEmpty) {
        final bestMatch = candidates[0]['chunk'] as TextChunk;
        return _generateConversationalAnswer(userQuery, bestMatch.text);
      } else {
        return "I looked through all your books, but I couldn't find a clear answer for '$userQuery'. Try asking with a specific chapter name.";
      }

    } catch (e) {
      print("Inference Error: $e");
      return "I ran into a problem thinking about that. Please try again.";
    }
  }

  String _generateConversationalAnswer(String query, String rawText) {
    // 1. Clean Text
    String clean = rawText.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // 2. Extract "Direct Answer" (Sentence containing keywords)
    List<String> sentences = clean.split(RegExp(r'(?<=[.!?])\s+'));
    String bestSentence = "";
    int maxMatches = 0;
    
    List<String> queryWords = query.toLowerCase().split(' ').where((w) => w.length > 3).toList();
    
    for (var s in sentences) {
      int matches = 0;
      for (var w in queryWords) {
        if (s.toLowerCase().contains(w)) matches++;
      }
      if (matches > maxMatches) {
        maxMatches = matches;
        bestSentence = s;
      }
    }
    
    // If no good sentence found, use the first one
    if (bestSentence.isEmpty && sentences.isNotEmpty) {
      bestSentence = sentences[0];
    }

    // 3. Format
    return "💡 **Direct Answer**:\n$bestSentence\n\n"
           "📖 **Detailed Explanation**:\n$clean\n\n"
           "Is this what you were looking for?";
  }
  
  bool _isGreeting(String text) {
    final greetings = ['hi', 'hello', 'hey', 'greetings', 'namaste'];
    for (var g in greetings) {
      if (text.contains(g)) return true;
    }
    return false;
  }

  String? _handleSmallTalk(String text) {
    if (text.contains('thank')) return "You're welcome! Happy to help. 📚";
    if (text.contains('goodbye') || text.contains('bye')) return "Goodbye! Keep studying hard! 👋";
    if (text.contains('who are you')) return "I am EduLok AI, your offline study companion.";
    if (text.contains('help')) return "I can explain topics from your textbooks. Try asking 'What is Photosynthesis?'.";
    return null;
  }

  // --- HELPER: Tokenization (Word Map) ---
  List<int> _tokenize(String text) {
    List<int> tokens = [101]; // [CLS]
    
    // Normalize
    String cleanText = text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '');
    List<String> words = cleanText.split(' ');

    for (var word in words) {
      if (_wordMap!.containsKey(word)) {
        // Cast dynamic list to int list
        List<int> ids = List<int>.from(_wordMap![word]!);
        tokens.addAll(ids);
      } else {
        tokens.add(100); // [UNK]
      }
    }

    tokens.add(102); // [SEP]

    // Pad / Truncate
    if (tokens.length > MAX_SEQ_LENGTH) {
      tokens = tokens.sublist(0, MAX_SEQ_LENGTH);
    } else {
      tokens.addAll(List.filled(MAX_SEQ_LENGTH - tokens.length, 0));
    }

    return tokens;
  }

  // --- HELPER: Encoding (TFLite) ---
  List<double>? _encode(String text) {
    if (_interpreter == null) return null;

    // 1. Prepare Inputs
    List<int> inputIds = _tokenize(text);
    List<int> attentionMask = inputIds.map((id) => id == 0 ? 0 : 1).toList();

    // Reshape for TFLite [1, 128]
    var inputIdsTensor = [inputIds];
    var attentionMaskTensor = [attentionMask];

    // 2. Run Inference
    // Output shape for LaBSE [CLS] is [1, 768]
    var outputBuffer = List.filled(1 * 768, 0.0).reshape([1, 768]);
    
    // Map inputs to outputs (Indices depend on model, usually 0 and 1)
    // We'll try passing map if list fails, but list is standard for single-sig
    try {
      _interpreter!.runForMultipleInputs(
        [inputIdsTensor, attentionMaskTensor], 
        {0: outputBuffer}
      );
    } catch (e) {
      // Fallback if inputs are swapped
      _interpreter!.runForMultipleInputs(
        [attentionMaskTensor, inputIdsTensor], 
        {0: outputBuffer}
      );
    }

    return List<double>.from(outputBuffer[0]);
  }

  // --- HELPER: Math ---
  double _cosineSimilarity(List<double> v1, List<double> v2) {
    double dot = 0.0;
    double mag1 = 0.0;
    double mag2 = 0.0;

    for (int i = 0; i < v1.length; i++) {
      dot += v1[i] * v2[i];
      mag1 += v1[i] * v1[i];
      mag2 += v2[i] * v2[i];
    }

    if (mag1 == 0 || mag2 == 0) return 0.0;
    return dot / (sqrt(mag1) * sqrt(mag2));
  }

  String _formatResponse(String rawText) {
    // Simple cleanup
    String clean = rawText.replaceAll(RegExp(r'\s+'), ' ').trim();
    return "Here is what I found:\n\n$clean\n\nDoes this help explain it?";
  }
}