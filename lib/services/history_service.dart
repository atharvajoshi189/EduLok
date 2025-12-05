import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  static Database? _database;

  factory HistoryService() {
    return _instance;
  }

  HistoryService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'user_history.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table 1: sessions
    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        title TEXT,
        timestamp INTEGER,
        type TEXT
      )
    ''');

    // Table 2: messages
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT,
        role TEXT,
        content TEXT,
        image_path TEXT,
        FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');
  }

  // 1. Create a new session
  Future<String> createSession(String title, String type) async {
    final db = await database;
    String sessionId = const Uuid().v4();
    int timestamp = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      'sessions',
      {
        'id': sessionId,
        'title': title,
        'timestamp': timestamp,
        'type': type, // 'chat' or 'scan'
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return sessionId;
  }

  // 2. Add a message to a session
  Future<void> addMessage(String sessionId, String role, String content,
      {String? imagePath}) async {
    final db = await database;
    await db.insert(
      'messages',
      {
        'session_id': sessionId,
        'role': role, // 'user' or 'bot'
        'content': content,
        'image_path': imagePath,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Update session timestamp to move it to the top
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'sessions',
      {'timestamp': timestamp},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  // 3. Get all sessions (sorted by newest first)
  Future<List<Map<String, dynamic>>> getSessions() async {
    final db = await database;
    return await db.query(
      'sessions',
      orderBy: 'timestamp DESC',
    );
  }

  // 4. Get messages for a specific session
  Future<List<Map<String, dynamic>>> getMessages(String sessionId) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'id ASC', // Oldest messages first (chat order)
    );
  }

  // 5. Delete a session
  Future<void> deleteSession(String sessionId) async {
    final db = await database;
    // Cascade delete is not enabled by default in SQLite for some versions,
    // so we manually delete messages first just in case, or enable foreign keys.
    // Ideally, 'ON DELETE CASCADE' works if PRAGMA foreign_keys = ON is set.
    // For safety, we can delete both.
    
    await db.delete(
      'messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    
    await db.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }
  
  // Helper to close db
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
