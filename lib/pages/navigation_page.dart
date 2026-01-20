import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/tts_service.dart';
import '../services/voice_command_service.dart';
import '../services/directions_service.dart';
import '../services/navigation_guidance_service.dart';
import '../services/route_history_service.dart';
import '../services/ai_navigation_service.dart';
import '../models/route_history_item.dart';

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
  final RouteHistoryService _history = RouteHistoryService();
  final AiNavigationService _aiNavigation = AiNavigationService();

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
    await _tts.speak("Слушаю. Скажите куда хотите пойти. Например: ближайшая аптека, или магазин одежды.");

    // Начинаем запись
    await _voice.startListening(
      onResult: (text) {}, // Не используется для Google STT
    );

    // Показываем диалог с анимацией записи
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blue.shade50,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mic,
                size: 64,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Слушаю...',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Скажите куда вы хотите пойти',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Например: "ближайшая аптека"\nили "где поесть?"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: Colors.blue.shade700,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                icon: const Icon(Icons.check),
                label: const Text('Готово'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      // Останавливаем запись и получаем результат
      final text = await _voice.stopListening();

      if (text != null && text.isNotEmpty) {
        debugPrint('🎤 Voice input: $text');

        setState(() {
          _destinationAddress = text;
        });

        // Передаём весь текст в AI навигацию - она сама разберётся
        await _buildRoute(text);
      } else {
        await _tts.speak("Не удалось распознать речь. Попробуйте снова.");
      }
    }
  }

  Future<void> _buildRoute(String userQuery) async {
    try {
      if (_currentPosition == null) {
        await _tts.speak("Не удалось определить ваше местоположение");
        return;
      }

      // Показываем индикатор загрузки
      setState(() {
        _currentInstruction = "Ищу место...";
      });

      await _tts.speak("Ищу $userQuery");

      // Используем AI для поиска места
      final foundPlace = await _aiNavigation.processNavigationRequest(userQuery);

      if (foundPlace == null) {
        final notFoundResponse = _aiNavigation.generateNotFoundResponse(userQuery);
        await _tts.speak(notFoundResponse);
        setState(() {
          _currentInstruction = "";
        });
        return;
      }

      // Озвучиваем найденное место
      final voiceResponse = _aiNavigation.generateVoiceResponse(foundPlace);
      await _tts.speak(voiceResponse);

      setState(() {
        _destinationAddress = foundPlace.name;
        _currentInstruction = "Строю маршрут до ${foundPlace.name}...";
      });

      // Строим маршрут до найденного места
      final origin = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      DirectionsRoute? route;

      if (_directions.hasApiKey) {
        route = await _directions.getDirections(
          origin: origin,
          destination: foundPlace.location,
        );
      } else {
        route = await _directions.getMockRoute(origin, foundPlace.location);
      }

      if (route == null) {
        await _tts.speak("Не удалось построить маршрут");
        setState(() {
          _currentInstruction = "";
        });
        return;
      }

      setState(() {
        _currentRoute = route;
        _isNavigating = true;
      });

      // Отображаем маршрут на карте
      _displayRouteOnMap(route);

      // Добавляем маркер найденного места
      _addFoundPlaceMarker(foundPlace);

      // Сохраняем маршрут в историю
      await _saveRouteToHistory(foundPlace.name, route);

      // Начинаем голосовую навигацию
      await _guidance.startNavigation(route);
    } catch (e) {
      debugPrint('Error building route: $e');
      await _tts.speak("Произошла ошибка при построении маршрута");
      setState(() {
        _currentInstruction = "";
      });
    }
  }

  void _addFoundPlaceMarker(FoundPlace place) {
    final marker = Marker(
      markerId: const MarkerId('destination'),
      position: place.location,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: place.name,
        snippet: place.distanceText,
      ),
    );

    setState(() {
      _markers.add(marker);
    });
  }

  Future<void> _saveRouteToHistory(String destination, DirectionsRoute route) async {
    try {
      final historyItem = RouteHistoryItem(
        destination: destination,
        destinationAddress: destination,
        timestamp: DateTime.now(),
        startLat: route.startLocation.latitude,
        startLng: route.startLocation.longitude,
        endLat: route.endLocation.latitude,
        endLng: route.endLocation.longitude,
        distance: route.totalDistance,
        duration: route.totalDuration,
      );

      await _history.addRoute(historyItem);
    } catch (e) {
      debugPrint('Error saving route to history: $e');
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
          Semantics(
            label: "История маршрутов",
            button: true,
            enabled: true,
            child: IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                _tts.announceButton("История маршрутов");
                _showRouteHistory();
              },
              tooltip: "История маршрутов",
            ),
          ),
          Semantics(
            label: "Ввести адрес текстом",
            button: true,
            enabled: true,
            child: IconButton(
              icon: const Icon(Icons.edit_location),
              onPressed: () {
                _tts.announceButton("Ввести адрес");
                _showAddressInput();
              },
              tooltip: "Ввести адрес",
            ),
          ),
          Semantics(
            label: "Голосовые команды. Нажмите чтобы сказать куда идти",
            button: true,
            enabled: true,
            child: IconButton(
              icon: Icon(_voice.isListening ? Icons.mic : Icons.mic_none),
              onPressed: () {
                _tts.announceButton("Голосовые команды");
                _startVoiceNavigation();
              },
              tooltip: "Голосовые команды",
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Карта (скрыта от screen reader - незрячие не видят карту)
          ExcludeSemantics(
            child: _currentPosition == null
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
                      Semantics(
                        label: "Текущая инструкция: $_currentInstruction. ${_distanceToNextStep > 0 ? 'Расстояние ${_distanceToNextStep.toStringAsFixed(0)} метров' : ''}",
                        liveRegion: true, // Обновляется в реальном времени
                        child: Container(
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
                              ExcludeSemantics(
                                child: Icon(
                                  Icons.directions,
                                  color: Colors.blue.shade700,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ExcludeSemantics(
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
                              ),
                            ],
                          ),
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
                          child: Semantics(
                            label: "Повторить текущую инструкцию",
                            hint: "Двойное нажатие повторит навигационную инструкцию",
                            button: true,
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
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Semantics(
                            label: "Остановить навигацию",
                            hint: "Двойное нажатие остановит текущий маршрут",
                            button: true,
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
                        ),
                      ],
                    ),
                  ] else ...[
                    Semantics(
                      label: "Начать навигацию. Сказать куда идти",
                      hint: "Двойное нажатие активирует голосовой ввод адреса",
                      button: true,
                      child: ElevatedButton.icon(
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
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      label: "Что впереди? Открыть AI камеру",
                      hint: "Двойное нажатие откроет камеру для анализа препятствий",
                      button: true,
                      child: OutlinedButton.icon(
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

  void _showRouteHistory() async {
    final history = await _history.getRecentRoutes(limit: 20);

    if (!mounted) return;

    if (history.isEmpty) {
      _tts.speak("История маршрутов пуста");
      return;
    }

    _tts.speak("История маршрутов. ${history.length} маршрутов");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'История маршрутов',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _tts.announceButton("Закрыть");
                      Navigator.pop(context);
                    },
                    tooltip: "Закрыть",
                  ),
                ],
              ),
            ),

            // Список маршрутов
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: history.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final item = history[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        _tts.speak("Повторить маршрут до ${item.destination}");
                        Navigator.pop(context);
                        _buildRoute(item.destination);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.place,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.destination,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.formattedDate,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (item.distance != null || item.duration != null) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (item.distance != null) ...[
                                    Icon(
                                      Icons.straighten,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.distance!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                  if (item.duration != null) ...[
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.duration!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Кнопка очистки истории
            Container(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () async {
                  _tts.announceButton("Очистить историю");
                  await _history.clearHistory();
                  Navigator.pop(context);
                  _tts.speak("История маршрутов очищена");
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Очистить историю'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddressInput() {
    final TextEditingController addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Куда вы хотите пойти?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Введите запрос',
                hintText: 'Например: ближайшая аптека',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.pop(context);
                  _buildRoute(value);
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Примеры запросов:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSuggestionChip('Ближайшая аптека', addressController),
                _buildSuggestionChip('Магазин одежды', addressController),
                _buildSuggestionChip('Где поесть?', addressController),
                _buildSuggestionChip('Банкомат Kaspi', addressController),
                _buildSuggestionChip('Кофейня рядом', addressController),
                _buildSuggestionChip('Супермаркет', addressController),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _tts.announceButton("Отмена");
              Navigator.pop(context);
            },
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final query = addressController.text;
              if (query.isNotEmpty) {
                Navigator.pop(context);
                _buildRoute(query);
              } else {
                _tts.speak("Введите запрос");
              }
            },
            child: const Text('Найти'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text, TextEditingController controller) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        controller.text = text;
      },
      backgroundColor: Colors.blue.shade50,
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
