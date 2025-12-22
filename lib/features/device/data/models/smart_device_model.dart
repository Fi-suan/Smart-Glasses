import '../../domain/entities/smart_device.dart';

class SmartDeviceModel extends SmartDevice {
  const SmartDeviceModel({
    required super.id,
    required super.name,
    required super.rssi,
    String connectionState = 'disconnected',
    super.batteryLevel,
  }) : super(
          connectionState: connectionState == 'connected'
              ? DeviceConnectionState.connected
              : connectionState == 'connecting'
                  ? DeviceConnectionState.connecting
                  : connectionState == 'disconnecting'
                      ? DeviceConnectionState.disconnecting
                      : DeviceConnectionState.disconnected,
        );

  factory SmartDeviceModel.fromJson(Map<String, dynamic> json) {
    return SmartDeviceModel(
      id: json['id'],
      name: json['name'],
      rssi: json['rssi'],
      connectionState: json['connectionState'] ?? 'disconnected',
      batteryLevel: json['batteryLevel'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rssi': rssi,
      'connectionState': connectionState.toString().split('.').last,
      'batteryLevel': batteryLevel,
    };
  }
}

