class Chapter {
  final String id;
  final String title;
  final String videoId;
  final String summary;       // New AI Feature
  final List<Map<String, dynamic>> quiz; // New AI Feature

  Chapter({
    required this.id,
    required this.title,
    required this.videoId,
    this.summary = "No summary available.",
    this.quiz = const [],
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    // AI Data nikalna
    String aiSummary = "No summary available.";
    List<Map<String, dynamic>> aiQuiz = [];

    if (json['smart_content'] != null) {
      aiSummary = json['smart_content']['summary'] ?? aiSummary;
      
      if (json['smart_content']['quiz'] != null) {
        aiQuiz = List<Map<String, dynamic>>.from(json['smart_content']['quiz']);
      }
    }

    return Chapter(
      id: json['id'],
      title: json['title'],
      videoId: json['videoId'] ?? "",
      summary: aiSummary,
      quiz: aiQuiz,
    );
  }
}