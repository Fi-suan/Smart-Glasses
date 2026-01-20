import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Результат анализа запроса пользователя
class NavigationIntent {
  final String intentType; // 'place_search', 'direct_address', 'category_search'
  final String? placeName; // Название места (если указано)
  final String? category; // Категория (магазин одежды, аптека, и т.д.)
  final String? address; // Прямой адрес (если указан)
  final String? additionalInfo; // Дополнительная информация
  final bool needsNearby; // Нужен ли поиск ближайшего

  NavigationIntent({
    required this.intentType,
    this.placeName,
    this.category,
    this.address,
    this.additionalInfo,
    this.needsNearby = false,
  });

  factory NavigationIntent.fromJson(Map<String, dynamic> json) {
    return NavigationIntent(
      intentType: json['intent_type'] ?? 'unknown',
      placeName: json['place_name'],
      category: json['category'],
      address: json['address'],
      additionalInfo: json['additional_info'],
      needsNearby: json['needs_nearby'] ?? false,
    );
  }
}

/// Найденное место
class FoundPlace {
  final String name;
  final String address;
  final LatLng location;
  final double? distance; // в метрах
  final double? rating;
  final bool? isOpen;
  final String? placeId;

  FoundPlace({
    required this.name,
    required this.address,
    required this.location,
    this.distance,
    this.rating,
    this.isOpen,
    this.placeId,
  });

  String get distanceText {
    if (distance == null) return '';
    if (distance! < 1000) {
      return '${distance!.toStringAsFixed(0)} м';
    } else {
      return '${(distance! / 1000).toStringAsFixed(1)} км';
    }
  }
}

class AiNavigationService {
  static final AiNavigationService _instance = AiNavigationService._internal();
  factory AiNavigationService() => _instance;
  AiNavigationService._internal();

  // API ключи
  static const String _openAiApiKey =
      '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';
  static const String _googleApiKey = 'AIzaSyDHLPatV3_3xG1cdx0nvEhxCdn2XEgnzac';

  // Максимальное расстояние для поиска (15 км)
  static const double _maxSearchDistanceMeters = 15000;

  // Кэшированный город пользователя
  String? _userCity;
  LatLng? _lastKnownLocation;

  /// Основной метод - обработка произвольного запроса пользователя
  Future<FoundPlace?> processNavigationRequest(String userQuery) async {
    try {
      debugPrint('🤖 Processing navigation request: "$userQuery"');

      // 1. Получаем текущую позицию пользователя
      final position = await _getCurrentPosition();
      if (position == null) {
        debugPrint('❌ Failed to get current position');
        return null;
      }

      final userLocation = LatLng(position.latitude, position.longitude);
      _lastKnownLocation = userLocation;
      debugPrint('📍 User location: ${position.latitude}, ${position.longitude}');

      // 2. Определяем город пользователя (для более точного поиска)
      await _detectUserCity(userLocation);
      debugPrint('🏙️ User city: $_userCity');

      // 3. Анализируем запрос через GPT
      final intent = await _analyzeUserIntent(userQuery, userLocation);
      if (intent == null) {
        debugPrint('❌ Failed to analyze user intent');
        return null;
      }

      debugPrint('🎯 Intent: ${intent.intentType}');
      debugPrint('   - Place: ${intent.placeName}');
      debugPrint('   - Category: ${intent.category}');
      debugPrint('   - Address: ${intent.address}');
      debugPrint('   - Needs nearby: ${intent.needsNearby}');

      // 4. Ищем место в зависимости от типа запроса
      FoundPlace? place;

      switch (intent.intentType) {
        case 'place_search':
          // Поиск конкретного места по названию
          place = await _searchPlaceByName(
            intent.placeName ?? userQuery,
            userLocation,
          );
          break;

        case 'category_search':
          // Поиск ближайшего места по категории
          place = await _searchNearbyByCategory(
            intent.category ?? userQuery,
            userLocation,
          );
          break;

        case 'direct_address':
          // Прямой адрес - геокодируем С ГОРОДОМ
          place = await _geocodeAddress(
            intent.address ?? userQuery,
            userLocation,
          );
          break;

        default:
          // Пробуем текстовый поиск
          place = await _textSearch(userQuery, userLocation);
      }

      // 5. Проверяем что место не слишком далеко
      if (place != null && place.distance != null) {
        if (place.distance! > _maxSearchDistanceMeters) {
          debugPrint('⚠️ Place too far: ${place.distanceText}');
          // Пробуем найти ближе
          final closerPlace = await _findCloserAlternative(userQuery, userLocation);
          if (closerPlace != null) {
            place = closerPlace;
          } else {
            debugPrint('❌ No closer alternative found, rejecting result');
            return null;
          }
        }
      }

      if (place != null) {
        debugPrint('✅ Found place: ${place.name}');
        debugPrint('   Address: ${place.address}');
        debugPrint('   Distance: ${place.distanceText}');
      }

      return place;
    } catch (e) {
      debugPrint('❌ Error processing navigation request: $e');
      return null;
    }
  }

