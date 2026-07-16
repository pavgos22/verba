class Word {
  const Word({
    required this.id,
    required this.ru,
    String? ruAccented,
    required this.pl,
    this.category,
    this.pronunciation,
    this.firstPerson,
    this.secondPerson,
    this.verbType,
  }) : ruAccented = ruAccented ?? ru;

  final String id;
  final String ru;
  final String ruAccented;
  final List<String> pl;
  final String? category;
  final String? pronunciation;
  final String? firstPerson;
  final String? secondPerson;
  final String? verbType;

  String get plPrimary => pl.first;

  bool get hasVerbInfo =>
      (firstPerson != null && firstPerson!.isNotEmpty) ||
      (secondPerson != null && secondPerson!.isNotEmpty) ||
      (verbType != null && verbType!.isNotEmpty);

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'] as String,
      ru: json['ru'] as String,
      ruAccented: json['ruAccented'] as String?,
      pl: [for (final v in json['pl'] as List<dynamic>) v as String],
      category: json['category'] as String?,
      pronunciation: json['pronunciation'] as String?,
      firstPerson: json['firstPerson'] as String?,
      secondPerson: json['secondPerson'] as String?,
      verbType: json['verbType'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ru': ru,
        if (ruAccented != ru) 'ruAccented': ruAccented,
        'pl': pl,
        if (category != null) 'category': category,
        if (pronunciation != null) 'pronunciation': pronunciation,
        if (firstPerson != null) 'firstPerson': firstPerson,
        if (secondPerson != null) 'secondPerson': secondPerson,
        if (verbType != null) 'verbType': verbType,
      };
}
