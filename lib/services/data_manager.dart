import 'dart:convert';
import 'package:flutter/services.dart';

class DataManager {
  // ==========================================
  // SECTION A: AI SYLLABUS & CONTENT (NEW) 🧠
  // ==========================================

  // Ye variable puri JSON file ko memory mein rakhega
  static Map<String, dynamic>? _fullSyllabus;

  // 1. App start hote hi ye function call karna (main.dart mein)
  static Future<void> loadSyllabus() async {
    try {
      // Hum nayi AI-Generated file load kar rahe hain
      final String response = await rootBundle.loadString('assets/ai/smart_syllabus.json');
      _fullSyllabus = json.decode(response);
      print("✅ Smart Syllabus Loaded Successfully!");
    } catch (e) {
      print("❌ Error loading syllabus: $e");
      // Fallback: Agar file nahi mili to empty map
      _fullSyllabus = {};
    }
  }

  // 2. Class ke hisaab se Subjects lene ke liye
  static List<dynamic> getSubjects(String className) {
    if (_fullSyllabus != null && _fullSyllabus!.containsKey(className)) {
      return _fullSyllabus![className]['subjects'];
    }
    return [];
  }

  // 3. Specific Chapter ka "Smart Data" nikalne ke liye helper function
  // Isse hume Quiz, Summary, aur Video ID milegi
  static Map<String, dynamic>? getChapterById(String className, String subjectName, String chapterId) {
    List<dynamic> subjects = getSubjects(className);
    
    // Subject dhoondo
    var subject = subjects.firstWhere(
      (s) => s['name'] == subjectName, 
      orElse: () => null
    );

    if (subject != null) {
      List<dynamic> chapters = subject['chapters'];
      // Chapter dhoondo ID se
      var chapter = chapters.firstWhere(
        (c) => c['id'] == chapterId, 
        orElse: () => null
      );
      return chapter;
    }
    return null;
  }

  // ==========================================
  // SECTION B: MENTORS & REQUESTS (OLD) 👨‍🏫
  // ==========================================

  // 1. Registered Mentors ki List (Dummy Data)
  static List<Map<String, dynamic>> mentors = [
    {
      "id": "101",
      "name": "Amit Verma",
      "subject": "Physics",
      "exp": "8 Years",
      "rating": 4.9,
      "requests": [], 
      "students": [], 
    },
    {
      "id": "102",
      "name": "Priya Sharma",
      "subject": "Biology",
      "exp": "5 Years",
      "rating": 4.7,
      "requests": [],
      "students": [],
    }
  ];

  // 2. Naya Teacher Add karne ka function
  static void addTeacher(String name, String subject, String exp) {
    mentors.add({
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "name": name,
      "subject": subject,
      "exp": exp,
      "rating": 5.0,
      "requests": [],
      "students": [],
    });
  }

  // 3. Request Bhejne ka function
  static void sendRequestToMentor(String mentorId, String studentName) {
    final mentorIndex = mentors.indexWhere((m) => m['id'] == mentorId);
    if (mentorIndex != -1) {
      mentors[mentorIndex]['requests'].add({
        "studentName": studentName,
        "status": "Pending",
        "time": DateTime.now().toString()
      });
    }
  }

  // 4. Request Accept karne ka function
  static void acceptRequest(String mentorName, int requestIndex) {
    final mentorIndex = mentors.indexWhere((m) => m['name'] == mentorName);
    if (mentorIndex != -1) {
      var request = mentors[mentorIndex]['requests'][requestIndex];
      mentors[mentorIndex]['students'].add(request['studentName']);
      mentors[mentorIndex]['requests'].removeAt(requestIndex);
    }
  }
  
  // 5. Teacher ka data lene ke liye
  static Map<String, dynamic>? getTeacherData(String name) {
    try {
      return mentors.firstWhere((m) => m['name'] == name);
    } catch (e) {
      return null;
    }
  }
}