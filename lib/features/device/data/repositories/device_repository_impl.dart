import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/smart_device.dart';
import '../../domain/repositories/device_repository.dart';
import '../datasources/ble_datasource.dart';
import '../../../../core/utils/logger.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final BleDataSource bleDataSource;

  DeviceRepositoryImpl(this.bleDataSource);

  @override
  Stream<List<SmartDevice>> scanForDevices() {
    return bleDataSource.scanForDevices();
  }

  @override
  Future<Either<Failure, SmartDevice>> connectToDevice(String deviceId) async {
    try {
      final device = await bleDataSource.connectToDevice(deviceId);
      return Right(device);
    } catch (e) {
      AppLogger.error('Connect device repository error', e);
      return Left(DeviceFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> disconnectDevice(String deviceId) async {
    try {
      await bleDataSource.disconnectDevice(deviceId);
      return const Right(null);
    } catch (e) {
      AppLogger.error('Disconnect device repository error', e);
      return Left(DeviceFailure(e.toString()));
    }
  }

  @override
  Stream<SmartDevice> getDeviceStatus(String deviceId) {
    return bleDataSource.getDeviceStatus(deviceId);
  }

  @override
  Future<Either<Failure, void>> sendCommand(String deviceId, String command) async {
    try {
      await bleDataSource.sendCommand(deviceId, command);
      return const Right(null);
    } catch (e) {
      AppLogger.error('Send command repository error', e);
      return Left(DeviceFailure(e.toString()));
    }
  }
}

