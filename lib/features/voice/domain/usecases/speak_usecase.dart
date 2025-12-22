import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/voice_repository.dart';

class SpeakUseCase {
  final VoiceRepository repository;

  SpeakUseCase(this.repository);

  Future<Either<Failure, void>> call(String text) async {
    return await repository.speak(text);
  }

  Future<Either<Failure, void>> stop() async {
    return await repository.stopSpeaking();
  }
}

