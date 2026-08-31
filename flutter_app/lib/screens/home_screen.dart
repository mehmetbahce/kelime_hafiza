import 'package:flutter/material.dart';
import '../models/word_card.dart';
import '../data/card_loader.dart';
import '../widgets/word_card_tile.dart';
import '../services/rewarded_ad_service.dart';
import 'flashcard_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Sunucusuz mod: kartlar assets/data/cards.json'dan yüklenir (500 karta kadar
  // aynı şekilde çalışır, kod içinde tek tek yazılı kart yok).
  static const int _groupSize = 5; // her galeri kutucuğu bu kadar kelime içerir

  List<WordCard> _allCards = [];
  bool _loading = true;
  int? _selectedCategoryIndex; // null = Tümü
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cards = await CardLoader.load();
    setState(() {
      _allCards = cards;
      _loading = false;
    });
  }

  String? get _selectedCategory =>
      _selectedCategoryIndex == null ? null : _categoryNames[_selectedCategoryIndex!];

  List<WordCard> get _filtered {
    return _allCards.where((c) {
      final matchesCat = _selectedCategory == null || c.categoryName == _selectedCategory;
      final matchesSearch = _search.isEmpty ||
          c.englishWord.toLowerCase().contains(_search.toLowerCase()) ||
          c.turkishMeaning.toLowerCase().contains(_search.toLowerCase()) ||
          c.associationWord.toLowerCase().contains(_search.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();
  }

  /// Filtrelenmiş kelimeleri 5'erli gruplara böler — her grup bir galeri
  /// kutucuğu olur, dokununca içindeki kelimeler kaydırmalı açılır.
  List<List<WordCard>> _grouped(List<WordCard> cards) {
    final groups = <List<WordCard>>[];
    for (var i = 0; i < cards.length; i += _groupSize) {
      groups.add(cards.sublist(i, i + _groupSize > cards.length ? cards.length : i + _groupSize));
    }
    return groups;
  }

  List<String> get _categoryNames =>
      _allCards.map((c) => c.categoryName).whereType<String>().toSet().toList()..sort();

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final cards = _filtered;
    final groups = _grouped(cards);
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelime Hafıza (${groups.length} kart, ${_allCards.length} kelime)',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        actions: [
          IconButton(
            icon: const Icon(Icons.ondemand_video_outlined),
            tooltip: 'Reklam izle',
            onPressed: () {
              try {
                RewardedAdService().show(
                  onReward: () {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reklamı izlediğin için teşekkürler! 🎉')),
                      );
                    }
                  },
                  onNotReady: () {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reklam hazırlanıyor, birazdan tekrar dene.')),
                      );
                    }
                  },
                );
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reklam şu an kullanılamıyor.')),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.school_outlined),
            tooltip: 'Tekrar Modu',
            onPressed: cards.isEmpty ? null : () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => FlashcardScreen(cards: cards))),
          ),
          IconButton(
            icon: const Icon(Icons.quiz_outlined),
            tooltip: 'Quiz Modu',
            onPressed: cards.length < 4 ? null : () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => QuizScreen(localCards: cards))),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryChips(),
          Expanded(child: _buildBody(groups)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Kelime, anlam veya çağrışım ara...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
        onChanged: (v) => setState(() => _search = v),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final names = _categoryNames;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          _chip(null, 'Tümü'),
          for (int i = 0; i < names.length; i++) _chip(i, names[i]),
        ],
      ),
    );
  }

  Widget _chip(int? index, String label) {
    final selected = _selectedCategoryIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _selectedCategoryIndex = index),
      ),
    );
  }

  Widget _buildBody(List<List<WordCard>> groups) {
    if (groups.isEmpty) {
      return const Center(child: Text('Aramanla eşleşen kart yok.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.8,
      ),
      itemCount: groups.length,
      itemBuilder: (_, i) => WordCardTile(group: groups[i], onChanged: () => setState(() {})),
    );
  }
}
