import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/word_card.dart';

class ApiService {
  // XAMPP2 local test: http://10.0.2.2/kelime_hafiza/backend/api (Android emülatör)
  // Gerçek cihazda: http://<bilgisayarının-lokal-ip'si>/kelime_hafiza/backend/api
  // Canlıda: https://guzel.net.tr/kelime_hafiza/backend/api
  static const String baseUrl = 'https://guzel.net.tr/kelime_hafiza/backend/api';

  Future<List<WordCard>> getCards({int? categoryId, String? search, bool dueOnly = false}) async {
    final params = <String, String>{};
    if (categoryId != null) params['category_id'] = categoryId.toString();
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (dueOnly) params['due_only'] = '1';

    final uri = Uri.parse('$baseUrl/cards_list.php').replace(queryParameters: params);
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Kartlar yüklenemedi');
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    return (data['cards'] as List).map((c) => WordCard.fromJson(c)).toList();
  }

  Future<List<WordCategory>> getCategories() async {
    final res = await http.get(Uri.parse('$baseUrl/categories_list.php'));
    if (res.statusCode != 200) throw Exception('Kategoriler yüklenemedi');
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    return (data['categories'] as List).map((c) => WordCategory.fromJson(c)).toList();
  }

  Future<void> addCard({
    required String englishWord,
    required String turkishMeaning,
    required String associationWord,
    required String mnemonicSentence,
    int? categoryId,
    String difficulty = 'medium',
    File? imageFile,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/cards_add.php'));
    request.fields['english_word'] = englishWord;
    request.fields['turkish_meaning'] = turkishMeaning;
    request.fields['association_word'] = associationWord;
    request.fields['mnemonic_sentence'] = mnemonicSentence;
    request.fields['difficulty'] = difficulty;
    if (categoryId != null) request.fields['category_id'] = categoryId.toString();
    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }
    final streamed = await request.send();
    if (streamed.statusCode != 201) throw Exception('Kart eklenemedi');
  }

  Future<void> submitReview(int cardId, int quality) async {
    final res = await http.post(
      Uri.parse('$baseUrl/review_submit.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': cardId, 'quality': quality}),
    );
    if (res.statusCode != 200) throw Exception('Tekrar kaydedilemedi');
  }

  Future<void> deleteCard(int id) async {
    final res = await http.get(Uri.parse('$baseUrl/cards_delete.php?id=$id'));
    if (res.statusCode != 200) throw Exception('Kart silinemedi');
  }

  Future<List<Map<String, dynamic>>> getQuizQuestions({int? categoryId, int count = 10}) async {
    final params = <String, String>{'count': count.toString()};
    if (categoryId != null) params['category_id'] = categoryId.toString();
    final uri = Uri.parse('$baseUrl/quiz_generate.php').replace(queryParameters: params);
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Quiz oluşturulamadı');
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    return List<Map<String, dynamic>>.from(data['questions']);
  }
}
