import '../../domain/entities/voice_command.dart';

class VoiceCommandModel extends VoiceCommand {
  VoiceCommandModel({
    required super.text,
    required super.confidence,
    required super.timestamp,
  }) : super(type: _parseCommandType(text));

  static CommandType _parseCommandType(String text) {
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('navigate') ||
        lowerText.contains('direction') ||
        lowerText.contains('route') ||
        lowerText.contains('go to') ||
        lowerText.contains('take me to')) {
      return CommandType.navigation;
    } else if (lowerText.contains('connect') ||
        lowerText.contains('disconnect') ||
        lowerText.contains('device') ||
        lowerText.contains('battery')) {
      return CommandType.device;
    } else if (lowerText.contains('what') ||
        lowerText.contains('how') ||
        lowerText.contains('when') ||
        lowerText.contains('where') ||
        lowerText.contains('tell me')) {
      return CommandType.assistant;
    }
    
    return CommandType.unknown;
  }

  factory VoiceCommandModel.fromJson(Map<String, dynamic> json) {
    return VoiceCommandModel(
      text: json['text'],
      confidence: json['confidence'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'type': type.toString().split('.').last,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

