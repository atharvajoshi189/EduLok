import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:eduthon/services/database_helper.dart';
import 'package:eduthon/services/auth_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  // REPLACE WITH YOUR ACTUAL BACKEND URL
  final String _baseUrl = "http://192.168.1.4:8000";

  // Main Sync Function
  Future<void> syncPendingActions() async {
    // 1. Get all pending actions from local DB
    final pendingActions = await DatabaseHelper.instance.getPendingActions();
    if (pendingActions.isEmpty) {
      print("SYNC: No pending actions found.");
      return;
    }

    // 2. Get Auth Token
    // Note: You need to implement getAuthToken in AuthService if not present
    // or retrieve it from SharedPreferences directly here.
    final token = await AuthService.authToken; 
    if (token == null) {
      print("SYNC: No auth token found. Cannot sync.");
      return;
    }

    print("SYNC: Found ${pendingActions.length} pending actions. Starting sync...");

    // 3. Process each action
    for (var action in pendingActions) {
      try {
        bool success = false;
        final payload = json.decode(action['payload'] as String);

        if (action['action_type'] == 'SEND_REQUEST') {
          success = await _syncSendRequest(payload, token);
        } else if (action['action_type'] == 'APPROVE_REQUEST') {
          success = await _syncApproveRequest(payload, token);
        }

        // 4. If successful, remove from queue
        if (success) {
          await DatabaseHelper.instance.deletePendingAction(action['id'] as int);
          print("SYNC: Action ${action['id']} synced successfully.");
        } else {
          print("SYNC: Failed to sync action ${action['id']}. Will retry later.");
        }
      } catch (e) {
        print("SYNC ERROR for action ${action['id']}: $e");
      }
    }
  }

  // --- Helper: Send Request to Backend ---
  Future<bool> _syncSendRequest(Map<String, dynamic> payload, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/mentorship/request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Network Error (_syncSendRequest): $e");
      return false;
    }
  }

  // --- Helper: Approve Request on Backend ---
  Future<bool> _syncApproveRequest(Map<String, dynamic> payload, String token) async {
    try {
      final requestId = payload['request_id'];
      final response = await http.post(
        Uri.parse('$_baseUrl/mentorship/requests/approve/$requestId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Network Error (_syncApproveRequest): $e");
      return false;
    }
  }
}