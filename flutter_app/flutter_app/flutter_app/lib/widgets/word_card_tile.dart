import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/word_card.dart';
import '../services/api_service.dart';
import '../screens/card_detail_screen.dart';

/// Galeri kutucuğu: 1-5 kelimelik bir GRUBU temsil eder. Kapak görseli
/// gruptaki ilk kelimenin görselidir; sağ üstte "5" gibi bir rozet varsa
/// içinde birden fazla kelime olduğunu gösterir. Dokununca CardDetailScreen
/// açılır ve tüm grup kaydırmalı olarak gösterilir.
class WordCardTile extends StatelessWidget {
  final List<WordCard> group;
  final VoidCallback onChanged;
  const WordCardTile({super.key, required this.group, required this.onChanged});

  WordCard get _cover => group.first;

  @override
  Widget build(BuildContext context) {
    final card = _cover;
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
              pageBuilder: (_, __, ___) => CardDetailScreen(cards: group),
            ),
          );
        },
        onLongPress: () => _showActions(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Hero(
                    tag: 'card_group_${card.id}',
                    child: Container(
                      width: double.infinity,
                      color: catColor.withOpacity(.08),
                      child: card.imageAsset != null
                          ? Image.asset(card.imageAsset!, fit: BoxFit.contain)
                          : card.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: card.imageUrl!,
                                  fit: BoxFit.contain,
                                  errorWidget: (_, __, ___) => _placeholder(catColor),
                                  placeholder: (_, __) => Container(color: Colors.grey.shade200),
                                )
                              : _placeholder(catColor),
                    ),
                  ),
                  if (group.length > 1)
                    Positioned(
                      top: 6, right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.collections_outlined, color: Colors.white, size: 11),
                            const SizedBox(width: 3),
                            Text('${group.length}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.length > 1 ? '${card.englishWord} +${group.length - 1}' : card.englishWord,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(card.turkishMeaning,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
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
        '${_cover.englishWord} = ${_cover.turkishMeaning}',
        textAlign: TextAlign.center,
        style: TextStyle(color: color.withOpacity(0.9), fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showActions(BuildContext context) {
    if (_cover.imageAsset != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu örnek kartlar test sürümünde sabittir.')),
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
              await ApiService().deleteCard(_cover.id);
              onChanged();
            },
          ),
        ]),
      ),
    );
  }
}
