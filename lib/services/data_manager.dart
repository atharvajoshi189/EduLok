// Yeh file puri app ka data temporary hold karegi
class DataManager {
  // 1. Registered Mentors ki List (Shuru mein kuch dummy data rakh sakte hain)
  static List<Map<String, dynamic>> mentors = [
    {
      "id": "101",
      "name": "Amit Verma",
      "subject": "Physics",
      "exp": "8 Years",
      "rating": 4.9,
      "requests": [], // Is teacher ke pass aayi hui requests
      "students": [], // Is teacher ke accepted students
    },
    {
      "id": "102",
      "name": "Priya Sharma",
      "subject": "Biology",
      "exp": "5 Years",
      "rating": 4.7,
      "requests": [],
      "students": [],
    }
  ];

  // 2. Naya Teacher Add karne ka function (Registration Screen se call hoga)
  static void addTeacher(String name, String subject, String exp) {
    mentors.add({
      "id": DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID
      "name": name,
      "subject": subject,
      "exp": exp,
      "rating": 5.0, // New teacher starts with 5 stars
      "requests": [],
      "students": [],
    });
  }

  // 3. Request Bhejne ka function (Student se call hoga)
  static void sendRequestToMentor(String mentorId, String studentName) {
    // Mentor ko dhoondo
    final mentorIndex = mentors.indexWhere((m) => m['id'] == mentorId);
    if (mentorIndex != -1) {
      // Request list mein student add karo
      mentors[mentorIndex]['requests'].add({
        "studentName": studentName,
        "status": "Pending",
        "time": DateTime.now().toString()
      });
    }
  }

  // 4. Request Accept karne ka function (Teacher Dashboard se call hoga)
  static void acceptRequest(String mentorName, int requestIndex) {
    // Mentor ko dhoondo (Naam se ya ID se - abhi hum naam use kar rahe hain demo ke liye)
    final mentorIndex = mentors.indexWhere((m) => m['name'] == mentorName);
    if (mentorIndex != -1) {
      // Request nikalo
      var request = mentors[mentorIndex]['requests'][requestIndex];
      
      // Student list mein add karo
      mentors[mentorIndex]['students'].add(request['studentName']);
      
      // Request list se hata do
      mentors[mentorIndex]['requests'].removeAt(requestIndex);
    }
  }
  
  // 5. Teacher ka data lene ke liye (Requests aur Students count)
  static Map<String, dynamic>? getTeacherData(String name) {
    try {
      return mentors.firstWhere((m) => m['name'] == name);
    } catch (e) {
      return null;
    }
  }
}