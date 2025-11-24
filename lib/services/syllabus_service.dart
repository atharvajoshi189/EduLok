import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; // rootBundle ke liye
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconsax/iconsax.dart';

class SyllabusService {
  static final SyllabusService _instance = SyllabusService._internal();
  factory SyllabusService() => _instance;
  SyllabusService._internal();

  Map<String, dynamic>? _masterData;

  static Null get instance => null;

  // --- 1. INITIALIZATION ---
  Future<void> init() async {
    if (_masterData != null) return;

    try {
      final String response = await rootBundle.loadString('assets/content/master_syllabus.json');
      _masterData = json.decode(response);
      print("✅ EduLok Syllabus Engine Loaded!");
    } catch (e) {
      print("❌ Error loading master_syllabus.json: $e");
      _masterData = {};
    }
  }

  // --- 2. GET SUBJECTS (FIXED) ---
  List<Map<String, dynamic>> getSubjectsForClass(String className) {
    if (_masterData == null || !_masterData!.containsKey(className)) {
      return [];
    }

    List<dynamic> rawList = _masterData![className]['subjects'];

    return rawList.map((subject) {
      return {
        'name': subject['name'],
        'chapters': subject['chapters'],
        
        // 🔥 ERROR FIX: 'as String' lagana zaroori hai
        'icon': _getIcon(subject['icon'] as String), 
        'color': _parseColor(subject['color'] as String), 
      };
    }).toList().cast<Map<String, dynamic>>();
  }

  // --- 3. HELPERS ---
  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'microscope': return Iconsax.microscope;
      case 'math': return Iconsax.math;
      case 'flash_1': return Iconsax.flash_1;
      case 'flask_2': return Iconsax.flag2;
      case 'book': return Iconsax.book_1;
      case 'text_block': return Iconsax.text_block;
      case 'translate': return Iconsax.translate;
      case 'scroll': return Iconsax.scroll;
      case 'global': return Iconsax.global;
      case 'courthouse': return Iconsax.courthouse;
      case 'chart_square': return Iconsax.chart_square;
      default: return Iconsax.book_saved;
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString));
    } catch (e) {
      return Colors.blue;
    }
  }

  // --- 4. PROGRESS LOGIC ---
  Future<void> saveProgress(String chapterId, double seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('prog_$chapterId', seconds);
  }

  Future<double> getProgress(String chapterId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('prog_$chapterId') ?? 0.0;
  }
}