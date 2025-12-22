import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/smart_device_model.dart';
import '../../../../core/utils/logger.dart';

abstract class BleDataSource {
  Stream<List<SmartDeviceModel>> scanForDevices();
  Future<SmartDeviceModel> connectToDevice(String deviceId);
  Future<void> disconnectDevice(String deviceId);
  Stream<SmartDeviceModel> getDeviceStatus(String deviceId);
  Future<void> sendCommand(String deviceId, String command);
}

class BleDataSourceImpl implements BleDataSource {
  final _scanController = StreamController<List<SmartDeviceModel>>.broadcast();
  final Map<String, BluetoothDevice> _discoveredDevices = {};
  final Map<String, BluetoothDevice> _connectedDevices = {};

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
      await device.discoverServices();

      AppLogger.info('Connected to device: ${device.platformName}');

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
  Future<void> sendCommand(String deviceId, String command) async {
    try {
      final device = _connectedDevices[deviceId];
      if (device == null) {
        throw Exception('Device not connected');
      }

      // Find the command characteristic (you'll need to replace with actual UUIDs)
      final services = await device.discoverServices();
      
      // This is a placeholder - replace with your actual service/characteristic UUIDs
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            await characteristic.write(command.codeUnits);
            AppLogger.info('Command sent: $command');
            return;
          }
        }
      }

      throw Exception('No writable characteristic found');
    } catch (e) {
      AppLogger.error('Send command error', e);
      rethrow;
    }
  }
}

