class WordCard {
  final int id;
  final String englishWord;
  final String turkishMeaning;
  final String associationWord;
  final String mnemonicSentence;
  final String? imageUrl;    // sunucudan gelen tek görsel (backend modu)
  final String? imageAsset;  // uygulama içine gömülü tek görsel (test/offline modu)
  final List<String> imageAssets; // birden fazla görsel (kart detayında kaydırmalı galeri)
  final int? categoryId;
  final String? categoryName;
  final String? categoryColor;
  final String difficulty;
  final int timesSeen;
  final int timesCorrect;
  final DateTime? nextReviewDate;

  WordCard({
    required this.id,
    required this.englishWord,
    required this.turkishMeaning,
    required this.associationWord,
    required this.mnemonicSentence,
    this.imageUrl,
    this.imageAsset,
    this.imageAssets = const [],
    this.categoryId,
    this.categoryName,
    this.categoryColor,
    this.difficulty = 'medium',
    this.timesSeen = 0,
    this.timesCorrect = 0,
    this.nextReviewDate,
  });

  /// Kart detayında gösterilecek tüm görseller (öncelik: imageAssets listesi,
  /// yoksa tekil imageAsset'i tek elemanlı liste yapar).
  List<String> get allImageAssets {
    if (imageAssets.isNotEmpty) return imageAssets;
    if (imageAsset != null) return [imageAsset!];
    return [];
  }

  factory WordCard.fromJson(Map<String, dynamic> json) {
    List<String> assets = [];
    if (json['image_files'] is List) {
      assets = List<String>.from(json['image_files']).map((f) => 'assets/images/$f').toList();
    }
    return WordCard(
      id: int.parse(json['id'].toString()),
      englishWord: json['english_word'] ?? '',
      turkishMeaning: json['turkish_meaning'] ?? '',
      associationWord: json['association_word'] ?? '',
      mnemonicSentence: json['mnemonic_sentence'] ?? '',
      imageUrl: json['image_url'],
      imageAssets: assets,
      categoryId: json['category_id'] != null ? int.tryParse(json['category_id'].toString()) : null,
      categoryName: json['category_name'],
      categoryColor: json['category_color'],
      difficulty: json['difficulty'] ?? 'medium',
      timesSeen: int.tryParse(json['times_seen']?.toString() ?? '0') ?? 0,
      timesCorrect: int.tryParse(json['times_correct']?.toString() ?? '0') ?? 0,
      nextReviewDate: json['next_review_date'] != null
          ? DateTime.tryParse(json['next_review_date'])
          : null,
    );
  }

  double get successRate => timesSeen == 0 ? 0 : timesCorrect / timesSeen;
}

class WordCategory {
  final int id;
  final String name;
  final String color;
  final int cardCount;

  WordCategory({required this.id, required this.name, required this.color, this.cardCount = 0});

  factory WordCategory.fromJson(Map<String, dynamic> json) {
    return WordCategory(
      id: int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      color: json['color'] ?? '#F5C518',
      cardCount: int.tryParse(json['card_count']?.toString() ?? '0') ?? 0,
    );
  }
}
