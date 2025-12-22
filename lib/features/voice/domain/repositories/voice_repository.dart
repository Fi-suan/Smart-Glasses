import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/voice_command.dart';

abstract class VoiceRepository {
  Future<Either<Failure, void>> initialize();
  Future<Either<Failure, void>> startListening();
  Future<Either<Failure, void>> stopListening();
  Stream<VoiceCommand> get voiceCommandStream;
  Future<Either<Failure, void>> speak(String text);
  Future<Either<Failure, void>> stopSpeaking();
}

