import 'package:flutter/material.dart';
import '../models/word_card.dart';

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
                            if (card.imageAsset != null)
                              Image.asset(card.imageAsset!, width: double.infinity, height: 170, fit: BoxFit.cover)
                            else if (card.imageUrl != null)
                              Image.network(card.imageUrl!, width: double.infinity, height: 170, fit: BoxFit.cover)
                            else
                              Container(height: 170, color: catColor.withOpacity(.15)),
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
                              Text(card.englishWord, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
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
