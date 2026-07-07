import 'word.dart';

class Course {
  const Course({
    required this.id,
    required this.name,
    required this.description,
    required this.words,
  });

  final String id;
  final String name;
  final String description;
  final List<Word> words;

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      words: [
        for (final w in json['words'] as List<dynamic>) Word.fromJson(w as Map<String, dynamic>),
      ],
    );
  }
}
