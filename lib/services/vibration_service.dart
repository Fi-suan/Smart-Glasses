import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

enum VibrationType {
  light, // Легкая вибрация
  medium, // Средняя вибрация
  heavy, // Сильная вибрация
  warning, // Предупреждение (паттерн)
  danger, // Опасность (интенсивный паттерн)
}

class VibrationService {
  static final VibrationService _instance = VibrationService._internal();
  factory VibrationService() => _instance;

  VibrationService._internal();

  bool _isEnabled = true;

  // Вибрация с заданной интенсивностью
  Future<void> vibrate(VibrationType type) async {
    if (!_isEnabled) return;

    try {
      switch (type) {
        case VibrationType.light:
          await HapticFeedback.lightImpact();
          break;

        case VibrationType.medium:
          await HapticFeedback.mediumImpact();
          break;

        case VibrationType.heavy:
          await HapticFeedback.heavyImpact();
          break;

        case VibrationType.warning:
          // Паттерн: короткая - пауза - короткая
          await HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.mediumImpact();
          break;

        case VibrationType.danger:
          // Паттерн: длинная - пауза - длинная - пауза - длинная
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 200));
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 200));
          await HapticFeedback.heavyImpact();
          break;
      }

      debugPrint('📳 Vibration: $type');
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }

  // Специализированные методы

  // Вибрация при нажатии кнопки
  Future<void> buttonPress() async {
    await vibrate(VibrationType.light);
  }

  // Вибрация при обнаружении препятствия
  Future<void> obstacleDetected({bool isDangerous = false}) async {
    if (isDangerous) {
      await vibrate(VibrationType.danger);
    } else {
      await vibrate(VibrationType.warning);
    }
  }

  // Вибрация при приближении к препятствию (по расстоянию)
  Future<void> proximityAlert(double distanceMeters) async {
    if (distanceMeters < 1.0) {
      await vibrate(VibrationType.danger);
    } else if (distanceMeters < 3.0) {
      await vibrate(VibrationType.heavy);
    } else if (distanceMeters < 5.0) {
      await vibrate(VibrationType.medium);
    }
  }

  // Вибрация при успешном действии (тройная короткая)
  Future<void> success() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.lightImpact();
      debugPrint('📳 Vibration: success (triple)');
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }

  // Вибрация при ошибке (двойная средняя)
  Future<void> error() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      await HapticFeedback.mediumImpact();
      debugPrint('📳 Vibration: error (double)');
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }

  // Паттерн SOS для критической опасности (... --- ...)
  Future<void> sos() async {
    if (!_isEnabled) return;
    try {
      // S (три короткие)
      for (int i = 0; i < 3; i++) {
        await HapticFeedback.lightImpact();
        await Future.delayed(const Duration(milliseconds: 100));
      }
      await Future.delayed(const Duration(milliseconds: 200));

      // O (три длинные)
      for (int i = 0; i < 3; i++) {
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 300));
      }
      await Future.delayed(const Duration(milliseconds: 200));

      // S (три короткие)
      for (int i = 0; i < 3; i++) {
        await HapticFeedback.lightImpact();
        await Future.delayed(const Duration(milliseconds: 100));
      }
      debugPrint('📳 Vibration: SOS');
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }

  // Пульсирующая вибрация для близкой опасности
  Future<void> pulsingDanger({int pulses = 5}) async {
    if (!_isEnabled) return;
    try {
      for (int i = 0; i < pulses; i++) {
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 200));
      }
      debugPrint('📳 Vibration: pulsing danger ($pulses pulses)');
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }

  // Уведомление (одна средняя)
  Future<void> notification() async {
    await vibrate(VibrationType.medium);
  }

  // Подтверждение (две короткие быстрые)
  Future<void> confirmation() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.lightImpact();
      debugPrint('📳 Vibration: confirmation');
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }

  // Включить/выключить вибрацию
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    debugPrint('Vibration enabled: $enabled');
  }

  bool get isEnabled => _isEnabled;
}
