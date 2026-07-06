import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'word.dart';

const wordCategories = ['zwroty', 'zaimki', 'pytania', 'czasowniki', 'rzeczowniki', 'przymiotniki'];

final wordsProvider = FutureProvider<List<Word>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/words.json');
  final list = jsonDecode(raw) as List<dynamic>;
  return [for (final e in list) Word.fromJson(e as Map<String, dynamic>)];
});
