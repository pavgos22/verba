class Word {
  const Word({
    required this.id,
    required this.ru,
    required this.ruAccented,
    required this.pl,
    required this.category,
  });

  final String id;
  final String ru;
  final String ruAccented;
  final List<String> pl;
  final String category;

  String get plPrimary => pl.first;

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'] as String,
      ru: json['ru'] as String,
      ruAccented: json['ruAccented'] as String,
      pl: [for (final v in json['pl'] as List<dynamic>) v as String],
      category: json['category'] as String,
    );
  }
}
