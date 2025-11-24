import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // --- KEYS ---
  static const String _keyRole = 'user_role'; 
  static const String _keyName = 'user_name';
  static const String _keyId = 'user_id';
  static const String _keySubject = 'teacher_subject';
  static const String _keyToken = 'auth_token';
  static const String _keyOnboarded = 'is_onboarded';
  static const String _keyMobile = 'temp_mobile';

  // --- STATIC VARIABLES (Quick Access ke liye) ---
  static String? authToken; 
  static String? userName; // <--- YE MISSING THA, AB ADD KAR DIYA

  // --- INIT (App start par call karna) ---
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString(_keyToken);
    userName = prefs.getString(_keyName); // Load saved name
  }

  // --- TEMP MOBILE ---
  static Future<void> saveTempMobile(String mobile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMobile, mobile);
  }

  static Future<String?> getTempMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyMobile);
  }

  // --- SAVE TEACHER ---
  // --- SAVE TEACHER ---
  static Future<void> saveTeacherData({
    required String id, 
    required String name, 
    required String subject,
    required String token // Added token
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRole, 'teacher');
    await prefs.setString(_keyId, id);
    await prefs.setString(_keyName, name);
    await prefs.setString(_keySubject, subject);
    await prefs.setBool(_keyOnboarded, true);
    
    // Update Static Variables
    userName = name;
    authToken = token; // Use real token
    await prefs.setString(_keyToken, authToken!);
  }

  // --- SAVE STUDENT ---
  static Future<void> saveStudentData({
    required String name,
    required String token // Added token
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRole, 'student');
    await prefs.setString(_keyName, name);
    await prefs.setBool(_keyOnboarded, true);
    
    // Update Static Variables
    userName = name;
    authToken = token; // Use real token
    await prefs.setString(_keyToken, authToken!);
  }
  
  // --- SAVE GENERAL USER (Legacy) ---
  static Future<void> saveUserData({
    required String token, 
    required String name, 
    bool onboarded = false
  }) async {
    final prefs = await SharedPreferences.getInstance();
    authToken = token; 
    userName = name; // Update static variable
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyName, name);
    await prefs.setBool(_keyOnboarded, onboarded);
  }

  // --- GETTERS ---
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }
  
  static Future<String?> getId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyId);
  }

  static Future<String?> getSubject() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySubject);
  }
  
  static Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboarded) ?? false;
  }
  
  static Future<String?> getAuthToken() async {
    if (authToken != null) return authToken;
    final prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString(_keyToken);
    return authToken;
  }

  // --- LOGOUT ---
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    authToken = null;
    userName = null;
    await prefs.clear();
  }
}