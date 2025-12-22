import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/check_auth_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

import '../../features/device/data/datasources/ble_datasource.dart';
import '../../features/device/data/repositories/device_repository_impl.dart';
import '../../features/device/domain/repositories/device_repository.dart';
import '../../features/device/domain/usecases/connect_device_usecase.dart';
import '../../features/device/domain/usecases/scan_devices_usecase.dart';
import '../../features/device/presentation/bloc/device_bloc.dart';

import '../../features/voice/data/datasources/voice_datasource.dart';
import '../../features/voice/data/repositories/voice_repository_impl.dart';
import '../../features/voice/domain/repositories/voice_repository.dart';
import '../../features/voice/domain/usecases/listen_voice_usecase.dart';
import '../../features/voice/domain/usecases/speak_usecase.dart';
import '../../features/voice/presentation/bloc/voice_bloc.dart';

import '../../features/navigation/data/datasources/navigation_datasource.dart';
import '../../features/navigation/data/repositories/navigation_repository_impl.dart';
import '../../features/navigation/domain/repositories/navigation_repository.dart';
import '../../features/navigation/domain/usecases/start_navigation_usecase.dart';
import '../../features/navigation/presentation/bloc/navigation_bloc.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  
  // Auth
  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt(), getIt()),
  );
  getIt.registerLazySingleton(() => LoginUseCase(getIt()));
  getIt.registerLazySingleton(() => LogoutUseCase(getIt()));
  getIt.registerLazySingleton(() => CheckAuthUseCase(getIt()));
  getIt.registerFactory(() => AuthBloc(
    loginUseCase: getIt(),
    logoutUseCase: getIt(),
    checkAuthUseCase: getIt(),
  ));
  
  // Device (Bluetooth)
  getIt.registerLazySingleton<BleDataSource>(() => BleDataSourceImpl());
  getIt.registerLazySingleton<DeviceRepository>(
    () => DeviceRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton(() => ScanDevicesUseCase(getIt()));
  getIt.registerLazySingleton(() => ConnectDeviceUseCase(getIt()));
  getIt.registerFactory(() => DeviceBloc(
    scanDevicesUseCase: getIt(),
    connectDeviceUseCase: getIt(),
  ));
  
  // Voice
  getIt.registerLazySingleton<VoiceDataSource>(() => VoiceDataSourceImpl());
  getIt.registerLazySingleton<VoiceRepository>(
    () => VoiceRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton(() => ListenVoiceUseCase(getIt()));
  getIt.registerLazySingleton(() => SpeakUseCase(getIt()));
  getIt.registerFactory(() => VoiceBloc(
    listenVoiceUseCase: getIt(),
    speakUseCase: getIt(),
  ));
  
  // Navigation
  getIt.registerLazySingleton<NavigationDataSource>(
    () => NavigationDataSourceImpl(),
  );
  getIt.registerLazySingleton<NavigationRepository>(
    () => NavigationRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton(() => StartNavigationUseCase(getIt()));
  getIt.registerFactory(() => NavigationBloc(
    startNavigationUseCase: getIt(),
  ));
}

