import 'dart:async';
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
  final _commandController = StreamController<VoiceCommandModel>.broadcast();

  bool _isInitialized = false;
  bool _isListening = false;

  @override
  Future<void> initialize() async {
    try {
      // Request microphone permission
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        AppLogger.warning('Microphone permission not granted');
      }

      _isInitialized = true;
      AppLogger.info('Voice services initialized (stub mode - speech packages disabled)');
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
      _isListening = true;
      AppLogger.info('Voice listening started (stub mode)');

      // TODO: Implement actual speech recognition when packages are re-enabled
      // For now, this is a stub implementation
    } catch (e) {
      AppLogger.error('Start listening error', e);
      rethrow;
    }
  }

  @override
  Future<void> stopListening() async {
    if (_isListening) {
      _isListening = false;
      AppLogger.info('Stopped listening');
    }
  }

  @override
  Stream<VoiceCommandModel> get voiceCommandStream => _commandController.stream;

  @override
  Future<void> speak(String text) async {
    try {
      AppLogger.info('Speaking (stub mode): $text');
      // TODO: Implement actual TTS when packages are re-enabled
    } catch (e) {
      AppLogger.error('Speak error', e);
      rethrow;
    }
  }

  @override
  Future<void> stopSpeaking() async {
    AppLogger.info('Stop speaking (stub mode)');
  }

  void dispose() {
    _commandController.close();
  }
}
