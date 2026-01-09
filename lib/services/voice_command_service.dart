import 'package:flutter/foundation.dart';

// Mock Voice Command Service - заглушка без реального распознавания
// TODO: Заменить на реальную реализацию когда решится проблема с Kotlin
class VoiceCommandService {
  static final VoiceCommandService _instance = VoiceCommandService._internal();
  factory VoiceCommandService() => _instance;

  bool _isListening = false;
  bool _isAvailable = true; // В mock режиме считаем что доступно

  VoiceCommandService._internal();

  Future<void> initialize() async {
    try {
      debugPrint("Voice Command Service initialized (MOCK MODE)");
      _isAvailable = true;
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
      debugPrint("🎤 Voice listening started (MOCK MODE)");
      _isListening = true;

      // Симулируем получение команды через 2 секунды
      await Future.delayed(const Duration(seconds: 2));

      // Возвращаем mock команду
      final mockCommands = [
        "Построй маршрут до центра города",
        "Что впереди",
        "Остановить навигацию",
        "Магазин",
      ];
      final command = mockCommands[DateTime.now().second % mockCommands.length];

      debugPrint("🎤 Recognized (MOCK): $command");
      onResult(command);
      _isListening = false;

      // TODO: Здесь будет реальное распознавание через speech_to_text
    } catch (e) {
      debugPrint("Start listening error: $e");
      _isListening = false;
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      debugPrint("🎤 Voice listening stopped");
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
