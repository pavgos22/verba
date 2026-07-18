class Word {
  const Word({
    required this.id,
    required this.ru,
    String? ruAccented,
    required this.pl,
    this.ruAlt = const [],
    this.category,
    this.pronunciation,
    this.firstPerson,
    this.secondPerson,
    this.verbType,
    this.masculine,
    this.feminine,
    this.neuter,
    this.plural,
  }) : ruAccented = ruAccented ?? ru;

  final String id;
  final String ru;
  final String ruAccented;
  final List<String> pl;
  final List<String> ruAlt;
  final String? category;
  final String? pronunciation;
  final String? firstPerson;
  final String? secondPerson;
  final String? verbType;
  final String? masculine;
  final String? feminine;
  final String? neuter;
  final String? plural;

  String get plPrimary => pl.first;

  bool get hasVerbInfo =>
      (firstPerson != null && firstPerson!.isNotEmpty) ||
      (secondPerson != null && secondPerson!.isNotEmpty) ||
      (verbType != null && verbType!.isNotEmpty);

  bool get hasAdjInfo =>
      (feminine != null && feminine!.isNotEmpty) ||
      (neuter != null && neuter!.isNotEmpty) ||
      (plural != null && plural!.isNotEmpty);

  String get masculineForm => masculine != null && masculine!.isNotEmpty ? masculine! : ruAccented;

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'] as String,
      ru: json['ru'] as String,
      ruAccented: json['ruAccented'] as String?,
      pl: [for (final v in json['pl'] as List<dynamic>) v as String],
      ruAlt: [for (final v in (json['ruAlt'] as List<dynamic>? ?? const [])) v as String],
      category: json['category'] as String?,
      pronunciation: json['pronunciation'] as String?,
      firstPerson: json['firstPerson'] as String?,
      secondPerson: json['secondPerson'] as String?,
      verbType: json['verbType'] as String?,
      masculine: json['masculine'] as String?,
      feminine: json['feminine'] as String?,
      neuter: json['neuter'] as String?,
      plural: json['plural'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ru': ru,
        if (ruAccented != ru) 'ruAccented': ruAccented,
        'pl': pl,
        if (ruAlt.isNotEmpty) 'ruAlt': ruAlt,
        if (category != null) 'category': category,
        if (pronunciation != null) 'pronunciation': pronunciation,
        if (firstPerson != null) 'firstPerson': firstPerson,
        if (secondPerson != null) 'secondPerson': secondPerson,
        if (verbType != null) 'verbType': verbType,
        if (masculine != null) 'masculine': masculine,
        if (feminine != null) 'feminine': feminine,
        if (neuter != null) 'neuter': neuter,
        if (plural != null) 'plural': plural,
      };
}
