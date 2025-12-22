import 'package:equatable/equatable.dart';
import '../../domain/entities/smart_device.dart';

abstract class DeviceState extends Equatable {
  const DeviceState();

  @override
  List<Object?> get props => [];
}

class DeviceInitial extends DeviceState {}

class DeviceScanning extends DeviceState {
  final List<SmartDevice> devices;

  const DeviceScanning(this.devices);

  @override
  List<Object> get props => [devices];
}

class DeviceConnecting extends DeviceState {
  final String deviceId;

  const DeviceConnecting(this.deviceId);

  @override
  List<Object> get props => [deviceId];
}

class DeviceConnected extends DeviceState {
  final SmartDevice device;

  const DeviceConnected(this.device);

  @override
  List<Object> get props => [device];
}

class DeviceDisconnected extends DeviceState {}

class DeviceError extends DeviceState {
  final String message;

  const DeviceError(this.message);

  @override
  List<Object> get props => [message];
}

