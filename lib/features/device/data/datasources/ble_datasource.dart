import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/smart_device_model.dart';
import '../../../../core/utils/logger.dart';

// ESP32 BLE Service and Characteristics UUIDs
// These match the ESP32 firmware: esp32_firmware/smartglasses_esp32.ino
class ESP32UUIDs {
  static const String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String txCharUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8"; // ESP32 -> Phone (Notify)
  static const String rxCharUUID = "beb5483f-36e1-4688-b7f5-ea07361b26a9"; // Phone -> ESP32 (Write)
  static const String statusCharUUID = "beb54840-36e1-4688-b7f5-ea07361b26aa"; // Status (Read/Notify)
  static const String batteryCharUUID = "beb54841-36e1-4688-b7f5-ea07361b26ab"; // Battery (Read/Notify)
}

abstract class BleDataSource {
  Stream<List<SmartDeviceModel>> scanForDevices();
  Future<SmartDeviceModel> connectToDevice(String deviceId);
  Future<void> disconnectDevice(String deviceId);
  Stream<SmartDeviceModel> getDeviceStatus(String deviceId);
  Future<void> sendCommand(String deviceId, String command, {Map<String, dynamic>? data});
  Stream<Map<String, dynamic>> listenToResponses(String deviceId);
  Future<int?> getBatteryLevel(String deviceId);
}

class BleDataSourceImpl implements BleDataSource {
  final _scanController = StreamController<List<SmartDeviceModel>>.broadcast();
  final Map<String, BluetoothDevice> _discoveredDevices = {};
  final Map<String, BluetoothDevice> _connectedDevices = {};
  final Map<String, BluetoothCharacteristic> _txCharacteristics = {};
  final Map<String, BluetoothCharacteristic> _rxCharacteristics = {};
  final Map<String, BluetoothCharacteristic> _statusCharacteristics = {};
  final Map<String, BluetoothCharacteristic> _batteryCharacteristics = {};
  final Map<String, StreamController<Map<String, dynamic>>> _responseControllers = {};

  @override
  Stream<List<SmartDeviceModel>> scanForDevices() async* {
    try {
      // Request Bluetooth permissions
      final bluetoothStatus = await Permission.bluetooth.request();
      final bluetoothScanStatus = await Permission.bluetoothScan.request();
      final bluetoothConnectStatus = await Permission.bluetoothConnect.request();

      if (!bluetoothStatus.isGranted ||
          !bluetoothScanStatus.isGranted ||
          !bluetoothConnectStatus.isGranted) {
        AppLogger.warning('Bluetooth permissions not granted');
        throw Exception('Bluetooth permissions required');
      }

      // Check if Bluetooth is available
      if (await FlutterBluePlus.isSupported == false) {
        throw Exception('Bluetooth not supported');
      }

      // Check if Bluetooth is turned on
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        throw Exception('Bluetooth is turned off');
      }

      _discoveredDevices.clear();

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );

