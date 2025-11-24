import 'package:objectbox/objectbox.dart';

@Entity()
class TextChunk {
  @Id()
  int id = 0;

  String text;       // Asli Padhai ka content
  String metadata;   // Chapter name / Page info

  // Vector ko hum simple List<double> ki tarah store karenge
  // Kyunki 14k items mein manual math bhi fast hota hai
  List<double>? vector; 

  TextChunk({required this.text, required this.metadata, this.vector});
}