import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // Using a versioned name to ensure updates apply correctly
    _database = await _initDB('edulok_final_v14.db'); 
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

    // 2. Requests Table (Local storage for offline requests)
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

    // 5. Unified Users Table (For offline login)
    await db.execute('''
    CREATE TABLE users (
      mobile TEXT PRIMARY KEY, name TEXT, role TEXT, token TEXT
    )
    ''');

    // 6. Pending Actions Table (The Queue for Sync)
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
  }

  // --- TEACHER OPERATIONS ---
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

  // --- STUDENT OPERATIONS ---
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

  // --- REQUEST OPERATIONS ---
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

  Future<void> withdrawRequest(String teacherId, String studentName) async {
    final db = await instance.database;
    await db.delete('requests', where: 'teacher_id = ? AND student_name = ?', whereArgs: [teacherId, studentName]);
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

  // --- UNIFIED USER OPERATIONS ---
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

  // --- PENDING ACTIONS (SYNC QUEUE) ---
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

  // --- MY MENTORS OPERATIONS ---
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

  // --- RESET DATABASE ---
  Future<void> nukeDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'edulok_final_v14.db'); 
    
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    await deleteDatabase(path);
    print("💥 Database Deleted Successfully.");
  }
}