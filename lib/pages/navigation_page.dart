import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/tts_service.dart';
import '../services/voice_command_service.dart';
import '../services/directions_service.dart';
import '../services/navigation_guidance_service.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  final TtsService _tts = TtsService();
  final VoiceCommandService _voice = VoiceCommandService();
  final DirectionsService _directions = DirectionsService();
  final NavigationGuidanceService _guidance = NavigationGuidanceService();

  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isNavigating = false;
  String _destinationAddress = "";
  DirectionsRoute? _currentRoute;
  String _currentInstruction = "";
  double _distanceToNextStep = 0;
  int _currentStepIndex = 0;

  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _getCurrentLocation();
    _setupNavigationCallbacks();
  }

  void _setupNavigationCallbacks() {
    _guidance.onProgressUpdate = (stepIndex, distanceToNextStep) {
      setState(() {
        _currentStepIndex = stepIndex;
        _distanceToNextStep = distanceToNextStep;
      });
    };

    _guidance.onInstructionUpdate = (instruction) {
      setState(() {
        _currentInstruction = instruction;
      });
    };

    _guidance.onArrival = () {
      setState(() {
        _isNavigating = false;
        _currentRoute = null;
        _polylines.clear();
        _markers.clear();
      });
    };
  }

  Future<void> _initializeServices() async {
    await _tts.initialize();
    await _voice.initialize();
    await _tts.speak("Навигация готова. Скажите куда вы хотите пойти.");
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      }
    } catch (e) {
      await _tts.speak("Не удалось получить ваше местоположение");
    }
  }

  void _startVoiceNavigation() async {
    await _tts.speak("Слушаю. Скажите адрес назначения.");

    await _voice.startListening(
      onResult: (text) async {
        setState(() {
          _destinationAddress = text;
        });
        await _tts.speak("Строю маршрут до $text");
        await _buildRoute(text);
      },
    );
  }

  Future<void> _buildRoute(String destination) async {
    try {
      if (_currentPosition == null) {
        await _tts.speak("Не удалось определить ваше местоположение");
        return;
      }

      final origin = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      DirectionsRoute? route;

      // Проверяем наличие API ключа
      if (_directions.hasApiKey) {
        // Используем реальный API
        route = await _directions.getDirectionsFromCurrentLocation(
          destinationAddress: destination,
        );
      } else {
        // Используем mock маршрут для тестирования
        await _tts.speak("Используется тестовый режим без Google API");
        // Создаем произвольную точку назначения рядом
        final mockDestination = LatLng(
          origin.latitude + 0.01,
          origin.longitude + 0.01,
        );
        route = await _directions.getMockRoute(origin, mockDestination);
      }

      if (route == null) {
        await _tts.speak("Не удалось построить маршрут");
        return;
      }

      setState(() {
        _currentRoute = route;
        _isNavigating = true;
      });

      // Отображаем маршрут на карте
      _displayRouteOnMap(route);

      // Начинаем голосовую навигацию
      await _guidance.startNavigation(route);
    } catch (e) {
      await _tts.speak("Произошла ошибка при построении маршрута");
    }
  }

  void _displayRouteOnMap(DirectionsRoute route) {
    // Добавляем polyline маршрута
    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: route.polylinePoints,
      color: Colors.blue,
      width: 5,
    );

    // Добавляем маркеры начала и конца
    final startMarker = Marker(
      markerId: const MarkerId('start'),
      position: route.startLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(title: 'Старт'),
    );

    final endMarker = Marker(
      markerId: const MarkerId('end'),
      position: route.endLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: 'Финиш'),
    );

    setState(() {
      _polylines = {polyline};
      _markers = {startMarker, endMarker};
    });

    // Настраиваем камеру чтобы показать весь маршрут
    if (_mapController != null) {
      _fitMapBounds(route.polylinePoints);
    }
  }

  void _fitMapBounds(List<LatLng> points) {
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  Future<void> _stopNavigation() async {
    await _guidance.stopNavigation();
    setState(() {
      _isNavigating = false;
      _currentRoute = null;
      _polylines.clear();
      _markers.clear();
      _currentInstruction = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Навигация',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(_voice.isListening ? Icons.mic : Icons.mic_none),
            onPressed: () {
              _tts.announceButton("Голосовые команды");
              _startVoiceNavigation();
            },
            tooltip: "Голосовые команды",
          ),
        ],
      ),
      body: Stack(
        children: [
          // Карта
          _currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    zoom: 16,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  polylines: _polylines,
                  markers: _markers,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),

          // Панель управления
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isNavigating) ...[
                    // Текущая инструкция
                    if (_currentInstruction.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.directions,
                              color: Colors.blue.shade700,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentInstruction,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                  if (_distanceToNextStep > 0) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Расстояние: ${_distanceToNextStep.toStringAsFixed(0)} м',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Информация о маршруте
                    if (_currentRoute != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Icon(Icons.straighten, size: 20),
                                const SizedBox(height: 4),
                                Text(
                                  _currentRoute!.totalDistance,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Icon(Icons.access_time, size: 20),
                                const SizedBox(height: 4),
                                Text(
                                  _currentRoute!.totalDuration,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Icon(Icons.list, size: 20),
                                const SizedBox(height: 4),
                                Text(
                                  'Шаг ${_currentStepIndex + 1}/${_currentRoute!.steps.length}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Кнопки управления
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _tts.announceButton("Повторить инструкцию");
                              _guidance.repeatCurrentInstruction();
                            },
                            icon: const Icon(Icons.replay),
                            label: const Text('Повторить'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _tts.announceButton("Остановить навигацию");
                              _stopNavigation();
                            },
                            icon: const Icon(Icons.stop),
                            label: const Text('Остановить'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        _tts.announceButton("Начать навигацию");
                        _startVoiceNavigation();
                      },
                      icon: const Icon(Icons.mic, size: 28),
                      label: const Text(
                        'Сказать куда идти',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 20,
                        ),
                        minimumSize: const Size(double.infinity, 60),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        _tts.announceButton("Открыть камеру");
                        Navigator.pushNamed(context, '/camera');
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Что впереди?'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        minimumSize: const Size(double.infinity, 54),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
