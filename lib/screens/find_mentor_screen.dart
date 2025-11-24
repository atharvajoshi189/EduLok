import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eduthon/services/database_helper.dart';
import 'package:eduthon/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FindMentorScreen extends StatefulWidget {
  const FindMentorScreen({super.key});

  @override
  State<FindMentorScreen> createState() => _FindMentorScreenState();
}

class _FindMentorScreenState extends State<FindMentorScreen> {
  List<Map<String, dynamic>> _allMentors = [];
  List<Map<String, dynamic>> _filteredMentors = [];
  String _selectedFilter = "All";
  bool _isLoading = true;
  final String _baseUrl = "http://192.168.1.4:8000";

  @override
  void initState() {
    super.initState();
    _loadMentors();
  }

  Future<void> _loadMentors() async {
    setState(() => _isLoading = true);

    // 1. Try Fetching from API (Online First)
    try {
      final token = await AuthService.getAuthToken();
      if (token != null) {
        final response = await http.get(
          Uri.parse('$_baseUrl/teachers/'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          // 2. Save to Local DB
          await DatabaseHelper.instance.saveTeachers(data);
        }
      }
    } catch (e) {
      print("Offline or API Error: $e");
    }

    // 3. Load from Local DB (Always source of truth for UI)
    final mentors = await DatabaseHelper.instance.getAllTeachers();
    
    if (mounted) {
      setState(() {
        _allMentors = mentors;
        _filteredMentors = mentors;
        _isLoading = false;
      });
    }
  }

  void _applyFilter(String subject) {
    setState(() {
      _selectedFilter = subject;
      if (subject == "All") {
        _filteredMentors = _allMentors;
      } else {
        _filteredMentors = _allMentors.where((m) {
          final s = m['subject'] ?? '';
          return s == subject;
        }).toList();
      }
    });
  }

  void _toggleConnection(int index) async {
    final selectedMentor = _filteredMentors[index];
    
    try {
      // 1. Check Connectivity
      bool isOnline = true;
      try {
        await http.get(Uri.parse('$_baseUrl/'));
      } catch (_) {
        isOnline = false;
      }

      if (isOnline) {
        // --- ONLINE MODE ---
        final token = await AuthService.getAuthToken();
        if (token != null) {
          final response = await http.post(
            Uri.parse('$_baseUrl/mentorship/request'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({'teacher_id': int.parse(selectedMentor['id'])}),
          );

          if (response.statusCode == 200) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Request sent to ${selectedMentor['name']}!"), backgroundColor: Colors.green)
            );
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to send request"), backgroundColor: Colors.red)
            );
          }
        }
      } else {
        // --- OFFLINE MODE ---
        await DatabaseHelper.instance.addPendingAction(
          'SEND_REQUEST', 
          json.encode({'teacher_id': int.parse(selectedMentor['id'])})
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Offline: Request to ${selectedMentor['name']} queued."), backgroundColor: Colors.orange)
        );
      }

      // Return selected mentor data so Dashboard can show "Pending" state
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) Navigator.pop(context, selectedMentor); 
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Find a Mentor', 
          style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2), 
          onPressed: () => Navigator.pop(context)
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search...", 
                    prefixIcon: const Icon(Iconsax.search_normal), 
                    filled: true, 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                  ),
                  onChanged: (val) {
                    setState(() {
                      _filteredMentors = _allMentors.where((m) {
                        final name = (m['name'] ?? '').toString().toLowerCase();
                        final subject = (m['subject'] ?? '').toString().toLowerCase();
                        return name.contains(val.toLowerCase()) || subject.contains(val.toLowerCase());
                      }).toList();
                    });
                  },
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ["All", "Physics", "Maths", "Chemistry", "Biology"].map((subject) {
                      bool isSelected = _selectedFilter == subject;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0), 
                        child: ChoiceChip(
                          label: Text(subject), 
                          selected: isSelected, 
                          onSelected: (_) => _applyFilter(subject)
                        )
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _filteredMentors.isEmpty
                  ? const Center(child: Text("No mentors found."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredMentors.length,
                      itemBuilder: (context, index) {
                        final mentor = _filteredMentors[index];
                        final name = mentor['name'] ?? 'Unknown Teacher';
                        final subject = mentor['subject'] ?? 'General';
                        final exp = mentor['exp'] ?? '0';
                        final firstLetter = name.isNotEmpty ? name[0] : '?';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            leading: CircleAvatar(child: Text(firstLetter)),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("$subject • $exp Exp"),
                            trailing: ElevatedButton(
                              onPressed: () => _toggleConnection(index),
                              child: const Text("Connect"),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}