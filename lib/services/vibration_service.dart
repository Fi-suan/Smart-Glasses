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

  // Вибрация при успешном действии
  Future<void> success() async {
    await vibrate(VibrationType.light);
  }

  // Вибрация при ошибке
  Future<void> error() async {
    await vibrate(VibrationType.heavy);
  }

  // Включить/выключить вибрацию
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    debugPrint('Vibration enabled: $enabled');
  }

  bool get isEnabled => _isEnabled;
}
