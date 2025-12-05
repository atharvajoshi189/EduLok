import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // ⚠️ IMPORTANT: Replace with your Laptop's IP Address
  static const String _baseUrl = "http://192.168.1.4:8000"; 

  bool _isReady = false;

  Future<void> init() async {
    _isReady = true;
    print("🌐 AI Service Ready (Online Mode)");
  }

  // --- ONLINE CHATBOT (Dashboard) ---
  Future<Map<String, dynamic>> getChatResponse(String userQuery, {String? language}) async {
    // 1. Local Greeting Handling (Gemini Polish)
    final q = userQuery.toLowerCase().trim();
    if (q.contains('hi') || q.contains('hello') || q.contains('hey')) {
      return {"message": "Hello! 👋 How can I help you with your studies today?", "type": "text"};
    }
    if (q.contains('thank')) {
      return {"message": "You're welcome! Happy learning! 🎓", "type": "text"};
    }
    if (q.contains('bye') || q.contains('goodbye')) {
      return {"message": "Goodbye! See you soon. 👋", "type": "text"};
    }

    if (!_isReady) return {"message": "Connecting to server...", "type": "text"};
    
    try {
      print("Sending query to $_baseUrl/chat: $userQuery");
      
      String finalQuery = userQuery;
      if (language != null && language != 'en') {
        finalQuery += " (Reply in $language language)";
      }

      final response = await http.post(
        Uri.parse("$_baseUrl/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "query": finalQuery,
          "subject": "General"
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "message": data['answer'] ?? "No answer received.",
          "type": "text" // Default to text for now
        };
      } else {
        return {
          "message": "Server Error: ${response.statusCode}. Is the backend running?",
          "type": "text"
        };
      }
    } catch (e) {
      print("Network Error: $e");
      return {
        "message": "⚠️ Connection Failed. Error: $e",
        "type": "text"
      };
    }
  }
}