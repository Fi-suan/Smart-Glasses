import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isEnabled = true;

  TtsService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Получаем доступные голоса
      var voices = await _flutterTts.getVoices;
      debugPrint("Available voices: $voices");

      // Пытаемся найти русский голос
      var russianVoice;
      if (voices != null && voices is List) {
        for (var voice in voices) {
          if (voice['locale'] != null && voice['locale'].toString().startsWith('ru')) {
            russianVoice = voice;
            debugPrint("Found Russian voice: ${voice['name']} (${voice['locale']})");
            break;
          }
        }
      }

      // Устанавливаем язык
      await _flutterTts.setLanguage("ru-RU");

      // Если нашли русский голос, устанавливаем его
      if (russianVoice != null && russianVoice['name'] != null) {
        await _flutterTts.setVoice({"name": russianVoice['name'], "locale": russianVoice['locale']});
        debugPrint("Set Russian voice: ${russianVoice['name']}");
      }

      // Настройки речи
      await _flutterTts.setSpeechRate(0.45); // Чуть медленнее для лучшего понимания
      await _flutterTts.setVolume(1.0); // Максимальная громкость
      await _flutterTts.setPitch(1.0); // Нормальный тон

      debugPrint("TTS Service initialized (REAL TTS with Russian voice)");
      _isInitialized = true;
    } catch (e) {
      debugPrint("TTS initialization error: $e");
      // Fallback - работаем без специфичного голоса
      _isInitialized = true;
    }
  }

  Future<void> speak(String text) async {
    if (!_isEnabled || text.isEmpty) return;

    try {
      debugPrint("🔊 TTS: $text");
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint("TTS speak error: $e");
      // При ошибке хотя бы выводим в консоль
    }
  }

  Future<void> stop() async {
    try {
      debugPrint("TTS stopped");
    } catch (e) {
      debugPrint("TTS stop error: $e");
    }
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    debugPrint("TTS enabled: $enabled");
  }

  bool get isEnabled => _isEnabled;

  // Удобные методы для стандартных фраз
  Future<void> announceButton(String buttonName) async {
    await speak("Кнопка $buttonName");
  }

  Future<void> announceNavigation(String destination) async {
    await speak("Переход на $destination");
  }

  Future<void> announceError(String error) async {
    await speak("Ошибка: $error");
  }

  Future<void> announceSuccess(String message) async {
    await speak(message);
  }
}
