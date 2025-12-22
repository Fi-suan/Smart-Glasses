import 'package:equatable/equatable.dart';

abstract class VoiceEvent extends Equatable {
  const VoiceEvent();

  @override
  List<Object> get props => [];
}

class InitializeVoice extends VoiceEvent {}

class StartListening extends VoiceEvent {}

class StopListening extends VoiceEvent {}

class SpeakText extends VoiceEvent {
  final String text;

  const SpeakText(this.text);

  @override
  List<Object> get props => [text];
}

class StopSpeaking extends VoiceEvent {}

class VoiceCommandReceived extends VoiceEvent {
  final String command;
  final double confidence;

  const VoiceCommandReceived(this.command, this.confidence);

  @override
  List<Object> get props => [command, confidence];
}

