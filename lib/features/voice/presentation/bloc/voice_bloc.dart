import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/voice_command.dart';
import '../../domain/usecases/listen_voice_usecase.dart';
import '../../domain/usecases/speak_usecase.dart';
import 'voice_event.dart';
import 'voice_state.dart';
import '../../../../core/utils/logger.dart';

class VoiceBloc extends Bloc<VoiceEvent, VoiceState> {
  final ListenVoiceUseCase listenVoiceUseCase;
  final SpeakUseCase speakUseCase;
  
  StreamSubscription? _voiceCommandSubscription;

  VoiceBloc({
    required this.listenVoiceUseCase,
    required this.speakUseCase,
  }) : super(VoiceInitial()) {
    on<InitializeVoice>(_onInitializeVoice);
    on<StartListening>(_onStartListening);
    on<StopListening>(_onStopListening);
    on<SpeakText>(_onSpeakText);
    on<StopSpeaking>(_onStopSpeaking);
    on<VoiceCommandReceived>(_onVoiceCommandReceived);
  }

  Future<void> _onInitializeVoice(
    InitializeVoice event,
    Emitter<VoiceState> emit,
  ) async {
    emit(VoiceInitializing());
    
    _voiceCommandSubscription = listenVoiceUseCase.commandStream.listen(
      (command) {
        add(VoiceCommandReceived(command.text, command.confidence));
      },
      onError: (error) {
        AppLogger.error('Voice command stream error', error);
      },
    );
    
    emit(VoiceReady());
  }

  Future<void> _onStartListening(
    StartListening event,
    Emitter<VoiceState> emit,
  ) async {
    final result = await listenVoiceUseCase.startListening();
    
    result.fold(
      (failure) {
        AppLogger.error('Start listening failed: ${failure.message}');
        emit(VoiceError(failure.message));
      },
      (_) {
        emit(VoiceListening());
      },
    );
  }

  Future<void> _onStopListening(
    StopListening event,
    Emitter<VoiceState> emit,
  ) async {
    final result = await listenVoiceUseCase.stopListening();
    
    result.fold(
      (failure) => emit(VoiceError(failure.message)),
      (_) => emit(VoiceReady()),
    );
  }

  Future<void> _onSpeakText(
    SpeakText event,
    Emitter<VoiceState> emit,
  ) async {
    final result = await speakUseCase(event.text);
    
    result.fold(
      (failure) {
        AppLogger.error('Speak failed: ${failure.message}');
        emit(VoiceError(failure.message));
      },
      (_) {
        emit(VoiceSpeaking(event.text));
      },
    );
  }

  Future<void> _onStopSpeaking(
    StopSpeaking event,
    Emitter<VoiceState> emit,
  ) async {
    await speakUseCase.stop();
    emit(VoiceReady());
  }

  Future<void> _onVoiceCommandReceived(
    VoiceCommandReceived event,
    Emitter<VoiceState> emit,
  ) async {
    AppLogger.info('Voice command received: ${event.command}');
    
    // Here you would route the command to appropriate handlers
    // For now, just emit the command
    emit(VoiceCommandDetected(
      VoiceCommand(
        text: event.command,
        type: CommandType.unknown,
        confidence: event.confidence,
        timestamp: DateTime.now(),
      ),
    ));
    
    // Return to ready state after processing
    await Future.delayed(const Duration(seconds: 2));
    emit(VoiceReady());
  }

  @override
  Future<void> close() {
    _voiceCommandSubscription?.cancel();
    return super.close();
  }
}

