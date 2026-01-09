import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';

class VoiceCommandService {
  static final VoiceCommandService _instance = VoiceCommandService._internal();
  factory VoiceCommandService() => _instance;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;

  VoiceCommandService._internal();

  Future<void> initialize() async {
    try {
      _isAvailable = await _speech.initialize(
        onError: (error) => debugPrint("Speech recognition error: $error"),
        onStatus: (status) => debugPrint("Speech recognition status: $status"),
      );

      if (_isAvailable) {
        debugPrint("Voice Command Service initialized");
      } else {
        debugPrint("Voice Command Service not available");
      }
    } catch (e) {
      debugPrint("Voice Command initialization error: $e");
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onPartialResult,
  }) async {
    if (!_isAvailable || _isListening) return;

    try {
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          } else if (onPartialResult != null) {
            onPartialResult(result.recognizedWords);
          }
        },
        localeId: "ru_RU",
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
      _isListening = true;
    } catch (e) {
      debugPrint("Start listening error: $e");
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
    } catch (e) {
      debugPrint("Stop listening error: $e");
    }
  }

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;

  // Распознавание команд
  String? parseCommand(String text) {
    final lowerText = text.toLowerCase();

    // Навигационные команды
    if (lowerText.contains("построй маршрут") ||
        lowerText.contains("проложи путь") ||
        lowerText.contains("навигация")) {
      return "navigate";
    }

    if (lowerText.contains("остановить") ||
        lowerText.contains("стоп")) {
      return "stop_navigation";
    }

    // Команды камеры
    if (lowerText.contains("что впереди") ||
        lowerText.contains("что вижу") ||
        lowerText.contains("опиши") ||
        lowerText.contains("смотри")) {
      return "describe_scene";
    }

    // Магазин
    if (lowerText.contains("магазин") ||
        lowerText.contains("купить")) {
      return "open_store";
    }

    // Помощь
    if (lowerText.contains("помощь") ||
        lowerText.contains("справка")) {
      return "open_help";
    }

    return null;
  }
}
