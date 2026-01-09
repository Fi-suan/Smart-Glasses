import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'directions_service.dart';
import 'tts_service.dart';

class NavigationGuidanceService {
  static final NavigationGuidanceService _instance = NavigationGuidanceService._internal();
  factory NavigationGuidanceService() => _instance;

  NavigationGuidanceService._internal();

  final TtsService _tts = TtsService();
  StreamSubscription<Position>? _positionSubscription;

  DirectionsRoute? _currentRoute;
  int _currentStepIndex = 0;
  bool _isNavigating = false;

  // Дистанция для предупреждения о повороте (метры)
  static const double _warningDistance = 50.0;
  static const double _arrivalDistance = 10.0; // Считаем что прибыли
  bool _hasWarned = false;

  // Колбэки для обновления UI
  Function(int stepIndex, double distanceToNextStep)? onProgressUpdate;
  Function()? onArrival;
  Function(String instruction)? onInstructionUpdate;

  // Начать навигацию
  Future<void> startNavigation(DirectionsRoute route) async {
    try {
      _currentRoute = route;
      _currentStepIndex = 0;
      _isNavigating = true;
      _hasWarned = false;

      debugPrint('🧭 Navigation started');

      // Озвучиваем начало навигации
      await _tts.speak(
        'Маршрут построен. Расстояние ${route.totalDistance}, '
        'примерное время в пути ${route.totalDuration}. Начинаю навигацию.',
      );

      await Future.delayed(const Duration(seconds: 2));

      // Озвучиваем первую инструкцию
      if (route.steps.isNotEmpty) {
        await _announceStep(route.steps[0]);
      }

      // Начинаем отслеживание позиции
      _startPositionTracking();
    } catch (e) {
      debugPrint('❌ Error starting navigation: $e');
    }
  }

  // Остановить навигацию
  Future<void> stopNavigation() async {
    _isNavigating = false;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _currentRoute = null;
    _currentStepIndex = 0;
    _hasWarned = false;

    await _tts.speak('Навигация остановлена');
    debugPrint('🧭 Navigation stopped');
  }

  // Отслеживание позиции пользователя
  void _startPositionTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Обновление каждые 5 метров
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _onPositionUpdate(position);
    });
  }

  // Обработка обновления позиции
  void _onPositionUpdate(Position position) {
    if (!_isNavigating || _currentRoute == null) return;

    final currentLocation = LatLng(position.latitude, position.longitude);
    final currentStep = _currentRoute!.steps[_currentStepIndex];

    // Вычисляем расстояние до конца текущего шага
    final distanceToStepEnd = _calculateDistance(
      currentLocation,
      currentStep.endLocation,
    );

    debugPrint('📍 Distance to next step: ${distanceToStepEnd.toStringAsFixed(1)}m');

    // Обновляем UI
    onProgressUpdate?.call(_currentStepIndex, distanceToStepEnd);

    // Проверяем приближение к концу шага
    if (distanceToStepEnd <= _arrivalDistance) {
      _moveToNextStep();
    } else if (distanceToStepEnd <= _warningDistance && !_hasWarned) {
      _announceWarning(currentStep, distanceToStepEnd);
      _hasWarned = true;
    }
  }

  // Переход к следующему шагу
  void _moveToNextStep() async {
    if (_currentRoute == null) return;

    _currentStepIndex++;
    _hasWarned = false;

    if (_currentStepIndex >= _currentRoute!.steps.length) {
      // Маршрут завершен
      await _onNavigationComplete();
    } else {
      // Озвучиваем следующий шаг
      final nextStep = _currentRoute!.steps[_currentStepIndex];
      await _announceStep(nextStep);
    }
  }

  // Озвучка шага навигации
  Future<void> _announceStep(RouteStep step) async {
    String announcement = step.instruction;

    // Добавляем информацию о расстоянии
    if (step.distance.isNotEmpty) {
      announcement += '. Расстояние ${step.distance}';
    }

    debugPrint('🔊 Announcing: $announcement');
    await _tts.speak(announcement);

    onInstructionUpdate?.call(step.instruction);
  }

  // Озвучка предупреждения о приближении к повороту
  Future<void> _announceWarning(RouteStep step, double distance) async {
    final distanceRounded = (distance / 10).round() * 10;

    String warning = 'Через $distanceRounded метров ';

    // Определяем тип маневра
    if (step.maneuver.contains('left')) {
      warning += 'поверните налево';
    } else if (step.maneuver.contains('right')) {
      warning += 'поверните направо';
    } else if (step.maneuver.contains('straight')) {
      warning += 'продолжайте движение прямо';
    } else {
      warning += step.instruction.toLowerCase();
    }

    debugPrint('⚠️ Warning: $warning');
    await _tts.speak(warning);
  }

  // Завершение навигации
  Future<void> _onNavigationComplete() async {
    _isNavigating = false;
    await _positionSubscription?.cancel();

    await _tts.speak('Вы прибыли к месту назначения');
    debugPrint('✅ Navigation complete');

    onArrival?.call();
  }

  // Вычисление расстояния между двумя точками (в метрах)
  double _calculateDistance(LatLng from, LatLng to) {
    const earthRadius = 6371000.0; // метры

    final dLat = _toRadians(to.latitude - from.latitude);
    final dLon = _toRadians(to.longitude - from.longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(from.latitude)) *
            cos(_toRadians(to.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  // Получение текущего прогресса
  Map<String, dynamic> getProgress() {
    if (_currentRoute == null || !_isNavigating) {
      return {
        'isNavigating': false,
      };
    }

    final totalSteps = _currentRoute!.steps.length;
    final completedSteps = _currentStepIndex;

    return {
      'isNavigating': true,
      'currentStepIndex': _currentStepIndex,
      'totalSteps': totalSteps,
      'progress': completedSteps / totalSteps,
      'currentInstruction': _currentRoute!.steps[_currentStepIndex].instruction,
      'totalDistance': _currentRoute!.totalDistance,
      'totalDuration': _currentRoute!.totalDuration,
    };
  }

  // Ручное озвучивание текущей инструкции
  Future<void> repeatCurrentInstruction() async {
    if (_currentRoute != null && _isNavigating) {
      final step = _currentRoute!.steps[_currentStepIndex];
      await _announceStep(step);
    }
  }

  bool get isNavigating => _isNavigating;
  DirectionsRoute? get currentRoute => _currentRoute;
  int get currentStepIndex => _currentStepIndex;
}
