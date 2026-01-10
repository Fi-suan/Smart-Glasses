import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

// Модели данных для маршрута
class DirectionsRoute {
  final List<LatLng> polylinePoints;
  final String totalDistance;
  final String totalDuration;
  final List<RouteStep> steps;
  final LatLng startLocation;
  final LatLng endLocation;

  DirectionsRoute({
    required this.polylinePoints,
    required this.totalDistance,
    required this.totalDuration,
    required this.steps,
    required this.startLocation,
    required this.endLocation,
  });
}

class RouteStep {
  final String instruction;
  final String distance;
  final String duration;
  final LatLng startLocation;
  final LatLng endLocation;
  final String maneuver; // turn-left, turn-right, straight, etc.

  RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
    required this.maneuver,
  });
}

class DirectionsService {
  static final DirectionsService _instance = DirectionsService._internal();
  factory DirectionsService() => _instance;

  DirectionsService._internal();

  static const String _apiKey = 'AIzaSyDHLPatV3_3xG1cdx0nvEhxCdn2XEgnzac';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  // Кэшированный город пользователя
  String? _userCity;

  // Получение маршрута между двумя точками
  Future<DirectionsRoute?> getDirections({
    required LatLng origin,
    required LatLng destination,
    String language = 'ru',
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=walking' // Режим пешехода
        '&language=$language'
        '&key=$_apiKey',
      );

      debugPrint('🗺️ Requesting directions: $origin -> $destination');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          return _parseDirectionsResponse(data);
        } else {
          debugPrint('❌ Directions API error: ${data['status']}');
          return null;
        }
      } else {
        debugPrint('❌ HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception in getDirections: $e');
      return null;
    }
  }

  // Получение маршрута от текущей позиции до адреса
  Future<DirectionsRoute?> getDirectionsFromCurrentLocation({
    required String destinationAddress,
  }) async {
    try {
      // Получаем текущую позицию
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final origin = LatLng(position.latitude, position.longitude);

      // Геокодируем адрес назначения с учетом текущей позиции (радиус 50 км)
      final destination = await _geocodeAddress(
        destinationAddress,
        userLocation: origin,
      );
      if (destination == null) {
        debugPrint('❌ Failed to geocode address: $destinationAddress');
        return null;
      }

      return await getDirections(
        origin: origin,
        destination: destination,
      );
    } catch (e) {
      debugPrint('❌ Exception in getDirectionsFromCurrentLocation: $e');
      return null;
    }
  }

  // Получение города пользователя по координатам
  Future<String?> _getUserCity(LatLng location) async {
    if (_userCity != null) {
      return _userCity; // Используем кэш
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${location.latitude},${location.longitude}'
        '&language=ru'
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          // Ищем компонент "locality" (город)
          for (var result in data['results']) {
            for (var component in result['address_components']) {
              final types = component['types'] as List;
              if (types.contains('locality')) {
                _userCity = component['long_name'];
                debugPrint('📍 Город пользователя: $_userCity');
                return _userCity;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error getting user city: $e');
    }

    return null;
  }

  // Геокодирование адреса в координаты с учетом текущей локации
  Future<LatLng?> _geocodeAddress(
    String address, {
    LatLng? userLocation,
  }) async {
    try {
      // Определяем город пользователя
      String? userCity;
      if (userLocation != null) {
        userCity = await _getUserCity(userLocation);
      }

      // Добавляем город к адресу если его нет и город определен
      String searchAddress = address;
      if (userCity != null &&
          !address.toLowerCase().contains(userCity.toLowerCase())) {
        searchAddress = '$address, $userCity';
      }

      // Базовый URL с адресом
      String urlString = 'https://maps.googleapis.com/maps/api/geocode/json'
          '?address=${Uri.encodeComponent(searchAddress)}'
          '&language=ru'
          '&components=country:KZ'; // Ограничиваем поиск Казахстаном

      // Добавляем location bias для поиска рядом с пользователем
      if (userLocation != null) {
        urlString += '&location=${userLocation.latitude},${userLocation.longitude}';
      }

      urlString += '&key=$_apiKey';

      final url = Uri.parse(urlString);

      debugPrint('🌍 Geocoding "$searchAddress" in Kazakhstan near ${userLocation?.latitude},${userLocation?.longitude}');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          final foundAddress = data['results'][0]['formatted_address'];
          final foundLocation = LatLng(location['lat'], location['lng']);

          // Проверяем расстояние до найденной точки
          if (userLocation != null) {
            final distance = Geolocator.distanceBetween(
              userLocation.latitude,
              userLocation.longitude,
              foundLocation.latitude,
              foundLocation.longitude,
            );

            final distanceKm = (distance / 1000).toStringAsFixed(1);
            debugPrint('📍 Found: $foundAddress ($distanceKm км)');

            // Отклоняем результаты дальше 100 км
            if (distance > 100000) {
              debugPrint('❌ Место слишком далеко ($distanceKm км > 100 км)');
              return null;
            }
          } else {
            debugPrint('✅ Found: $foundAddress');
          }

          return foundLocation;
        } else {
          debugPrint('⚠️ Geocoding status: ${data['status']}');
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Geocoding error: $e');
      return null;
    }
  }

  // Парсинг ответа от Directions API
  DirectionsRoute _parseDirectionsResponse(Map<String, dynamic> data) {
    final route = data['routes'][0];
    final leg = route['legs'][0];

    // Парсим polyline
    final polylinePoints = _decodePolyline(route['overview_polyline']['points']);

    // Парсим шаги маршрута
    final steps = <RouteStep>[];
    for (var step in leg['steps']) {
      steps.add(RouteStep(
        instruction: _stripHtmlTags(step['html_instructions']),
        distance: step['distance']['text'],
        duration: step['duration']['text'],
        startLocation: LatLng(
          step['start_location']['lat'],
          step['start_location']['lng'],
        ),
        endLocation: LatLng(
          step['end_location']['lat'],
          step['end_location']['lng'],
        ),
        maneuver: step['maneuver'] ?? 'straight',
      ));
    }

    return DirectionsRoute(
      polylinePoints: polylinePoints,
      totalDistance: leg['distance']['text'],
      totalDuration: leg['duration']['text'],
      steps: steps,
      startLocation: LatLng(
        leg['start_location']['lat'],
        leg['start_location']['lng'],
      ),
      endLocation: LatLng(
        leg['end_location']['lat'],
        leg['end_location']['lng'],
      ),
    );
  }

  // Декодирование polyline из формата Google
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  // Удаление HTML тегов из инструкций
  String _stripHtmlTags(String htmlString) {
    return htmlString
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }

  // Проверка наличия API ключа
  bool get hasApiKey => _apiKey != 'YOUR_GOOGLE_MAPS_API_KEY';

  // Mock маршрут для тестирования
  Future<DirectionsRoute> getMockRoute(LatLng origin, LatLng destination) async {
    await Future.delayed(const Duration(seconds: 1));

    return DirectionsRoute(
      polylinePoints: [
        origin,
        LatLng(origin.latitude + 0.001, origin.longitude + 0.001),
        LatLng(origin.latitude + 0.002, origin.longitude + 0.001),
        destination,
      ],
      totalDistance: '350 м',
      totalDuration: '5 мин',
      steps: [
        RouteStep(
          instruction: 'Идите прямо по улице',
          distance: '100 м',
          duration: '2 мин',
          startLocation: origin,
          endLocation: LatLng(origin.latitude + 0.001, origin.longitude + 0.001),
          maneuver: 'straight',
        ),
        RouteStep(
          instruction: 'Поверните направо',
          distance: '150 м',
          duration: '2 мин',
          startLocation: LatLng(origin.latitude + 0.001, origin.longitude + 0.001),
          endLocation: LatLng(origin.latitude + 0.002, origin.longitude + 0.001),
          maneuver: 'turn-right',
        ),
        RouteStep(
          instruction: 'Вы пришли к месту назначения',
          distance: '100 м',
          duration: '1 мин',
          startLocation: LatLng(origin.latitude + 0.002, origin.longitude + 0.001),
          endLocation: destination,
          maneuver: 'straight',
        ),
      ],
      startLocation: origin,
      endLocation: destination,
    );
  }
}
