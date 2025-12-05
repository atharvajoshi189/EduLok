import 'package:objectbox/objectbox.dart';
import 'dart:typed_data';

@Entity()
class BookChunk {
  @Id()
  int id = 0;

  int classNum;
  String subject;
  String chapter;
  String text;

  // @HnswIndex(dimensions: 384)
  List<double> vector;
  // Actually, the error said "Could not resolve annotation".
  // Maybe I need to remove the annotation if the generator is old?
  // But I want vector search.
  // Let's try to just remove the annotation for now to get it building.
  // If I remove it, I can't do vector search.
  // Wait, maybe I need to upgrade objectbox_generator? It is 2.4.0.
  // Let's try to just use List<double> without annotation first to see if it builds.

  BookChunk({
    this.id = 0,
    required this.classNum,
    required this.subject,
    required this.chapter,
    required this.text,
    required this.vector,
  });
}
