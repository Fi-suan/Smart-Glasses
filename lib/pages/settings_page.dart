import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tts_service.dart';
import '../services/vibration_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TtsService _tts = TtsService();
  final VibrationService _vibration = VibrationService();

  // Настройки
  bool _ttsEnabled = true;
  double _speechRate = 0.45;
  double _volume = 1.0;
  double _pitch = 1.0;
  bool _vibrationEnabled = true;
  String _userName = 'Гость';
  bool _isBluetoothConnected = false;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _tts.speak("Настройки приложения");
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _ttsEnabled = prefs.getBool('tts_enabled') ?? true;
        _speechRate = prefs.getDouble('speech_rate') ?? 0.45;
        _volume = prefs.getDouble('volume') ?? 1.0;
        _pitch = prefs.getDouble('pitch') ?? 1.0;
        _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
        _userName = prefs.getString('user_name') ?? 'Гость';
        _isLoading = false;
      });

      _tts.setEnabled(_ttsEnabled);
    } catch (e) {
      debugPrint("Error loading settings: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tts_enabled', _ttsEnabled);
      await prefs.setDouble('speech_rate', _speechRate);
      await prefs.setDouble('volume', _volume);
      await prefs.setDouble('pitch', _pitch);
      await prefs.setBool('vibration_enabled', _vibrationEnabled);
      await prefs.setString('user_name', _userName);

      _vibration.buttonPress();
      _tts.speak("Настройки сохранены");
    } catch (e) {
      debugPrint("Error saving settings: $e");
      _tts.speak("Ошибка сохранения настроек");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              _vibration.buttonPress();
              _tts.announceButton("Сохранить");
              _saveSettings();
            },
            tooltip: "Сохранить настройки",
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Профиль пользователя
          _buildSection(
            title: 'Профиль',
            icon: Icons.person,
            children: [
              ListTile(
                leading: const Icon(Icons.account_circle, size: 48),
                title: Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text('Нажмите чтобы изменить имя'),
                onTap: () {
                  _vibration.buttonPress();
                  _tts.announceButton("Изменить имя");
                  _showEditNameDialog();
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Голосовой помощник (TTS)
          _buildSection(
            title: 'Голосовой помощник',
            icon: Icons.record_voice_over,
            children: [
              SwitchListTile(
                title: const Text('Включить голос'),
                subtitle: const Text('Озвучивание всех действий'),
                value: _ttsEnabled,
                onChanged: (value) {
                  setState(() {
                    _ttsEnabled = value;
                  });
                  _tts.setEnabled(value);
                  _vibration.buttonPress();
                  if (value) {
                    _tts.speak("Голосовой помощник включен");
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.speed),
                title: const Text('Скорость речи'),
                subtitle: Text('${(_speechRate * 100).toInt()}%'),
                onTap: () {
                  _vibration.buttonPress();
                  _tts.speak("Скорость речи ${(_speechRate * 100).toInt()} процентов");
                },
              ),
              Slider(
                value: _speechRate,
                min: 0.1,
                max: 1.0,
                divisions: 18,
                label: '${(_speechRate * 100).toInt()}%',
                onChanged: (value) {
                  setState(() {
                    _speechRate = value;
                  });
                },
                onChangeEnd: (value) {
                  _tts.speak("Новая скорость");
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.volume_up),
                title: const Text('Громкость'),
                subtitle: Text('${(_volume * 100).toInt()}%'),
                onTap: () {
                  _vibration.buttonPress();
                  _tts.speak("Громкость ${(_volume * 100).toInt()} процентов");
                },
              ),
              Slider(
                value: _volume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: '${(_volume * 100).toInt()}%',
                onChanged: (value) {
                  setState(() {
                    _volume = value;
                  });
                },
                onChangeEnd: (value) {
                  _tts.speak("Новая громкость");
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.graphic_eq),
                title: const Text('Высота голоса'),
                subtitle: Text('${(_pitch * 100).toInt()}%'),
                onTap: () {
                  _vibration.buttonPress();
                  _tts.speak("Высота голоса ${(_pitch * 100).toInt()} процентов");
                },
              ),
              Slider(
                value: _pitch,
                min: 0.5,
                max: 2.0,
                divisions: 15,
                label: '${(_pitch * 100).toInt()}%',
                onChanged: (value) {
                  setState(() {
                    _pitch = value;
                  });
                },
                onChangeEnd: (value) {
                  _tts.speak("Новая высота голоса");
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Вибрация
          _buildSection(
            title: 'Вибрация',
            icon: Icons.vibration,
            children: [
              SwitchListTile(
                title: const Text('Включить вибрацию'),
                subtitle: const Text('Тактильная обратная связь'),
                value: _vibrationEnabled,
                onChanged: (value) {
                  setState(() {
                    _vibrationEnabled = value;
                  });
                  if (value) {
                    _vibration.buttonPress();
                  }
                  _tts.speak(value ? "Вибрация включена" : "Вибрация выключена");
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Bluetooth подключение
          _buildSection(
            title: 'Умные очки',
            icon: Icons.bluetooth,
            children: [
              ListTile(
                leading: Icon(
                  _isBluetoothConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                  color: _isBluetoothConnected ? Colors.blue : Colors.grey,
                ),
                title: Text(_isBluetoothConnected ? 'Подключено' : 'Не подключено'),
                subtitle: Text(
                  _isBluetoothConnected
                      ? 'SmartGlasses Pro'
                      : 'Нажмите для подключения',
                ),
                trailing: _isBluetoothConnected
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _isBluetoothConnected = false;
                          });
                          _vibration.buttonPress();
                          _tts.speak("Bluetooth отключен");
                        },
                        tooltip: "Отключить",
                      )
                    : null,
                onTap: _isBluetoothConnected
                    ? null
                    : () {
                        _vibration.buttonPress();
                        _tts.speak("Поиск устройств");
                        _showBluetoothDialog();
                      },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // О приложении
          _buildSection(
            title: 'О приложении',
            icon: Icons.info,
            children: [
              ListTile(
                leading: const Icon(Icons.apps),
                title: const Text('Версия'),
                subtitle: const Text('1.0.0'),
                onTap: () {
                  _vibration.buttonPress();
                  _tts.speak("Версия приложения один ноль ноль");
                },
              ),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Помощь'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _vibration.buttonPress();
                  _tts.announceButton("Помощь");
                  Navigator.pushNamed(context, '/help');
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Кнопка выхода
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                _vibration.buttonPress();
                _tts.announceButton("Выход");
                _showLogoutDialog();
              },
              icon: const Icon(Icons.logout),
              label: const Text(
                'Выйти из аккаунта',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить имя'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Ваше имя',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _vibration.buttonPress();
              _tts.announceButton("Отмена");
              Navigator.pop(context);
            },
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _userName = controller.text;
                });
                _saveSettings();
                Navigator.pop(context);
                _tts.speak("Имя изменено на ${controller.text}");
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showBluetoothDialog() {
    _tts.speak("Доступные устройства: SmartGlasses Pro, SmartGlasses Lite");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подключение Bluetooth'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Поиск устройств...'),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.bluetooth),
              title: const Text('SmartGlasses Pro'),
              subtitle: const Text('Поблизости'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                setState(() {
                  _isBluetoothConnected = true;
                });
                Navigator.pop(context);
                _vibration.buttonPress();
                _tts.speak("Подключено к SmartGlasses Pro");
              },
            ),
            ListTile(
              leading: const Icon(Icons.bluetooth),
              title: const Text('SmartGlasses Lite'),
              subtitle: const Text('Слабый сигнал'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _vibration.buttonPress();
                _tts.speak("Подключение не удалось. Устройство слишком далеко.");
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _vibration.buttonPress();
              _tts.announceButton("Отмена");
              Navigator.pop(context);
            },
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    _tts.speak("Вы уверены что хотите выйти?");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход из аккаунта'),
        content: const Text('Вы уверены что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () {
              _vibration.buttonPress();
              _tts.announceButton("Отмена");
              Navigator.pop(context);
            },
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _vibration.buttonPress();
              _tts.speak("Выход выполнен");
              // TODO: Implement actual logout with Firebase Auth
              Navigator.of(context).pushReplacementNamed('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}
