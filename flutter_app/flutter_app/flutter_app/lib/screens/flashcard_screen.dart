import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/word_card.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';

class FlashcardScreen extends StatefulWidget {
  final List<WordCard> cards;
  const FlashcardScreen({super.key, required this.cards});
  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final ApiService _api = ApiService();
  late final PageController _pageController;
  int _index = 0;
  final Set<int> _flipped = {};
  bool _done = false;
  int _reviewedCount = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _currentShowsBack => _flipped.contains(_index);

  void _flip(int index) {
    setState(() {
      if (_flipped.contains(index)) {
        _flipped.remove(index);
      } else {
        _flipped.add(index);
      }
    });
  }

  Future<void> _answer(int quality) async {
    final card = widget.cards[_index];
    if (card.imageAsset == null) {
      await _api.submitReview(card.id, quality);
    }
    _reviewedCount++;
    _goNext();
  }

  void _goNext() {
    if (_index < widget.cards.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    } else {
      setState(() => _done = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return _buildDoneScreen();

    final progress = _index / widget.cards.length;
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('${_index + 1} / ${widget.cards.length}'),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: progress, color: const Color(0xFFF5C518), backgroundColor: Colors.white12),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.cards.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final card = widget.cards[i];
                final showBack = _flipped.contains(i);
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: GestureDetector(
                      onTap: () => _flip(i),
                      child: showBack ? _buildBack(card) : _buildFront(card),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_currentShowsBack) _buildAnswerButtons() else _buildHint(),
        ],
      ),
    );
  }

  Widget _buildFront(WordCard card) {
    return _cardShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(card.englishWord,
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => TtsService().speak(card.englishWord),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFF5C518).withOpacity(.25), shape: BoxShape.circle),
                  child: const Icon(Icons.volume_up_rounded, color: Color(0xFFC9971A), size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Anlamını hatırlıyor musun?', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildBack(WordCard card) {
    return _cardShell(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (card.imageAsset != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(card.imageAsset!, height: 200, fit: BoxFit.contain),
              )
            else if (card.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(imageUrl: card.imageUrl!, height: 200, fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => const SizedBox.shrink()),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(card.englishWord, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => TtsService().speak(card.englishWord),
                  child: const Icon(Icons.volume_up_rounded, color: Color(0xFFC9971A), size: 22),
                ),
              ],
            ),
            Text('= ${card.turkishMeaning}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFFC9971A))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFF6D9), borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                Text('Çağrışım: ${card.associationWord}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(card.mnemonicSentence, textAlign: TextAlign.center),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardShell({required Widget child}) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 460),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }

  Widget _buildHint() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Text('Kartı çevirmek için dokun · sağa/sola kaydır', style: TextStyle(color: Colors.white54)),
    );
  }

  Widget _buildAnswerButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Row(
        children: [
          _answerBtn('Tekrar', Colors.red, 1),
          _answerBtn('Zor', Colors.orange, 3),
          _answerBtn('İyi', Colors.blue, 4),
          _answerBtn('Kolay', Colors.green, 5),
        ],
      ),
    );
  }

  Widget _answerBtn(String label, Color color, int quality) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => _answer(quality),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildDoneScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text('Tebrikler!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('$_reviewedCount kartı tekrar ettin.', style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5C518), foregroundColor: const Color(0xFF1A1A1A),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
