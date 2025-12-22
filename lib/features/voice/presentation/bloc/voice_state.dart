import 'package:equatable/equatable.dart';
import '../../domain/entities/voice_command.dart';

abstract class VoiceState extends Equatable {
  const VoiceState();

  @override
  List<Object?> get props => [];
}

class VoiceInitial extends VoiceState {}

class VoiceInitializing extends VoiceState {}

class VoiceReady extends VoiceState {}

class VoiceListening extends VoiceState {}

class VoiceSpeaking extends VoiceState {
  final String text;

  const VoiceSpeaking(this.text);

  @override
  List<Object> get props => [text];
}

class VoiceCommandDetected extends VoiceState {
  final VoiceCommand command;

  const VoiceCommandDetected(this.command);

  @override
  List<Object> get props => [command];
}

class VoiceError extends VoiceState {
  final String message;

  const VoiceError(this.message);

  @override
  List<Object> get props => [message];
}

