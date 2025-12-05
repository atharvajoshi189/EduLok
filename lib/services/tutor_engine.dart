import 'dart:convert';
import 'dart:math' as Math;
import 'dart:io';
import 'dart:typed_data'; // Added typed_data import
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';
import '../models/book_chunk.dart';
import '../objectbox.g.dart';

class TutorEngine {
  static final TutorEngine instance = TutorEngine._internal();
  factory TutorEngine() => instance;
  TutorEngine._internal();

  late Store _store;
  late Box<BookChunk> _box;
  late Interpreter _interpreter;
  
  // Internal Vocab Map (No external tokenizer needed)
  Map<String, int> _vocab = {};

  bool isInitialized = false;
  
  // Memory/Context: Store last query for follow-up questions
  String? _lastQuery;

  Future<void> init() async {
    if (isInitialized) return;
    try {
      print("Initializing TutorEngine...");
      
      // 1. Load ObjectBox
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        _store = await openStore(directory: '${docsDir.path}/tutor_db');
        _box = _store.box<BookChunk>();
        print("ObjectBox loaded successfully");
      } catch (e) {
        print("ObjectBox init error: $e");
        throw Exception("Failed to initialize database: $e");
      }

      // 2. Load TFLite
      try {
        final options = InterpreterOptions()..threads = 2;
        _interpreter = await Interpreter.fromAsset('assets/ai/model_quant.tflite', options: options);
        print("TFLite model loaded successfully");
      } catch (e) {
        print("TFLite init error: $e");
        throw Exception("Failed to load AI model: $e");
      }

      // 3. Load Vocab for Internal Tokenizer
      try {
        final vocabString = await rootBundle.loadString('assets/ai/vocab.txt');
        final lines = vocabString.split('\n');
        for (int i = 0; i < lines.length; i++) {
          final word = lines[i].trim();
          if (word.isNotEmpty) {
            _vocab[word] = i;
          }
        }
        print("Vocab loaded: ${_vocab.length} words");
      } catch (e) {
        print("Vocab load error: $e");
        throw Exception("Failed to load vocabulary: $e");
      }

      // 4. Seed if empty (Ensuring DB validity)
      try {
        if (_box.isEmpty()) {
          print("Database is empty, seeding...");
          await _seedDatabase();
        } else {
          print("Database already has ${_box.count()} chunks");
        }
      } catch (e) {
        print("Seeding error: $e");
        // Don't fail initialization if seeding fails, but log it
      }
      
      isInitialized = true;
      print("✅ TutorEngine Ready. Vocab size: ${_vocab.length}, Chunks: ${_box.count()}");
    } catch (e, stackTrace) {
      print("❌ TutorEngine Init Error: $e");
      print("Stack trace: $stackTrace");
      isInitialized = false;
      // Don't rethrow, let search() handle the error gracefully
    }
  }

  // --- INTERNAL CRASH-PROOF TOKENIZER ---
  List<int> _simpleTokenize(String text) {
    // Use a Growable List [] explicitly
    List<int> tokens = [];
    
    // 1. CLS Token
    tokens.add(101); 

    // 2. Simple Split & Map
    // Remove punctuation and split
    String cleanText = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    List<String> words = cleanText.split(' ');

    for (var word in words) {
      if (word.trim().isEmpty) continue;
      if (_vocab.containsKey(word)) {
        tokens.add(_vocab[word]!);
      } else {
        tokens.add(100); // UNK token
      }
    }

    // 3. SEP Token
    tokens.add(102); 

    return tokens;
  }

  Future<String> search(String query) async {
    try {
      if (!isInitialized) {
        print("Model not ready. Waiting...");
        await init(); // Force wait
        if (!isInitialized) {
          return "Sorry, I'm still loading. Please try again in a moment.";
        }
      }

      // Check if resources are properly initialized
      if (!isInitialized || _vocab.isEmpty) {
        return "Sorry, the AI model is not ready yet. Please restart the app.";
      }

      // Check for Follow-up Questions
      final queryLower = query.toLowerCase();
      final isFollowUp = _lastQuery != null && (
        queryLower.contains('detail') || 
        queryLower.contains('more') || 
        queryLower.contains('explain') || 
        queryLower.contains('aur') || 
        queryLower.contains('dobara') ||
        queryLower.contains('further') ||
        queryLower.contains('elaborate')
      );

      // Use last query for follow-ups, otherwise use current query
      final searchQuery = isFollowUp ? _lastQuery! : query;
      
      // Update _lastQuery for new queries (not follow-ups)
      if (!isFollowUp) {
        _lastQuery = query;
      }

      // STEP 1: Tokenize (Using internal safe function)
      List<int> tokens = _simpleTokenize(searchQuery);

      // STEP 2: Pad to 128 (Using standard list logic)
      while (tokens.length < 128) {
        tokens.add(0);
      }
      if (tokens.length > 128) {
        tokens = tokens.sublist(0, 128);
      }

      // STEP 3: Inference with Strict Typed Buffers
      // Convert proper Int32 input
      var input = Int32List.fromList(tokens).reshape([1, 128]);
      
      // Output buffer Float32
      var output = Float32List(1 * 384).reshape([1, 384]);
      
      // Check interpreter before using
      try {
        if (_interpreter.address == 0) {
          throw Exception("Interpreter is closed or invalid.");
        }
        
        _interpreter.run(input, output);
        List<double> queryVector = List<double>.from(output[0]);

        // STEP 4: Manual Search
        List<BookChunk> allChunks = _box.getAll();
        
        if (allChunks.isEmpty) {
          return "Sorry, I don't have enough information about that topic yet. Try asking about topics from your syllabus.";
        }
        
        // Collect top chunks with scores
        List<MapEntry<BookChunk, double>> scoredChunks = [];
        
        for (var chunk in allChunks) {
          if (chunk.vector.isEmpty) continue; // Skip chunks with empty vectors
          double score = _cosineSimilarity(queryVector, chunk.vector);
          scoredChunks.add(MapEntry(chunk, score));
        }

        // Sort by score (descending)
        scoredChunks.sort((a, b) => b.value.compareTo(a.value));

        // For follow-ups, return top 3 chunks combined
        if (isFollowUp && scoredChunks.isNotEmpty) {
          final topChunks = scoredChunks.take(3).where((e) => e.value > 0.25).toList();
          if (topChunks.isEmpty) {
            return "Sorry, I couldn't find more detailed information about '$_lastQuery'. Try asking a different question.";
          }
          
          String combinedText = topChunks.map((e) => e.key.text).join('\n\n');
          return "Here is a detailed explanation for '$_lastQuery':\n\n$combinedText";
        }

        // For normal queries, use best sentence extraction
        if (scoredChunks.isNotEmpty && scoredChunks.first.value > 0.25) {
          final bestChunk = scoredChunks.first.key;
          return _generateResponse(query, bestChunk.text);
        } else {
          final bestScore = scoredChunks.isNotEmpty ? scoredChunks.first.value : -1.0;
          return "Sorry, I couldn't find detailed information about that topic. (Match score: ${bestScore.toStringAsFixed(2)})\n\nTry asking about:\n- Topics from your syllabus\n- Specific chapters you're studying\n- Or rephrase your question";
        }
      } catch (e) {
        print("Interpreter error: $e");
        return "Sorry, there was an issue processing your question. Please try again.";
      }

    } catch (e, stackTrace) {
      print("Search error: $e");
      print("Stack trace: $stackTrace");
      return "Sorry, I encountered an error. Please try asking your question differently or restart the app.";
    }
  }

  double _cosineSimilarity(List<double> A, List<double> B) {
    double dot = 0.0, magA = 0.0, magB = 0.0;
    for (int i = 0; i < A.length; i++) {
      dot += A[i] * B[i];
      magA += A[i] * A[i];
      magB += B[i] * B[i];
    }
    return dot / ((Math.sqrt(magA) * Math.sqrt(magB)) + 0.000001);
  }

  // --- ANSWER SPECIFICITY: Best Sentence First ---
  String _generateResponse(String query, String retrievedText) {
    // Extract keywords from query
    final queryWords = query.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(' ')
        .where((w) => w.length > 2)
        .where((w) => !['what', 'is', 'are', 'the', 'how', 'why', 'when', 'where', 'which', 'who', 'does', 'do', 'can', 'could', 'would', 'should'].contains(w))
        .toList();

    // Split text into sentences
    final sentences = retrievedText
        .split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 10)
        .toList();

    if (sentences.isEmpty) {
      return retrievedText; // Return as-is if no sentences found
    }

    // Find best sentence (contains most keywords)
    String? bestSentence;
    int bestScore = -1;

    for (var sentence in sentences) {
      final sentenceLower = sentence.toLowerCase();
      int score = 0;
      for (var word in queryWords) {
        if (sentenceLower.contains(word)) {
          score += 1;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestSentence = sentence;
      }
    }

    // If no sentence matches keywords well, use first sentence
    if (bestSentence == null || bestScore == 0) {
      bestSentence = sentences.first;
    }

    // Get remaining text (excluding best sentence)
    final remainingText = retrievedText
        .replaceFirst(bestSentence, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Format output
    if (remainingText.isEmpty || remainingText == bestSentence) {
      return "**Direct Answer:**\n$bestSentence.";
    } else {
      return "**Direct Answer:**\n$bestSentence.\n\n**Full Context:**\n$remainingText";
    }
  }

  // --- RESTORED HELPER METHODS FOR CHATSCREEN COMPATIBILITY ---
  
  Future<void> _seedDatabase() async {
    print("Seeding database from initial_data.json...");
    try {
      final jsonString = await rootBundle.loadString('assets/data/initial_data.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      
      final List<BookChunk> chunks = [];
      
      for (var item in jsonData) {
        int classNum = 0;
        if (item['classNum'] is int) {
          classNum = item['classNum'];
        } else if (item['classNum'] is String) {
          classNum = int.tryParse(item['classNum']) ?? 0;
        }

        List<double> vector = [];
        if (item['vector'] != null) {
          vector = List<double>.from(item['vector']);
        }

        chunks.add(BookChunk(
          classNum: classNum,
          subject: item['subject'] ?? 'Unknown',
          chapter: item['chapter'] ?? 'Unknown',
          text: item['text'] ?? '',
          vector: vector,
        ));
      }

      _box.putMany(chunks);
      print("Seeded ${chunks.length} chunks into ObjectBox.");
    } catch (e) {
      print("Error seeding database: $e");
    }
  }

  Future<Map<String, dynamic>> checkDatabaseStatus() async {
    if (!isInitialized) {
      return {'status': 'Not Initialized'};
    }

    try {
      int count = _box.count();
      List<String> firstChunks = [];
      
      if (count > 0) {
        final query = _box.query().build();
        query.limit = 5;
        final chunks = query.find();
        query.close();
        firstChunks = chunks.map((c) => "${c.chapter} (L: ${c.text.length})").toList();
      }

      int jsonSize = 0;
      try {
        final jsonString = await rootBundle.loadString('assets/data/initial_data.json');
        jsonSize = jsonString.length;
      } catch (e) {
        print("Error reading JSON asset: $e");
      }

      return {
        'count': count,
        'firstChunks': firstChunks,
        'jsonSize': jsonSize,
        'status': 'OK'
      };
    } catch (e) {
      return {'status': 'Error: $e'};
    }
  }

  Future<void> forceSeed() async {
    await _seedDatabase();
  }
}
