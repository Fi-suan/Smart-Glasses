import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

enum AnalysisType {
  sceneDescription, // Общее описание сцены
  textRecognition, // OCR - распознавание текста
  colorDetection, // Определение цветов
  faceRecognition, // Распознавание лиц
  crosswalkDetection, // Детекция пешеходного перехода
  obstacleWarning, // Предупреждение о препятствиях
}

class GptVisionService {
  static const String _apiKey = 'YOUR_OPENAI_API_KEY'; // TODO: Получить от пользователя или из конфига
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  // Универсальный метод анализа изображения
  Future<String> analyzeImage(
    File imageFile, {
    AnalysisType type = AnalysisType.sceneDescription,
  }) async {
    try {
      if (!hasApiKey) {
        return analyzeMock(type: type);
      }

      // Конвертируем изображение в base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final prompt = _getPromptForType(type);

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4-vision-preview',
          'messages': [
            {
              'role': 'system',
              'content': 'Ты ассистент для слепого человека. Отвечай кратко, четко и по делу. Говори на русском языке.'
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': prompt,
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image'
                  }
                }
              ]
            }
          ],
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final description = data['choices'][0]['message']['content'];
        return description;
      } else {
        debugPrint('GPT Vision API error: ${response.statusCode} ${response.body}');
        return 'Ошибка анализа изображения. Код: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('GPT Vision error: $e');
      return 'Не удалось проанализировать изображение. Проверьте подключение к интернету.';
    }
  }

  // Получить промпт для типа анализа
  String _getPromptForType(AnalysisType type) {
    switch (type) {
      case AnalysisType.sceneDescription:
        return '''Ты ассистент для слепого человека. Проанализируй изображение и дай КОМПЛЕКСНОЕ описание:

1. ПРЕПЯТСТВИЯ И ОПАСНОСТИ (если есть):
   - Опасные объекты на пути (ямы, столбы, ступени, края)
   - Расстояние до них
   - Как обойти

2. ПЕШЕХОДНЫЙ ПЕРЕХОД (если виден):
   - Есть ли зебра или светофор
   - Какой сигнал светофора
   - Безопасно ли переходить

3. ТЕКСТ (если есть):
   - Вывески, таблички, знаки
   - Прочитай текст точно как написано

4. ОБЩАЯ СЦЕНА:
   - Что впереди (улица, помещение, площадь)
   - Основные объекты и их расположение
   - Примерные расстояния

5. ЛЮДИ (если есть):
   - Сколько людей и где они находятся

Отвечай кратко и по делу на русском языке. Начинай с самого важного - опасностей и препятствий.''';

      case AnalysisType.textRecognition:
        return 'Прочитай весь текст который видишь на изображении. Укажи что это: вывеска, меню, ценник, знак и т.д. Произнеси текст точно как написано.';

      case AnalysisType.colorDetection:
        return 'Опиши цвета всех объектов на изображении. Укажи основные цвета для каждого видимого предмета.';

      case AnalysisType.faceRecognition:
        return 'Есть ли на изображении люди? Сколько человек? Опиши их расположение и примерное расстояние.';

      case AnalysisType.crosswalkDetection:
        return 'Есть ли на изображении пешеходный переход (зебра)? Есть ли светофор? Какой сигнал светофора? Безопасно ли переходить дорогу сейчас?';

      case AnalysisType.obstacleWarning:
        return 'КРИТИЧЕСКИ ВАЖНО: Есть ли препятствия на пути? Опиши все опасности: ямы, столбы, ступени, края платформы, открытые люки и т.д. Укажи расстояние до препятствий.';
    }
  }

  // Специализированные методы для удобства

  Future<String> describeScene(File imageFile) async {
    return analyzeImage(imageFile, type: AnalysisType.sceneDescription);
  }

  Future<String> recognizeText(File imageFile) async {
    return analyzeImage(imageFile, type: AnalysisType.textRecognition);
  }

  Future<String> detectColors(File imageFile) async {
    return analyzeImage(imageFile, type: AnalysisType.colorDetection);
  }

  Future<String> recognizeFaces(File imageFile) async {
    return analyzeImage(imageFile, type: AnalysisType.faceRecognition);
  }

  Future<String> checkCrosswalk(File imageFile) async {
    return analyzeImage(imageFile, type: AnalysisType.crosswalkDetection);
  }

  Future<String> detectObstacles(File imageFile) async {
    return analyzeImage(imageFile, type: AnalysisType.obstacleWarning);
  }

  // Mock версия для тестирования без API ключа
  Future<String> analyzeMock({AnalysisType type = AnalysisType.sceneDescription}) async {
    await Future.delayed(const Duration(seconds: 2)); // Имитация задержки API

    switch (type) {
      case AnalysisType.sceneDescription:
        final mockScenes = [
          '''ПРЕПЯТСТВИЯ: Путь свободен, препятствий не обнаружено.

ПЕРЕХОД: Впереди пешеходный переход через 3 метра. Светофора нет. Осторожно проверьте движение.

ТЕКСТ: Вывеска "Магазин Продукты 24/7" справа.

СЦЕНА: Вы на тротуаре. Справа здание с синим фасадом. Слева дерево. Прямо ровная дорога.''',

          '''ОПАСНОСТЬ! Лестница вниз в 2 метрах. 5 ступеней. Есть перила слева.

ПЕРЕХОД: Пешеходного перехода не видно.

СЦЕНА: Входная зона здания. За лестницей входная дверь.''',

          '''ПРЕПЯТСТВИЯ: Столб прямо по курсу в 3 метрах. Обойдите справа.

ПЕРЕХОД: Перекресток впереди. Светофор показывает КРАСНЫЙ сигнал. Ждите зеленого.

ТЕКСТ: Знак "Остановка общественного транспорта".

СЦЕНА: Городской перекресток. Справа припаркованы автомобили. 2 человека справа на остановке.''',

          '''ПРЕПЯТСТВИЯ: Путь свободен.

СЦЕНА: Помещение, коридор шириной 2 метра. Слева стена, справа окна. Пол ровный.''',

          '''ПРЕПЯТСТВИЯ: Путь свободен.

СЦЕНА: Открытая площадка. В 10 метрах фонтан. Вокруг скамейки. 3-4 человека впереди слева.''',
        ];
        return mockScenes[(DateTime.now().second) % mockScenes.length];

      case AnalysisType.textRecognition:
        final mockTexts = [
          'Вывеска магазина: "Продукты 24/7". Режим работы: круглосуточно.',
          'Меню кафе: Кофе - 150 руб, Чай - 100 руб, Круассан - 120 руб.',
          'Ценник: Молоко 3.2% - 89 рублей за литр. Скидка -10%.',
          'Дорожный знак: "Пешеходный переход". Стрелка указывает налево.',
          'Табличка на двери: "Вход. Режим работы: 9:00 - 21:00"',
        ];
        return mockTexts[(DateTime.now().second) % mockTexts.length];

      case AnalysisType.colorDetection:
        final mockColors = [
          'Основные цвета: Машина красного цвета справа. Здание серое. Дорога темно-серая. Небо голубое.',
          'Дверь синяя. Стены белые. Пол коричневый. Табличка зеленая.',
          'Светофор: верхний красный сигнал. Зебра белая с черными полосами.',
          'Одежда человека: синяя куртка, черные брюки, белая рубашка.',
        ];
        return mockColors[(DateTime.now().second) % mockColors.length];

      case AnalysisType.faceRecognition:
        final mockFaces = [
          'На изображении 2 человека. Один человек в 3 метрах слева, второй в 5 метрах прямо.',
          'Один человек прямо перед вами на расстоянии около 2 метров.',
          'Людей не обнаружено на изображении.',
          'Группа из 4 человек справа на расстоянии 7-8 метров.',
        ];
        return mockFaces[(DateTime.now().second) % mockFaces.length];

      case AnalysisType.crosswalkDetection:
        final mockCrosswalks = [
          'Да, пешеходный переход прямо перед вами. Светофор показывает ЗЕЛЕНЫЙ сигнал. Безопасно переходить.',
          'Пешеходный переход справа в 5 метрах. Светофор КРАСНЫЙ. Подождите зеленого сигнала.',
          'Пешеходный переход не обнаружен. Светофора нет.',
          'Зебра прямо. Светофора нет. Осторожно проверьте движение транспорта.',
        ];
        return mockCrosswalks[(DateTime.now().second) % mockCrosswalks.length];

      case AnalysisType.obstacleWarning:
        final mockObstacles = [
          'ВНИМАНИЕ! Столб в 2 метрах прямо по курсу. Обойдите справа.',
          'ОПАСНО! Лестница вниз в 1.5 метрах. 3 ступени. Есть перила слева.',
          'ПРЕПЯТСТВИЕ! Открытый люк на тротуаре в 4 метрах. Обойдите слева.',
          'Путь свободен. Препятствий не обнаружено.',
          'ВНИМАНИЕ! Низкий навес в 3 метрах. Высота 1.7 метра. Пригнитесь.',
        ];
        return mockObstacles[(DateTime.now().second) % mockObstacles.length];
    }
  }

  // Проверка наличия API ключа
  bool get hasApiKey => _apiKey != 'YOUR_OPENAI_API_KEY';
}
