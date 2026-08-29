import 'package:flutter/material.dart';
import '../models/word_card.dart';
import '../services/tts_service.dart';

class CardDetailScreen extends StatelessWidget {
  final WordCard card;
  const CardDetailScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final catColor = card.categoryColor != null
        ? Color(int.parse(card.categoryColor!.replaceFirst('#', '0xFF')))
        : const Color(0xFFF5C518);

    return Scaffold(
      backgroundColor: Colors.black54,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {}, // kartın kendisine tıklamak kapatmasın
            child: Hero(
              tag: 'card_${card.id}',
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.86,
                  constraints: const BoxConstraints(maxHeight: 560),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.4), blurRadius: 30, offset: const Offset(0, 12))],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 220,
                              color: catColor.withOpacity(.08),
                              child: card.imageAsset != null
                                  ? Image.asset(card.imageAsset!, fit: BoxFit.contain)
                                  : card.imageUrl != null
                                      ? Image.network(card.imageUrl!, fit: BoxFit.contain)
                                      : null,
                            ),
                            Positioned(
                              top: 10, right: 10,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(card.englishWord, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => TtsService().speak(card.englishWord),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: catColor.withOpacity(.15), shape: BoxShape.circle),
                                      child: Icon(Icons.volume_up_rounded, color: catColor, size: 22),
                                    ),
                                  ),
                                ],
                              ),
                              Text('= ${card.turkishMeaning}',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFC9971A))),
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: const Color(0xFFFFF6D9), borderRadius: BorderRadius.circular(14)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Çağrışım: ${card.associationWord}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text(card.mnemonicSentence, style: const TextStyle(height: 1.4)),
                                  ],
                                ),
                              ),
                              if (card.categoryName != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: catColor.withOpacity(.15), borderRadius: BorderRadius.circular(20)),
                                  child: Text(card.categoryName!,
                                      style: TextStyle(color: catColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
