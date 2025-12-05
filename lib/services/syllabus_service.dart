import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eduthon/services/data_manager.dart';

class SyllabusService {
  static final SyllabusService _instance = SyllabusService._internal();
  factory SyllabusService() => _instance;
  SyllabusService._internal();

  // --- 1. INITIALIZATION ---
  // No longer needed as DataManager handles loading, but keeping for compatibility if called
  Future<void> init() async {
    // DataManager.loadSyllabus() is called in main.dart
  }

  // --- 2. GET SUBJECTS (LINKED TO DATA MANAGER) ---
  List<Map<String, dynamic>> getSubjectsForClass(String className) {
    // Fetch raw data from DataManager
    List<dynamic> rawList = DataManager.getSubjects(className);

    return rawList.map((subject) {
      return {
        'name': subject['name'],
        'chapters': subject['chapters'],
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