  /// Определение города пользователя через reverse geocoding
  Future<void> _detectUserCity(LatLng location) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${location.latitude},${location.longitude}'
        '&language=ru'
        '&result_type=locality'
        '&key=$_googleApiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          for (var result in data['results']) {
            for (var component in result['address_components']) {
              final types = component['types'] as List;
              if (types.contains('locality')) {
                _userCity = component['long_name'];
                debugPrint('📍 Detected city: $_userCity');
                return;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error detecting city: $e');
    }
  }

  /// Поиск более близкой альтернативы
  Future<FoundPlace?> _findCloserAlternative(
    String query,
    LatLng userLocation,
  ) async {
    debugPrint('🔍 Looking for closer alternative...');

    // Добавляем город к запросу и ищем снова
    if (_userCity != null) {
      final queryWithCity = '$query, $_userCity';
      final place = await _textSearch(queryWithCity, userLocation, strictRadius: true);
      if (place != null && place.distance != null && place.distance! <= _maxSearchDistanceMeters) {
        return place;
      }
    }

    return null;
  }

  /// Анализ намерения пользователя через GPT
  Future<NavigationIntent?> _analyzeUserIntent(
    String query,
    LatLng userLocation,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAiApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': '''Ты помощник навигации для слабовидящих людей.
Анализируй запрос пользователя и определи куда он хочет попасть.

Пользователь находится в Казахстане. Учитывай местные названия и особенности.

Верни JSON в формате:
{
  "intent_type": "place_search" | "category_search" | "direct_address",
  "place_name": "название конкретного места если указано",
  "category": "категория для поиска (аптека, магазин одежды, кафе, банк, и т.д.)",
  "address": "адрес если указан напрямую",
  "needs_nearby": true/false (нужен ли ближайший),
  "additional_info": "дополнительная информация"
}

Примеры:
- "Где ближайшая аптека?" → {"intent_type": "category_search", "category": "аптека", "needs_nearby": true}
- "Магазин одежды рядом" → {"intent_type": "category_search", "category": "магазин одежды", "needs_nearby": true}
- "Как добраться до Меги" → {"intent_type": "place_search", "place_name": "Мега", "needs_nearby": false}
- "ТРЦ Апорт" → {"intent_type": "place_search", "place_name": "ТРЦ Апорт"}
- "Улица Абая 150" → {"intent_type": "direct_address", "address": "Улица Абая 150"}
- "Хочу кофе" → {"intent_type": "category_search", "category": "кофейня", "needs_nearby": true}
- "Где поесть?" → {"intent_type": "category_search", "category": "ресторан", "needs_nearby": true}
- "Банкомат Kaspi" → {"intent_type": "place_search", "place_name": "банкомат Kaspi", "needs_nearby": true}

Отвечай ТОЛЬКО JSON без дополнительного текста.'''
            },
            {
              'role': 'user',
              'content': query,
            }
          ],
          'max_tokens': 200,
          'temperature': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'] as String;

        // Извлекаем JSON из ответа
        final jsonStr = _extractJson(content);
        if (jsonStr != null) {
          final intentJson = jsonDecode(jsonStr);
          return NavigationIntent.fromJson(intentJson);
        }
      }

      debugPrint('❌ GPT API error: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error analyzing intent: $e');
      return null;
    }
  }

  /// Поиск места по названию
  Future<FoundPlace?> _searchPlaceByName(
    String placeName,
    LatLng userLocation,
  ) async {
    try {
      // Добавляем город к запросу для точности
      String searchQuery = placeName;
      if (_userCity != null && !placeName.toLowerCase().contains(_userCity!.toLowerCase())) {
        searchQuery = '$placeName, $_userCity';
      }

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json'
        '?query=${Uri.encodeComponent(searchQuery)}'
        '&location=${userLocation.latitude},${userLocation.longitude}'
        '&radius=15000' // 15 км - строгий радиус
        '&language=ru'
        '&key=$_googleApiKey',
      );

      debugPrint('🔍 Searching place: $searchQuery');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          // Сортируем по расстоянию и выбираем ближайшее
          final results = List<Map<String, dynamic>>.from(data['results']);
          results.sort((a, b) {
            final distA = _calculateDistance(
              userLocation,
              LatLng(a['geometry']['location']['lat'], a['geometry']['location']['lng']),
            );
            final distB = _calculateDistance(
              userLocation,
              LatLng(b['geometry']['location']['lat'], b['geometry']['location']['lng']),
            );
            return distA.compareTo(distB);
          });

          // Берём ближайшее в пределах лимита
          for (var result in results) {
            final place = _parsePlace(result, userLocation);
            if (place.distance != null && place.distance! <= _maxSearchDistanceMeters) {
              return place;
            }
          }

          // Если все далеко - возвращаем ближайшее с предупреждением
          debugPrint('⚠️ All results are far, returning closest');
          return _parsePlace(results[0], userLocation);
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error searching place: $e');
      return null;
    }
  }

  /// Поиск ближайшего места по категории
  Future<FoundPlace?> _searchNearbyByCategory(
    String category,
    LatLng userLocation,
  ) async {
    try {
      // Преобразуем категорию в тип Google Places
      final placeType = _categoryToPlaceType(category);

      // Сначала пробуем nearby search с типом
      if (placeType != null) {
        final nearbyUrl = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=${userLocation.latitude},${userLocation.longitude}'
          '&rankby=distance'
          '&type=$placeType'
          '&language=ru'
          '&key=$_googleApiKey',
        );

        debugPrint('🔍 Nearby search: type=$placeType');

        final nearbyResponse = await http.get(nearbyUrl);

        if (nearbyResponse.statusCode == 200) {
          final data = jsonDecode(nearbyResponse.body);

          if (data['status'] == 'OK' && data['results'].isNotEmpty) {
            // Берём ближайшее открытое место
            for (var result in data['results']) {
              final openNow = result['opening_hours']?['open_now'];
              if (openNow == null || openNow == true) {
                return _parsePlace(result, userLocation);
              }
            }
            // Если все закрыты - берём первое
            return _parsePlace(data['results'][0], userLocation);
          }
        }
      }

      // Если по типу не нашли - пробуем текстовый поиск
      return await _textSearch('ближайший $category', userLocation);
    } catch (e) {
      debugPrint('❌ Error searching nearby: $e');
      return null;
    }
  }

  /// Текстовый поиск
  Future<FoundPlace?> _textSearch(
    String query,
    LatLng userLocation, {
    bool strictRadius = false,
  }) async {
    try {
      // Добавляем город для точности
      String searchQuery = query;
      if (_userCity != null && !query.toLowerCase().contains(_userCity!.toLowerCase())) {
        searchQuery = '$query, $_userCity';
      }

      final radius = strictRadius ? 10000 : 15000;

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json'
        '?query=${Uri.encodeComponent(searchQuery)}'
        '&location=${userLocation.latitude},${userLocation.longitude}'
        '&radius=$radius'
        '&language=ru'
        '&key=$_googleApiKey',
      );

      debugPrint('🔍 Text search: $searchQuery (radius: ${radius}m)');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          // Сортируем по расстоянию
          List<Map<String, dynamic>> results =
              List<Map<String, dynamic>>.from(data['results']);

          results.sort((a, b) {
            final distA = _calculateDistance(
              userLocation,
              LatLng(
                a['geometry']['location']['lat'],
                a['geometry']['location']['lng'],
              ),
            );
            final distB = _calculateDistance(
              userLocation,
              LatLng(
                b['geometry']['location']['lat'],
                b['geometry']['location']['lng'],
              ),
            );
            return distA.compareTo(distB);
          });

          // Берём ближайшее в пределах лимита
          for (var result in results) {
            final place = _parsePlace(result, userLocation);
            if (place.distance != null && place.distance! <= _maxSearchDistanceMeters) {
              return place;
            }
          }

          // Если strictRadius - не возвращаем далёкие результаты
          if (strictRadius) {
            return null;
          }

          return _parsePlace(results[0], userLocation);
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error in text search: $e');
      return null;
    }
  }

  /// Геокодирование адреса
  Future<FoundPlace?> _geocodeAddress(
    String address,
    LatLng userLocation,
  ) async {
    try {
      // ВАЖНО: Добавляем город к адресу для точного поиска
      String fullAddress = address;
      if (_userCity != null && !address.toLowerCase().contains(_userCity!.toLowerCase())) {
        fullAddress = '$address, $_userCity, Казахстан';
      } else {
        fullAddress = '$address, Казахстан';
      }

      // Используем bounds для ограничения поиска в радиусе 20 км от пользователя
      final latDelta = 0.18; // примерно 20 км
      final lngDelta = 0.25;

      final bounds = '${userLocation.latitude - latDelta},${userLocation.longitude - lngDelta}'
          '|${userLocation.latitude + latDelta},${userLocation.longitude + lngDelta}';

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=${Uri.encodeComponent(fullAddress)}'
        '&bounds=$bounds'
        '&language=ru'
        '&components=country:KZ'
        '&key=$_googleApiKey',
      );

      debugPrint('🔍 Geocoding: $fullAddress');
      debugPrint('   Bounds: $bounds');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          // Перебираем результаты и выбираем ближайший
          FoundPlace? bestPlace;
          double bestDistance = double.infinity;

          for (var result in data['results']) {
            final location = result['geometry']['location'];
            final placeLocation = LatLng(location['lat'], location['lng']);
            final distance = _calculateDistance(userLocation, placeLocation);

            debugPrint('   Found: ${result['formatted_address']} (${(distance/1000).toStringAsFixed(1)} км)');

            if (distance < bestDistance) {
              bestDistance = distance;
              bestPlace = FoundPlace(
                name: address,
                address: result['formatted_address'],
                location: placeLocation,
                distance: distance,
              );
            }
          }

          // Проверяем что не слишком далеко
          if (bestPlace != null && bestDistance <= _maxSearchDistanceMeters) {
            debugPrint('✅ Selected: ${bestPlace.address}');
            return bestPlace;
          } else if (bestPlace != null) {
            debugPrint('⚠️ Best result is too far: ${(bestDistance/1000).toStringAsFixed(1)} км');
            // Попробуем найти через Places API
            return await _searchPlaceByName(address, userLocation);
          }
        }
      }

      // Fallback: пробуем через Places Text Search
      debugPrint('⚠️ Geocoding failed, trying Places API...');
      return await _searchPlaceByName(address, userLocation);
    } catch (e) {
      debugPrint('❌ Error geocoding: $e');
      return null;
    }
  }

  /// Парсинг места из ответа Google Places
  FoundPlace _parsePlace(Map<String, dynamic> data, LatLng userLocation) {
    final location = LatLng(
      data['geometry']['location']['lat'],
      data['geometry']['location']['lng'],
    );

    return FoundPlace(
      name: data['name'] ?? 'Без названия',
      address: data['formatted_address'] ?? data['vicinity'] ?? '',
      location: location,
      distance: _calculateDistance(userLocation, location),
      rating: data['rating']?.toDouble(),
      isOpen: data['opening_hours']?['open_now'],
      placeId: data['place_id'],
    );
  }

  /// Преобразование категории в тип Google Places
  String? _categoryToPlaceType(String category) {
    final categoryLower = category.toLowerCase();

    final mapping = {
      // Магазины
      'магазин': 'store',
      'супермаркет': 'supermarket',
      'продукты': 'grocery_or_supermarket',
      'магазин одежды': 'clothing_store',
      'одежда': 'clothing_store',
      'обувь': 'shoe_store',
      'электроника': 'electronics_store',
      'техника': 'electronics_store',

      // Еда
      'ресторан': 'restaurant',
      'кафе': 'cafe',
      'кофейня': 'cafe',
      'кофе': 'cafe',
      'фастфуд': 'restaurant',
      'поесть': 'restaurant',
      'столовая': 'restaurant',
      'пекарня': 'bakery',

      // Здоровье
      'аптека': 'pharmacy',
      'больница': 'hospital',
      'поликлиника': 'hospital',
      'стоматология': 'dentist',
      'врач': 'doctor',

      // Финансы
      'банк': 'bank',
      'банкомат': 'atm',
      'обмен валют': 'bank',

      // Транспорт
      'автобусная остановка': 'bus_station',
      'остановка': 'transit_station',
      'метро': 'subway_station',
      'заправка': 'gas_station',
      'азс': 'gas_station',
      'парковка': 'parking',

      // Развлечения
      'кино': 'movie_theater',
      'кинотеатр': 'movie_theater',
      'парк': 'park',
      'музей': 'museum',
      'библиотека': 'library',
      'спортзал': 'gym',
      'фитнес': 'gym',

      // Услуги
      'парикмахерская': 'hair_care',
      'салон красоты': 'beauty_salon',
      'почта': 'post_office',
      'отель': 'lodging',
      'гостиница': 'lodging',

      // Образование
      'школа': 'school',
      'университет': 'university',
    };

    for (var entry in mapping.entries) {
      if (categoryLower.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Расчет расстояния между точками
  double _calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Получение текущей позиции
  Future<Position?> _getCurrentPosition() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('❌ Error getting position: $e');
      return null;
    }
  }

  /// Извлечение JSON из текста
  String? _extractJson(String text) {
    // Пробуем найти JSON в тексте
    final jsonRegex = RegExp(r'\{[\s\S]*\}');
    final match = jsonRegex.firstMatch(text);
    if (match != null) {
      return match.group(0);
    }
    return null;
  }

  /// Генерация голосового ответа о найденном месте
  String generateVoiceResponse(FoundPlace place) {
    final buffer = StringBuffer();

    buffer.write('Нашёл ${place.name}');

    if (place.distance != null) {
      buffer.write(', ${place.distanceText} от вас');
    }

    if (place.isOpen == true) {
      buffer.write('. Сейчас открыто');
    } else if (place.isOpen == false) {
      buffer.write('. Сейчас закрыто');
    }

    if (place.rating != null) {
      buffer.write('. Рейтинг ${place.rating!.toStringAsFixed(1)}');
    }

    buffer.write('. Строю маршрут.');

    return buffer.toString();
  }

  /// Генерация ответа когда место не найдено
  String generateNotFoundResponse(String query) {
    final cityInfo = _userCity != null ? ' в городе $_userCity' : ' поблизости';
    return 'Не удалось найти "$query"$cityInfo в радиусе 15 километров. '
        'Попробуйте уточнить адрес или название места.';
  }

  /// Получить текущий город пользователя
  String? get userCity => _userCity;
}
