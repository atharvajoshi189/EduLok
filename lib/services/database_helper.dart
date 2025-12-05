import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // Version bumped to v16 to ensure new tables are created
    _database = await _initDB('edulok_final_v16.db'); 
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // 1. Teachers Table
    await db.execute('''
    CREATE TABLE teachers (
      id TEXT PRIMARY KEY, name TEXT, subject TEXT, exp TEXT, rating REAL, mobile TEXT
    )
    ''');

    // 2. Requests Table
    await db.execute('''
    CREATE TABLE requests (
      id INTEGER PRIMARY KEY AUTOINCREMENT, teacher_id TEXT, student_name TEXT, status TEXT, time TEXT
    )
    ''');
    
    // 3. Accepted Students Table
    await db.execute('''
    CREATE TABLE students (
      id INTEGER PRIMARY KEY AUTOINCREMENT, teacher_id TEXT, student_name TEXT
    )
    ''');

    // 4. Registered Students Table
    await db.execute('''
    CREATE TABLE registered_students (
      mobile TEXT PRIMARY KEY, name TEXT
    )
    ''');

    // 5. Unified Users Table
    await db.execute('''
    CREATE TABLE users (
      mobile TEXT PRIMARY KEY, name TEXT, role TEXT, token TEXT
    )
    ''');

    // 6. Pending Actions Table
    await db.execute('''
      CREATE TABLE pending_actions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action_type TEXT,
        payload TEXT,
        timestamp TEXT
      )
    ''');

    // 7. My Mentors Table
    await db.execute('''
      CREATE TABLE my_mentors(
        id TEXT PRIMARY KEY, full_name TEXT, subject TEXT, mobile TEXT
      )
    ''');

    // 8. NEW: Study Progress (For Recommendations)
    await db.execute('''
      CREATE TABLE study_progress(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter_id TEXT,
        video_id TEXT,
        is_completed INTEGER,
        last_accessed TEXT
      )
    ''');

    // 9. NEW: Quiz Results (For Scoring)
    await db.execute('''
      CREATE TABLE quiz_results(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter_id TEXT,
        score INTEGER,
        total_questions INTEGER,
        date TEXT
      )
    ''');
  }

  // ==========================================
  // SECTION 1: AUTH & USERS
  // ==========================================

  Future<void> registerStudent(String mobile, String name) async {
    final db = await instance.database;
    await db.insert('registered_students', {
      'mobile': mobile,
      'name': name
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getStudentByMobile(String mobile) async {
    final db = await instance.database;
    final maps = await db.query('registered_students', where: 'mobile = ?', whereArgs: [mobile]);
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<void> saveUser(String mobile, String name, String role, String token) async {
    final db = await instance.database;
    await db.insert('users', {
      'mobile': mobile,
      'name': name,
      'role': role,
      'token': token
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getUser(String mobile) async {
    final db = await instance.database;
    final maps = await db.query('users', where: 'mobile = ?', whereArgs: [mobile]);
    return maps.isNotEmpty ? maps.first : null;
  }

  // ==========================================
  // SECTION 2: TEACHERS & MENTORS
  // ==========================================

  Future<void> addTeacher(Map<String, dynamic> teacher) async {
    final db = await instance.database;
    await db.insert('teachers', teacher, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getTeacherByMobile(String mobile) async {
    final db = await instance.database;
    final maps = await db.query('teachers', where: 'mobile = ?', whereArgs: [mobile]);
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllTeachers() async {
    final db = await instance.database;
    return await db.query('teachers');
  }

  Future<void> saveTeachers(List<dynamic> teachersList) async {
    final db = await instance.database;
    final batch = db.batch();

    for (var teacher in teachersList) {
      batch.insert('teachers', {
        'id': teacher['id'].toString(),
        'name': teacher['full_name'],
        'subject': teacher['subject'] ?? 'General',
        'exp': teacher['experience'] ?? '0',
        'rating': teacher['rating'] ?? 0.0,
        'mobile': teacher['mobile_number']
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<void> saveMyMentors(List<dynamic> mentorsList) async {
    final db = await instance.database;
    final batch = db.batch();
    
    for (var mentor in mentorsList) {
      batch.insert('my_mentors', {
        'id': mentor['id'].toString(),
        'full_name': mentor['full_name'],
        'subject': mentor['subject'] ?? 'General',
        'mobile': mentor['mobile_number']
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getMyMentors() async {
    final db = await instance.database;
    return await db.query('my_mentors');
  }

  // ==========================================
  // SECTION 3: REQUESTS & ACTIONS
  // ==========================================

  Future<void> sendRequest(String teacherId, String studentName) async {
    final db = await instance.database;
    final existing = await db.query('requests', where: 'teacher_id = ? AND student_name = ?', whereArgs: [teacherId, studentName]);
    if (existing.isEmpty) {
      await db.insert('requests', {'teacher_id': teacherId, 'student_name': studentName, 'status': 'Pending', 'time': DateTime.now().toString()});
    }
  }

  Future<String?> getRequestStatus(String teacherId, String studentName) async {
    final db = await instance.database;
    final result = await db.query('requests', columns: ['status'], where: 'teacher_id = ? AND student_name = ?', whereArgs: [teacherId, studentName], orderBy: 'id DESC', limit: 1);
    return result.isNotEmpty ? result.first['status'] as String : null;
  }

  // UPDATED: Now supports deleting by ID (for MentorScreen)
  Future<void> withdrawRequest(int requestId) async {
    final db = await instance.database;
    await db.delete('requests', where: 'id = ?', whereArgs: [requestId]);
  }

  Future<List<Map<String, dynamic>>> getRequestsForTeacher(String teacherId) async {
    final db = await instance.database;
    return await db.query('requests', where: 'teacher_id = ? AND status = ?', whereArgs: [teacherId, 'Pending']);
  }

  Future<void> acceptRequest(int requestId, String teacherId, String studentName) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.update('requests', {'status': 'Accepted'}, where: 'id = ?', whereArgs: [requestId]);
      await txn.insert('students', {'teacher_id': teacherId, 'student_name': studentName});
    });
  }

  Future<List<Map<String, dynamic>>> getStudentsForTeacher(String teacherId) async {
    final db = await instance.database;
    return await db.query('students', where: 'teacher_id = ?', whereArgs: [teacherId]);
  }

  // PENDING ACTIONS (For Sync)
  Future<void> addPendingAction(String type, String payload) async {
    final db = await instance.database;
    await db.insert('pending_actions', {
      'action_type': type,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingActions() async {
    final db = await instance.database;
    return await db.query('pending_actions');
  }

  Future<void> deletePendingAction(int id) async {
    final db = await instance.database;
    await db.delete('pending_actions', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // SECTION 4: STUDY PROGRESS (NEW AI FEATURES) 🧠
  // ==========================================

  // Save that a user started/finished a chapter
  Future<void> updateProgress(String chapterId, String videoId) async {
    final db = await instance.database;
    final result = await db.query('study_progress', 
      where: 'chapter_id = ?', whereArgs: [chapterId]);

    if (result.isEmpty) {
      await db.insert('study_progress', {
        'chapter_id': chapterId,
        'video_id': videoId,
        'is_completed': 1,
        'last_accessed': DateTime.now().toString()
      });
    } else {
      await db.update('study_progress', {
        'last_accessed': DateTime.now().toString()
      }, where: 'chapter_id = ?', whereArgs: [chapterId]);
    }
  }

  // Get the last chapter the user studied (For Recommendations)
  Future<Map<String, dynamic>?> getLastStudiedChapter() async {
    final db = await instance.database;
    final result = await db.query('study_progress', 
      orderBy: 'last_accessed DESC', 
      limit: 1
    );
    return result.isNotEmpty ? result.first : null;
  }

  // ==========================================
  // SECTION 5: UTILS
  // ==========================================

  Future<void> nukeDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'edulok_final_v16.db'); 
    
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    await deleteDatabase(path);
    print("💥 Database Deleted Successfully.");
  }

  Future<void> clearUserTables() async {
    final db = await instance.database;
    await db.delete('my_mentors');
    await db.delete('requests');
    await db.delete('students');
    await db.delete('users');
    await db.delete('pending_actions');
    await db.delete('study_progress');
    await db.delete('quiz_results');
    print("🧹 User Data Cleared Successfully.");
  }

  // ==========================================
  // SECTION 6: OFFLINE DOUBT SOLVING (FTS) 🔍
  // ==========================================

  static Database? _questionsDatabase;

  Future<Database> get questionsDatabase async {
    if (_questionsDatabase != null) return _questionsDatabase!;
    _questionsDatabase = await _initQuestionsDB();
    return _questionsDatabase!;
  }

  Future<Database> _initQuestionsDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'questions.db');

    // Check if DB exists
    final exists = await databaseExists(path);

    if (!exists) {
      print("Creating new copy of questions.db from assets");
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Copy from assets
      ByteData data = await rootBundle.load(join('assets', 'databases', 'questions.db'));
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      
      await File(path).writeAsBytes(bytes, flush: true);
    } else {
      print("Opening existing questions.db");
    }

    final db = await openDatabase(path, readOnly: true);
    
    // DEBUG: Check DB content
    try {
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM questions_fts'));
      print("DEBUG: Total questions in DB: $count");
    } catch (e) {
      print("DEBUG: Error checking DB count: $e");
    }

    return db;
  }

  Future<List<Map<String, dynamic>>> searchDoubts(String query) async {
    final db = await questionsDatabase;
    print("DEBUG: Searching for: '$query'");

    // 1. Clean Query (Strip Punctuation)
    final cleanQuery = query.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ').trim();
    if (cleanQuery.isEmpty) return [];

    // 2. Try Standard FTS Search
    print("DEBUG: Trying FTS Match with: '$cleanQuery*'");
    var results = await db.rawQuery('''
      SELECT * FROM questions_fts 
      WHERE clean_question MATCH ? 
      LIMIT 5
    ''', ['$cleanQuery*']);

    if (results.isNotEmpty) {
      print("DEBUG: FTS Match Found: ${results.length} results");
      return results;
    }

    // 3. Fallback: Number Search (e.g., "Exercise 12.3")
    final numbers = RegExp(r'\d+').allMatches(cleanQuery).map((m) => m.group(0)).join('%');
    if (numbers.isNotEmpty) {
      print("DEBUG: Trying Number Search with: '%$numbers%'");
      results = await db.rawQuery('''
        SELECT * FROM questions_fts 
        WHERE clean_question LIKE ? 
        LIMIT 5
      ''', ['%$numbers%']);

      if (results.isNotEmpty) {
        print("DEBUG: Number Match Found: ${results.length} results");
        return results;
      }
    }

    // 4. Fallback: Longest Word Search
    final words = cleanQuery.split(' ').where((w) => w.length > 4).toList();
    if (words.isNotEmpty) {
      // Sort by length descending
      words.sort((a, b) => b.length.compareTo(a.length));
      final longestWord = words.first;
      
      print("DEBUG: Trying Longest Word Search with: '%$longestWord%'");
      results = await db.rawQuery('''
        SELECT * FROM questions_fts 
        WHERE clean_question LIKE ? 
        LIMIT 5
      ''', ['%$longestWord%']);

      if (results.isNotEmpty) {
        print("DEBUG: Keyword Match Found: ${results.length} results");
        return results;
      }
    }

    print("DEBUG: No matches found.");
    return [];
  }
}