import '../entities/smart_device.dart';
import '../repositories/device_repository.dart';

class ScanDevicesUseCase {
  final DeviceRepository repository;

  ScanDevicesUseCase(this.repository);

  Stream<List<SmartDevice>> call() {
    return repository.scanForDevices();
  }
}

