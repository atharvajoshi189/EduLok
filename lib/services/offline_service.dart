import 'package:eduthon/services/database_helper.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  // --- OFFLINE DOUBT SOLVER (AI Hub) ---
  Future<String> solveOfflineDoubt(String query) async {
    try {
      // Offline Search in SQLite
      final results = await DatabaseHelper.instance.searchDoubts(query);

      if (results.isNotEmpty) {
        return results.first['solution'] ?? "Solution found but empty.";
      } else {
        return "Offline Solution: No direct match found in the database.";
      }
    } catch (e) {
      print("Database Error: $e");
      return "Error searching database: $e";
    }
  }

  Future<String> performOCR(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      await textRecognizer.close();
      return recognizedText.text;
    } catch (e) {
      print("OCR Error: $e");
      return "";
    }
  }
}