      // Listen to scan results
      yield* FlutterBluePlus.scanResults.map((results) {
        for (var result in results) {
          _discoveredDevices[result.device.remoteId.toString()] = result.device;
        }

        return results.map((result) {
          return SmartDeviceModel(
            id: result.device.remoteId.toString(),
            name: result.device.platformName.isEmpty
                ? 'Unknown Device'
                : result.device.platformName,
            rssi: result.rssi,
          );
        }).toList();
      });
    } catch (e) {
      AppLogger.error('BLE scan error', e);
      rethrow;
    }
  }

  @override
  Future<SmartDeviceModel> connectToDevice(String deviceId) async {
    try {
      final device = _discoveredDevices[deviceId];
      if (device == null) {
        throw Exception('Device not found');
      }

      AppLogger.info('Connecting to device: ${device.platformName}');

      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevices[deviceId] = device;

      // Discover services
      final services = await device.discoverServices();

      // Find ESP32 Smart Glasses service and characteristics
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == ESP32UUIDs.serviceUUID.toLowerCase()) {
          AppLogger.info('Found Smart Glasses service!');

          for (var characteristic in service.characteristics) {
            final charUuid = characteristic.uuid.toString().toLowerCase();

            // TX Characteristic (ESP32 -> Phone)
            if (charUuid == ESP32UUIDs.txCharUUID.toLowerCase()) {
              _txCharacteristics[deviceId] = characteristic;
              await characteristic.setNotifyValue(true);
              AppLogger.info('TX characteristic subscribed');

              // Listen to responses
              _responseControllers[deviceId] = StreamController<Map<String, dynamic>>.broadcast();
              characteristic.lastValueStream.listen((bytes) {
                if (bytes.isNotEmpty) {
                  try {
                    final jsonStr = utf8.decode(bytes);
                    final response = jsonDecode(jsonStr) as Map<String, dynamic>;
                    AppLogger.info('Received from ESP32: $response');
                    _responseControllers[deviceId]?.add(response);
                  } catch (e) {
                    AppLogger.error('Failed to decode response', e);
                  }
                }
              });
            }

            // RX Characteristic (Phone -> ESP32)
            else if (charUuid == ESP32UUIDs.rxCharUUID.toLowerCase()) {
              _rxCharacteristics[deviceId] = characteristic;
              AppLogger.info('RX characteristic found');
            }

            // Status Characteristic
            else if (charUuid == ESP32UUIDs.statusCharUUID.toLowerCase()) {
              _statusCharacteristics[deviceId] = characteristic;
              await characteristic.setNotifyValue(true);
              AppLogger.info('Status characteristic subscribed');
            }

            // Battery Characteristic
            else if (charUuid == ESP32UUIDs.batteryCharUUID.toLowerCase()) {
              _batteryCharacteristics[deviceId] = characteristic;
              await characteristic.setNotifyValue(true);
              AppLogger.info('Battery characteristic subscribed');
            }
          }
        }
      }

      if (!_txCharacteristics.containsKey(deviceId) || !_rxCharacteristics.containsKey(deviceId)) {
        throw Exception('Smart Glasses service not found on device');
      }

      AppLogger.info('Connected to Smart Glasses: ${device.platformName}');

      return SmartDeviceModel(
        id: deviceId,
        name: device.platformName,
        rssi: 0,
        connectionState: 'connected',
      );
    } catch (e) {
      AppLogger.error('Connection error', e);
      rethrow;
    }
  }

  @override
  Future<void> disconnectDevice(String deviceId) async {
    try {
      final device = _connectedDevices[deviceId];
      if (device != null) {
        await device.disconnect();
        _connectedDevices.remove(deviceId);
        AppLogger.info('Disconnected from device');
      }
    } catch (e) {
      AppLogger.error('Disconnect error', e);
      rethrow;
    }
  }

  @override
  Stream<SmartDeviceModel> getDeviceStatus(String deviceId) async* {
    final device = _connectedDevices[deviceId];
    if (device == null) {
      throw Exception('Device not connected');
    }

    yield* device.connectionState.map((state) {
      String connectionState;
      switch (state) {
        case BluetoothConnectionState.connected:
          connectionState = 'connected';
          break;
        case BluetoothConnectionState.disconnected:
          connectionState = 'disconnected';
          break;
        default:
          connectionState = 'disconnected';
      }

      return SmartDeviceModel(
        id: deviceId,
        name: device.platformName,
        rssi: 0,
        connectionState: connectionState,
      );
    });
  }

  @override
  Future<void> sendCommand(
    String deviceId,
    String command, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final rxChar = _rxCharacteristics[deviceId];
      if (rxChar == null) {
        throw Exception('Device not connected or RX characteristic not found');
      }

      // Create JSON command matching ESP32 protocol
      final commandJson = {
        'cmd': command,
        'data': data ?? {},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      final jsonString = jsonEncode(commandJson);
      final bytes = utf8.encode(jsonString);

      await rxChar.write(bytes, withoutResponse: false);
      AppLogger.info('Command sent to ESP32: $command');
    } catch (e) {
      AppLogger.error('Send command error', e);
      rethrow;
    }
  }

  @override
  Stream<Map<String, dynamic>> listenToResponses(String deviceId) {
    final controller = _responseControllers[deviceId];
    if (controller == null) {
      throw Exception('Device not connected or no response controller');
    }
    return controller.stream;
  }

  @override
  Future<int?> getBatteryLevel(String deviceId) async {
    try {
      final batteryChar = _batteryCharacteristics[deviceId];
      if (batteryChar == null) {
        return null;
      }

      final bytes = await batteryChar.read();
      if (bytes.isEmpty) return null;

      final batteryStr = utf8.decode(bytes);
      return int.tryParse(batteryStr);
    } catch (e) {
      AppLogger.error('Battery read error', e);
      return null;
    }
  }
}

