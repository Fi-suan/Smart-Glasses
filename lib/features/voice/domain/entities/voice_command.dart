import 'package:equatable/equatable.dart';

enum CommandType {
  navigation,
  device,
  assistant,
  unknown,
}

class VoiceCommand extends Equatable {
  final String text;
  final CommandType type;
  final double confidence;
  final DateTime timestamp;

  const VoiceCommand({
    required this.text,
    required this.type,
    required this.confidence,
    required this.timestamp,
  });

  @override
  List<Object> get props => [text, type, confidence, timestamp];
}

