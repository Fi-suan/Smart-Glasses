import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/voice_command.dart';
import '../repositories/voice_repository.dart';

class ListenVoiceUseCase {
  final VoiceRepository repository;

  ListenVoiceUseCase(this.repository);

  Future<Either<Failure, void>> startListening() async {
    return await repository.startListening();
  }

  Future<Either<Failure, void>> stopListening() async {
    return await repository.stopListening();
  }

  Stream<VoiceCommand> get commandStream => repository.voiceCommandStream;
}

