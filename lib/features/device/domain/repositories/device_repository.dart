import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/smart_device.dart';

abstract class DeviceRepository {
  Stream<List<SmartDevice>> scanForDevices();
  Future<Either<Failure, SmartDevice>> connectToDevice(String deviceId);
  Future<Either<Failure, void>> disconnectDevice(String deviceId);
  Stream<SmartDevice> getDeviceStatus(String deviceId);
  Future<Either<Failure, void>> sendCommand(String deviceId, String command);
}

