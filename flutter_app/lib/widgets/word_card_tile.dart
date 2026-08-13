import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/word_card.dart';
import '../services/api_service.dart';
import '../screens/card_detail_screen.dart';

class WordCardTile extends StatelessWidget {
  final WordCard card;
  final VoidCallback onChanged;
  const WordCardTile({super.key, required this.card, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final catColor = card.categoryColor != null
        ? Color(int.parse(card.categoryColor!.replaceFirst('#', '0xFF')))
        : const Color(0xFFF5C518);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              opaque: false,
              barrierColor: Colors.transparent,
              transitionDuration: const Duration(milliseconds: 220),
              pageBuilder: (_, __, ___) => CardDetailScreen(card: card),
            ),
          );
        },
        onLongPress: () => _showActions(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Hero(
                tag: 'card_${card.id}',
                child: card.imageAsset != null
                    ? Image.asset(card.imageAsset!, fit: BoxFit.cover)
                    : card.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: card.imageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _placeholder(catColor),
                            placeholder: (_, __) => Container(color: Colors.grey.shade200),
                          )
                        : _placeholder(catColor),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.englishWord,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  Text(card.turkishMeaning,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: card.successRate,
                    minHeight: 4,
                    backgroundColor: Colors.grey.shade200,
                    color: catColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(Color color) {
    return Container(
      color: color.withOpacity(0.15),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Text(
        '${card.englishWord} = ${card.turkishMeaning}\n\nÇağrışım: ${card.associationWord}',
        textAlign: TextAlign.center,
        style: TextStyle(color: color.withOpacity(0.9), fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showActions(BuildContext context) {
    if (card.imageAsset != null) {
      // Test/yerel kart - backend'e bağlı değil, silinemez
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu örnek kart test sürümünde sabittir.')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Kartı sil'),
            onTap: () async {
              Navigator.pop(context);
              await ApiService().deleteCard(card.id);
              onChanged();
            },
          ),
        ]),
      ),
    );
  }
}
