import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/smart_device.dart';
import '../repositories/device_repository.dart';

class ConnectDeviceUseCase {
  final DeviceRepository repository;

  ConnectDeviceUseCase(this.repository);

  Future<Either<Failure, SmartDevice>> call(String deviceId) async {
    return await repository.connectToDevice(deviceId);
  }
}

