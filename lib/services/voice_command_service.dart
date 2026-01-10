import 'package:flutter/foundation.dart';
import 'google_stt_service.dart';

class VoiceCommandService {
  static final VoiceCommandService _instance = VoiceCommandService._internal();
  factory VoiceCommandService() => _instance;

  VoiceCommandService._internal();

  final GoogleSttService _stt = GoogleSttService();
  bool _isListening = false;
  bool _isAvailable = false;

  Future<void> initialize() async {
    try {
      _isAvailable = await _stt.initialize();

      if (_isAvailable) {
        debugPrint("✅ Voice Command Service initialized successfully");
      } else {
        debugPrint("❌ Voice Command Service not available");
      }
    } catch (e) {
      debugPrint("❌ Voice Command initialization error: $e");
      _isAvailable = false;
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onPartialResult,
  }) async {
    if (!_isAvailable) {
      debugPrint("❌ Speech recognition not available");
      return;
    }

    if (_isListening) {
      debugPrint("⚠️ Already listening");
      return;
    }

    try {
      debugPrint("🎤 Starting voice listening...");

      final success = await _stt.startListening();
      if (success) {
        _isListening = true;
      } else {
        debugPrint("❌ Failed to start listening");
      }
    } catch (e) {
      debugPrint("❌ Start listening error: $e");
      _isListening = false;
    }
  }

  Future<String?> stopListening() async {
    if (!_isListening) return null;

    try {
      debugPrint("🎤 Stopping voice listening");
      final result = await _stt.stopListening();
      _isListening = false;

      if (result != null) {
        debugPrint("🎤 Recognition result: $result");
      }

      return result;
    } catch (e) {
      debugPrint("❌ Stop listening error: $e");
      _isListening = false;
      return null;
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
        lowerText.contains("навигация") ||
        lowerText.contains("как добраться") ||
        lowerText.contains("веди до") ||
        lowerText.contains("дорога до")) {
      return "navigate";
    }

    if (lowerText.contains("остановить") ||
        lowerText.contains("стоп") ||
        lowerText.contains("отмена") ||
        lowerText.contains("прекратить")) {
      return "stop_navigation";
    }

    // Команды камеры
    if (lowerText.contains("что впереди") ||
        lowerText.contains("что вижу") ||
        lowerText.contains("опиши") ||
        lowerText.contains("смотри") ||
        lowerText.contains("что передо мной") ||
        lowerText.contains("посмотри")) {
      return "describe_scene";
    }

    // Магазин
    if (lowerText.contains("магазин") ||
        lowerText.contains("купить") ||
        lowerText.contains("покупки")) {
      return "open_store";
    }

    // Помощь
    if (lowerText.contains("помощь") ||
        lowerText.contains("справка") ||
        lowerText.contains("что ты умеешь")) {
      return "open_help";
    }

    return null;
  }

  // Извлечение адреса из команды навигации
  String? extractDestination(String text) {
    final lowerText = text.toLowerCase();

    // Паттерны для извлечения адреса
    final patterns = [
      RegExp(r'построй маршрут до (.+)', caseSensitive: false),
      RegExp(r'проложи путь до (.+)', caseSensitive: false),
      RegExp(r'веди до (.+)', caseSensitive: false),
      RegExp(r'дорога до (.+)', caseSensitive: false),
      RegExp(r'как добраться до (.+)', caseSensitive: false),
      RegExp(r'навигация до (.+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(lowerText);
      if (match != null && match.groupCount > 0) {
        return match.group(1)?.trim();
      }
    }

    return null;
  }
}
