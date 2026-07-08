class Word {
  const Word({
    required this.id,
    required this.ru,
    String? ruAccented,
    required this.pl,
    this.category,
    this.pronunciation,
  }) : ruAccented = ruAccented ?? ru;

  final String id;
  final String ru;
  final String ruAccented;
  final List<String> pl;
  final String? category;
  final String? pronunciation;

  String get plPrimary => pl.first;

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'] as String,
      ru: json['ru'] as String,
      ruAccented: json['ruAccented'] as String?,
      pl: [for (final v in json['pl'] as List<dynamic>) v as String],
      category: json['category'] as String?,
      pronunciation: json['pronunciation'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ru': ru,
        if (ruAccented != ru) 'ruAccented': ruAccented,
        'pl': pl,
        if (category != null) 'category': category,
        if (pronunciation != null) 'pronunciation': pronunciation,
      };
}
