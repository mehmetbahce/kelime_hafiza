import 'dart:math';
import 'package:flutter/material.dart';
import '../models/word_card.dart';
import '../services/api_service.dart';

class QuizScreen extends StatefulWidget {
  final int? categoryId;
  final List<WordCard>? localCards; // verilirse backend'e hiç gitmez
  const QuizScreen({super.key, this.categoryId, this.localCards});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _questions = [];
  int _index = 0;
  int _score = 0;
  String? _selected;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (widget.localCards != null) {
        setState(() { _questions = _generateLocalQuestions(widget.localCards!); _loading = false; });
        return;
      }
      final qs = await _api.getQuizQuestions(categoryId: widget.categoryId, count: 10);
      setState(() { _questions = qs; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<Map<String, dynamic>> _generateLocalQuestions(List<WordCard> cards) {
    final rnd = Random();
    final shuffled = [...cards]..shuffle(rnd);
    return shuffled.map((correct) {
      final distractors = cards.where((c) => c.id != correct.id).toList()..shuffle(rnd);
      final wrong = distractors.take(3).map((c) => c.turkishMeaning).toList();
      final options = [correct.turkishMeaning, ...wrong]..shuffle(rnd);
      return {
        'card_id': correct.id,
        'question': correct.englishWord,
        'options': options,
        'correct_answer': correct.turkishMeaning,
      };
    }).toList();
  }

  void _select(String option) {
    if (_selected != null) return;
    setState(() => _selected = option);
    final correct = _questions[_index]['correct_answer'] == option;
    if (correct) _score++;
    Future.delayed(const Duration(milliseconds: 900), () {
      if (_index < _questions.length - 1) {
        setState(() { _index++; _selected = null; });
      } else {
        _showResult();
      }
    });
  }

  void _showResult() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quiz Bitti! 🏆'),
        content: Text('$_score / ${_questions.length} doğru cevapladın.'),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('Tamam')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) {
      return Scaffold(appBar: AppBar(title: const Text('Quiz')), body: Center(child: Text(_error!)));
    }
    final q = _questions[_index];
    return Scaffold(
      appBar: AppBar(title: Text('Soru ${_index + 1} / ${_questions.length}')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: (_index) / _questions.length, color: const Color(0xFFF5C518)),
            const SizedBox(height: 32),
            Text('"${q['question']}" kelimesinin anlamı nedir?',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ...List<String>.from(q['options']).map((opt) => _optionButton(opt, q['correct_answer'])),
          ],
        ),
      ),
    );
  }

  Widget _optionButton(String option, String correctAnswer) {
    Color? bg;
    if (_selected != null) {
      if (option == correctAnswer) bg = Colors.green;
      else if (option == _selected) bg = Colors.red;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: bg != null ? Colors.white : null,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => _select(option),
        child: Text(option, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
