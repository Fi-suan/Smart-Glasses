import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/scan_devices_usecase.dart';
import '../../domain/usecases/connect_device_usecase.dart';
import 'device_event.dart';
import 'device_state.dart';
import '../../../../core/utils/logger.dart';

class DeviceBloc extends Bloc<DeviceEvent, DeviceState> {
  final ScanDevicesUseCase scanDevicesUseCase;
  final ConnectDeviceUseCase connectDeviceUseCase;
  
  StreamSubscription? _scanSubscription;

  DeviceBloc({
    required this.scanDevicesUseCase,
    required this.connectDeviceUseCase,
  }) : super(DeviceInitial()) {
    on<StartScanDevices>(_onStartScanDevices);
    on<StopScanDevices>(_onStopScanDevices);
    on<ConnectToDevice>(_onConnectToDevice);
    on<DisconnectDevice>(_onDisconnectDevice);
  }

  Future<void> _onStartScanDevices(
    StartScanDevices event,
    Emitter<DeviceState> emit,
  ) async {
    try {
      await _scanSubscription?.cancel();
      
      _scanSubscription = scanDevicesUseCase().listen(
        (devices) {
          emit(DeviceScanning(devices));
        },
        onError: (error) {
          AppLogger.error('Scan error', error);
          emit(DeviceError(error.toString()));
        },
      );
    } catch (e) {
      AppLogger.error('Start scan error', e);
      emit(DeviceError(e.toString()));
    }
  }

  Future<void> _onStopScanDevices(
    StopScanDevices event,
    Emitter<DeviceState> emit,
  ) async {
    await _scanSubscription?.cancel();
    emit(DeviceInitial());
  }

  Future<void> _onConnectToDevice(
    ConnectToDevice event,
    Emitter<DeviceState> emit,
  ) async {
    emit(DeviceConnecting(event.deviceId));
    
    final result = await connectDeviceUseCase(event.deviceId);
    
    result.fold(
      (failure) {
        AppLogger.error('Connection failed: ${failure.message}');
        emit(DeviceError(failure.message));
      },
      (device) {
        AppLogger.info('Connected to: ${device.name}');
        emit(DeviceConnected(device));
      },
    );
  }

  Future<void> _onDisconnectDevice(
    DisconnectDevice event,
    Emitter<DeviceState> emit,
  ) async {
    emit(DeviceDisconnected());
  }

  @override
  Future<void> close() {
    _scanSubscription?.cancel();
    return super.close();
  }
}

