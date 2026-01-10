import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

/// Сервис распознавания речи через Google Cloud Speech-to-Text API
class GoogleSttService {
  static final GoogleSttService _instance = GoogleSttService._internal();
  factory GoogleSttService() => _instance;

  GoogleSttService._internal();

  // API ключ с включенным Speech-to-Text
  static const String _apiKey = 'AIzaSyDHLPatV3_3xG1cdx0nvEhxCdn2XEgnzac';
  static const String _apiUrl =
      'https://speech.googleapis.com/v1/speech:recognize?key=$_apiKey';

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isListening = false;
  String? _recordingPath;

  bool get isListening => _isListening;

  /// Инициализация сервиса (запрос разрешений)
  Future<bool> initialize() async {
    try {
      final micPermission = await Permission.microphone.request();
      if (micPermission.isGranted) {
        debugPrint('✅ Google STT initialized');
        return true;
      } else {
        debugPrint('⚠️ Microphone permission denied');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Google STT initialization error: $e');
      return false;
    }
  }

  /// Начать запись голоса
  Future<bool> startListening() async {
    if (_isListening) {
      debugPrint('⚠️ Already listening');
      return false;
    }

    try {
      // Проверяем разрешение
      if (!await Permission.microphone.isGranted) {
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          debugPrint('⚠️ Microphone permission denied');
          return false;
        }
      }

      // Получаем директорию для временных файлов
      final tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.wav';

      // Начинаем запись в WAV формате для Google STT
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 128000,
        ),
        path: _recordingPath!,
      );

      _isListening = true;
      debugPrint('🎤 Recording started: $_recordingPath');
      return true;
    } catch (e) {
      debugPrint('❌ Error starting recording: $e');
      _isListening = false;
      return false;
    }
  }

  /// Остановить запись и распознать речь
  Future<String?> stopListening() async {
    if (!_isListening) {
      debugPrint('⚠️ Not listening');
      return null;
    }

    try {
      // Останавливаем запись
      final path = await _audioRecorder.stop();
      _isListening = false;

      if (path == null) {
        debugPrint('⚠️ No recording path');
        return null;
      }

      debugPrint('🎤 Recording stopped: $path');

      // Читаем аудио файл
      final audioBytes = await _readAudioFile(path);
      if (audioBytes == null) {
        debugPrint('⚠️ Failed to read audio file');
        return null;
      }

      // Отправляем на распознавание
      final text = await _recognizeSpeech(audioBytes);
      return text;
    } catch (e) {
      debugPrint('❌ Error stopping recording: $e');
      _isListening = false;
      return null;
    }
  }

  /// Прочитать аудио файл
  Future<Uint8List?> _readAudioFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        debugPrint('⚠️ Audio file not found: $path');
        return null;
      }

      final bytes = await file.readAsBytes();
      debugPrint('✅ Read ${bytes.length} bytes from audio file');
      return bytes;
    } catch (e) {
      debugPrint('❌ Error reading audio file: $e');
      return null;
    }
  }

  /// Отправить аудио на Google Cloud STT
  Future<String?> _recognizeSpeech(Uint8List audioBytes) async {
    try {
      // Пропускаем WAV заголовок (44 байта) для получения чистого PCM
      final pcmData = audioBytes.sublist(44);

      // Кодируем аудио в base64
      final base64Audio = base64Encode(pcmData);

      debugPrint('🌐 Sending ${pcmData.length} bytes to Google STT...');

      // Формируем запрос
      final requestBody = {
        'config': {
          'encoding': 'LINEAR16',
          'sampleRateHertz': 16000,
          'languageCode': 'ru-RU',
          'model': 'default',
          'enableAutomaticPunctuation': true,
        },
        'audio': {
          'content': base64Audio,
        },
      };

      // Отправляем запрос
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      debugPrint('📡 Google STT response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Response data: $data');

        if (data['results'] != null && data['results'].isNotEmpty) {
          final transcript =
              data['results'][0]['alternatives'][0]['transcript'] as String;
          debugPrint('✅ Google STT result: $transcript');
          return transcript;
        } else {
          debugPrint('⚠️ No transcription results - speech may be too quiet or unclear');
          return null;
        }
      } else {
        debugPrint('❌ Google STT error: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error recognizing speech: $e');
      return null;
    }
  }

  /// Отменить запись
  Future<void> cancel() async {
    if (_isListening) {
      await _audioRecorder.stop();
      _isListening = false;
      debugPrint('🎤 Recording cancelled');
    }
  }

  /// Освободить ресурсы
  Future<void> dispose() async {
    await _audioRecorder.dispose();
  }
}
