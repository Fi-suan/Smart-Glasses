import 'package:flutter/material.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/device/presentation/pages/device_connection_page.dart';
import '../../features/navigation/presentation/pages/navigation_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String deviceConnection = '/device-connection';
  static const String navigation = '/navigation';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());

      case deviceConnection:
        return MaterialPageRoute(builder: (_) => const DeviceConnectionPage());

      case navigation:
        return MaterialPageRoute(builder: (_) => const NavigationPage());

      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsPage());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${routeSettings.name}'),
            ),
          ),
        );
    }
  }
}

