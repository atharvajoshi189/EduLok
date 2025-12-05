import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class FormulaScreen extends StatefulWidget {
  const FormulaScreen({super.key});

  @override
  State<FormulaScreen> createState() => _FormulaScreenState();
}

class _FormulaScreenState extends State<FormulaScreen> {
  List<dynamic> _allChapters = [];
  List<dynamic> _filteredChapters = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFormulas();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadFormulas() async {
    try {
      final String response = await rootBundle.loadString('assets/data/formulas.json');
      final List<dynamic> data = json.decode(response);

      setState(() {
        _allChapters = data;
        _filteredChapters = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading formulas: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredChapters = _allChapters;
      } else {
        // Deep search: Match Chapter name OR Formula title
        _filteredChapters = _allChapters.map((chapter) {
          // Handle both 'chapter_name' and 'category' keys
          String chapterTitle = (chapter['chapter_name'] ?? chapter['category'] ?? '').toString();
          
          // Filter formulas inside the chapter
          var formulas = (chapter['formulas'] as List).where((f) {
            String title = (f['title'] ?? '').toString().toLowerCase();
            return title.contains(query);
          }).toList();

          // If chapter name matches, show all formulas. 
          // If not, show only matching formulas (if any).
          if (chapterTitle.toLowerCase().contains(query)) {
            return chapter;
          } else if (formulas.isNotEmpty) {
            // Create a copy of chapter with only matching formulas
            var newChapter = Map.from(chapter);
            newChapter['formulas'] = formulas;
            return newChapter;
          }
          return null;
        }).where((e) => e != null).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background for contrast
      appBar: AppBar(
        title: Text("Formula Master", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.outfit(),
              decoration: InputDecoration(
                hintText: "Search formulas, topics...",
                hintStyle: GoogleFonts.outfit(color: Colors.grey),
                prefixIcon: const Icon(Iconsax.search_normal, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.blueAccent, width: 1),
                ),
              ),
            ),
          ),

          // Content List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredChapters.isEmpty
                    ? Center(child: Text("No formulas found.", style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: _filteredChapters.length,
                        itemBuilder: (context, index) {
                          var chapter = _filteredChapters[index];
                          // Handle diverse JSON keys safely
                          String title = chapter['chapter_name'] ?? chapter['category'] ?? 'Unknown Chapter';
                          List formulas = chapter['formulas'] ?? [];

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 0, // Flat style
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade200)
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                title: Text(
                                  title,
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                ),
                                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                children: formulas.map<Widget>((f) => FormulaCard(data: f)).toList(),
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

// Smart Card Widget Logic
class FormulaCard extends StatelessWidget {
  final Map data;
  const FormulaCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Determine subject type based on available keys
    bool isPhysics = data.containsKey('si_unit');
    bool isChemistry = data.containsKey('description') && !isPhysics && (data['type'] == 'Reaction' || data['type'] == 'Compound');
    
    // Theme Colors (Soft Pastels)
    Color bgColor = isPhysics ? const Color(0xFFE8EAF6) : (isChemistry ? const Color(0xFFFFF3E0) : const Color(0xFFE0F2F1));
    Color accentColor = isPhysics ? const Color(0xFF3949AB) : (isChemistry ? const Color(0xFFEF6C00) : const Color(0xFF00897B));
    
    // Get Equation (handle both keys)
    String equation = data['formula'] ?? data['equation'] ?? '';
    String title = data['title'] ?? 'Untitled';
    String? subText = isPhysics ? data['where'] : data['description'];

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title + SI Unit Badge (if Physics)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: accentColor),
                ),
              ),
              if (isPhysics && data['si_unit'] != null)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accentColor.withOpacity(0.2))
                  ),
                  child: Text(
                    data['si_unit'],
                    style: GoogleFonts.outfit(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // The Formula/Equation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
              ]
            ),
            child: SelectableText(
              equation,
              style: GoogleFonts.robotoMono(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Description or "Where" clause
          if (subText != null && subText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Iconsax.info_circle, size: 14, color: accentColor.withOpacity(0.7)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isPhysics ? "Where: $subText" : subText,
                    style: GoogleFonts.outfit(
                      fontStyle: FontStyle.italic,
                      color: Colors.black54,
                      fontSize: 13,
                      height: 1.4
                    ),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}