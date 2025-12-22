import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/voice_command_model.dart';
import '../../../../core/utils/logger.dart';

abstract class VoiceDataSource {
  Future<void> initialize();
  Future<void> startListening();
  Future<void> stopListening();
  Stream<VoiceCommandModel> get voiceCommandStream;
  Future<void> speak(String text);
  Future<void> stopSpeaking();
}

class VoiceDataSourceImpl implements VoiceDataSource {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final _commandController = StreamController<VoiceCommandModel>.broadcast();
  
  bool _isInitialized = false;
  bool _isListening = false;

  @override
  Future<void> initialize() async {
    try {
      // Request microphone permission
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        throw Exception('Microphone permission required');
      }

      // Initialize Speech to Text
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          AppLogger.error('Speech recognition error: ${error.errorMsg}');
          _commandController.addError(error.errorMsg);
        },
        onStatus: (status) {
          AppLogger.debug('Speech recognition status: $status');
          _isListening = status == 'listening';
        },
      );

      if (!_isInitialized) {
        throw Exception('Failed to initialize speech recognition');
      }

      // Initialize TTS
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      AppLogger.info('Voice services initialized');
    } catch (e) {
      AppLogger.error('Voice initialization error', e);
      rethrow;
    }
  }

  @override
  Future<void> startListening() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isListening) {
      AppLogger.warning('Already listening');
      return;
    }

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            final command = VoiceCommandModel(
              text: result.recognizedWords,
              confidence: result.confidence,
              timestamp: DateTime.now(),
            );
            _commandController.add(command);
            AppLogger.info('Voice command: ${result.recognizedWords}');
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
        cancelOnError: true,
      );
    } catch (e) {
      AppLogger.error('Start listening error', e);
      rethrow;
    }
  }

  @override
  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
      AppLogger.info('Stopped listening');
    }
  }

  @override
  Stream<VoiceCommandModel> get voiceCommandStream => _commandController.stream;

  @override
  Future<void> speak(String text) async {
    try {
      await stopSpeaking(); // Stop any ongoing speech
      await _flutterTts.speak(text);
      AppLogger.info('Speaking: $text');
    } catch (e) {
      AppLogger.error('Speak error', e);
      rethrow;
    }
  }

  @override
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  void dispose() {
    _commandController.close();
    _speechToText.stop();
    _flutterTts.stop();
  }
}

