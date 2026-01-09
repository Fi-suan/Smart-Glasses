import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/cart_service.dart';
import 'services/tts_service.dart';
import 'services/auth_service.dart';
import 'pages/navigation_page.dart';
import 'pages/camera_page.dart';
import 'pages/store_page.dart';
import 'pages/settings_page.dart';
import 'pages/help_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Инициализируем TTS сервис
  final tts = TtsService();
  await tts.initialize();

  runApp(SmartGlassesAccessibleApp(tts: tts));
}

class SmartGlassesAccessibleApp extends StatelessWidget {
  final TtsService tts;

  const SmartGlassesAccessibleApp({super.key, required this.tts});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartService(),
      child: MaterialApp(
        title: 'Smart Glasses для слепых',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          // Увеличенные размеры для доступности
          textTheme: const TextTheme(
            bodyLarge: TextStyle(fontSize: 18),
            bodyMedium: TextStyle(fontSize: 16),
            titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        home: FutureBuilder<bool>(
          future: AuthService().isLoggedIn(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.data == true) {
              return MainNavigationPage(tts: tts);
            } else {
              return const LoginPage();
            }
          },
        ),
        routes: {
          '/camera': (context) => const CameraPage(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/home': (context) => MainNavigationPage(tts: tts),
          '/help': (context) => const HelpPage(),
        },
      ),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  final TtsService tts;

  const MainNavigationPage({super.key, required this.tts});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<_NavItem> _navItems = [
    _NavItem(
      page: const NavigationPage(),
      label: 'Навигация',
      icon: Icons.navigation,
      selectedIcon: Icons.navigation,
    ),
    _NavItem(
      page: const StorePage(),
      label: 'Магазин',
      icon: Icons.shopping_bag_outlined,
      selectedIcon: Icons.shopping_bag,
    ),
    _NavItem(
      page: const SettingsPage(),
      label: 'Настройки',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
    _NavItem(
      page: const HelpPage(),
      label: 'Помощь',
      icon: Icons.help_outline,
      selectedIcon: Icons.help,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _navItems[_currentIndex].page,
      bottomNavigationBar: Consumer<CartService>(
        builder: (context, cart, child) {
          return NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              widget.tts.announceNavigation(_navItems[index].label);
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: _navItems.map((item) {
              return NavigationDestination(
                icon: Semantics(
                  label: item.label,
                  child: Icon(item.icon),
                ),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _NavItem {
  final Widget page;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  _NavItem({
    required this.page,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}
