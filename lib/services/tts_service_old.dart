import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

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
      await _flutterTts.setLanguage("ru-RU");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        debugPrint("TTS: Started speaking");
      });

      _flutterTts.setCompletionHandler(() {
        debugPrint("TTS: Completed speaking");
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint("TTS Error: $msg");
      });

      _isInitialized = true;
      debugPrint("TTS Service initialized");
    } catch (e) {
      debugPrint("TTS initialization error: $e");
    }
  }

  Future<void> speak(String text) async {
    if (!_isEnabled || text.isEmpty) return;

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint("TTS speak error: $e");
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint("TTS stop error: $e");
    }
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
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
