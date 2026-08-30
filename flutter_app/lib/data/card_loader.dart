import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/word_card.dart';

/// Uygulamanın içine gömülü kart verisini (assets/data/cards.json) okur.
/// 500 kart olsa da olmasa da aynı şekilde çalışır — Dart kodunda hiçbir
/// kart tek tek yazılı değil, hepsi JSON'dan geliyor.
class CardLoader {
  static List<WordCard>? _cache;

  static Future<List<WordCard>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/cards.json');
    final List<dynamic> jsonList = jsonDecode(raw);
    _cache = jsonList.map((j) => _fromJson(j as Map<String, dynamic>)).toList();
    return _cache!;
  }

  static WordCard _fromJson(Map<String, dynamic> j) {
    // Yeni format: "image_files": ["a.jpg","b.jpg",...] (birden fazla görsel)
    // Eski format: "image_file": "a.jpg" (tek görsel) — geriye dönük uyumluluk
    List<String> assets = [];
    if (j['image_files'] is List) {
      assets = List<String>.from(j['image_files']).map((f) => 'assets/images/$f').toList();
    }
    return WordCard(
      id: j['id'] as int,
      englishWord: j['english_word'] ?? '',
      turkishMeaning: j['turkish_meaning'] ?? '',
      associationWord: j['association_word'] ?? '',
      mnemonicSentence: j['mnemonic_sentence'] ?? '',
      imageAsset: j['image_file'] != null ? 'assets/images/${j['image_file']}' : null,
      imageAssets: assets,
      categoryName: j['category'],
      difficulty: j['difficulty'] ?? 'medium',
    );
  }
}
