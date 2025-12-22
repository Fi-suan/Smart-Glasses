import 'package:equatable/equatable.dart';

abstract class DeviceEvent extends Equatable {
  const DeviceEvent();

  @override
  List<Object> get props => [];
}

class StartScanDevices extends DeviceEvent {}

class StopScanDevices extends DeviceEvent {}

class ConnectToDevice extends DeviceEvent {
  final String deviceId;

  const ConnectToDevice(this.deviceId);

  @override
  List<Object> get props => [deviceId];
}

class DisconnectDevice extends DeviceEvent {
  final String deviceId;

  const DisconnectDevice(this.deviceId);

  @override
  List<Object> get props => [deviceId];
}

class SendDeviceCommand extends DeviceEvent {
  final String deviceId;
  final String command;

  const SendDeviceCommand(this.deviceId, this.command);

  @override
  List<Object> get props => [deviceId, command];
}

