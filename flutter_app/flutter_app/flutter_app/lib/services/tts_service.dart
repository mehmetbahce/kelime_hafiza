import 'package:flutter_tts/flutter_tts.dart';

/// İngilizce kelimelerin telaffuzunu cihazın kendi sesli okuma
/// motoruyla (TTS) çalar. İnternet gerekmez, telefonun sistem
/// TTS motorunu kullanır.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.42); // biraz yavaş, öğrenme için daha net
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  Future<void> speak(String englishWord) async {
    await _ensureInit();
    await _tts.stop();
    await _tts.speak(englishWord);
  }
}
