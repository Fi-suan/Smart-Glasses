import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/voice_command.dart';
import '../../domain/repositories/voice_repository.dart';
import '../datasources/voice_datasource.dart';
import '../../../../core/utils/logger.dart';

class VoiceRepositoryImpl implements VoiceRepository {
  final VoiceDataSource dataSource;

  VoiceRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, void>> initialize() async {
    try {
      await dataSource.initialize();
      return const Right(null);
    } catch (e) {
      AppLogger.error('Voice initialization error', e);
      return Left(VoiceFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> startListening() async {
    try {
      await dataSource.startListening();
      return const Right(null);
    } catch (e) {
      AppLogger.error('Start listening error', e);
      return Left(VoiceFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> stopListening() async {
    try {
      await dataSource.stopListening();
      return const Right(null);
    } catch (e) {
      AppLogger.error('Stop listening error', e);
      return Left(VoiceFailure(e.toString()));
    }
  }

  @override
  Stream<VoiceCommand> get voiceCommandStream => dataSource.voiceCommandStream;

  @override
  Future<Either<Failure, void>> speak(String text) async {
    try {
      await dataSource.speak(text);
      return const Right(null);
    } catch (e) {
      AppLogger.error('Speak error', e);
      return Left(VoiceFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> stopSpeaking() async {
    try {
      await dataSource.stopSpeaking();
      return const Right(null);
    } catch (e) {
      AppLogger.error('Stop speaking error', e);
      return Left(VoiceFailure(e.toString()));
    }
  }
}

