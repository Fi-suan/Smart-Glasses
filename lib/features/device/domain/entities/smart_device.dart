import 'package:equatable/equatable.dart';

enum DeviceConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
}

class SmartDevice extends Equatable {
  final String id;
  final String name;
  final int rssi;
  final DeviceConnectionState connectionState;
  final int? batteryLevel;

  const SmartDevice({
    required this.id,
    required this.name,
    required this.rssi,
    this.connectionState = DeviceConnectionState.disconnected,
    this.batteryLevel,
  });

  SmartDevice copyWith({
    String? id,
    String? name,
    int? rssi,
    DeviceConnectionState? connectionState,
    int? batteryLevel,
  }) {
    return SmartDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      connectionState: connectionState ?? this.connectionState,
      batteryLevel: batteryLevel ?? this.batteryLevel,
    );
  }

  @override
  List<Object?> get props => [id, name, rssi, connectionState, batteryLevel];
}

