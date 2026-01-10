import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tts_service.dart';
import '../services/vibration_service.dart';
import '../services/firebase_sync_service.dart';
import '../services/auth_service.dart';
import '../features/device/data/datasources/ble_datasource.dart';
import '../features/device/data/models/smart_device_model.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TtsService _tts = TtsService();
  final VibrationService _vibration = VibrationService();
  final BleDataSource _bleDataSource = BleDataSourceImpl();
  FirebaseSyncService? _firebaseSync;

  // Настройки
  bool _ttsEnabled = true;
  double _speechRate = 0.45;
  double _volume = 1.0;
  double _pitch = 1.0;
  bool _vibrationEnabled = true;
  String _userName = 'Гость';
  String _userEmail = '';
  bool _isBluetoothConnected = false;
  String _connectedDeviceName = '';
  String? _connectedDeviceId;
  int _autoScanPeriod = 5; // Период авто-сканирования в секундах

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initFirebase();
    _loadSettings();
    _tts.speak("Настройки приложения");
  }

  Future<void> _initFirebase() async {
    try {
      _firebaseSync = FirebaseSyncService();
      debugPrint('✅ FirebaseSync initialized in settings');
    } catch (e) {
      debugPrint('⚠️ FirebaseSync not available: $e');
      _firebaseSync = null;
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Загружаем данные пользователя из AuthService
      final userData = await AuthService().getCurrentUser();

      setState(() {
        _ttsEnabled = prefs.getBool('tts_enabled') ?? true;
        _speechRate = prefs.getDouble('speech_rate') ?? 0.45;
        _volume = prefs.getDouble('volume') ?? 1.0;
        _pitch = prefs.getDouble('pitch') ?? 1.0;
        _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
        _userName = userData['name'] ?? 'Гость';
        _userEmail = userData['email'] ?? '';
        _autoScanPeriod = prefs.getInt('auto_scan_period') ?? 5;
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
      await prefs.setInt('auto_scan_period', _autoScanPeriod);

      // Синхронизация с Firebase (если доступен)
      if (_firebaseSync != null) {
        try {
          await _firebaseSync!.saveSettings(
            ttsEnabled: _ttsEnabled,
            speechRate: _speechRate,
            volume: _volume,
            pitch: _pitch,
            vibrationEnabled: _vibrationEnabled,
            userName: _userName,
          );
        } catch (e) {
          debugPrint('⚠️ Firebase sync error: $e');
        }
      }

      await _vibration.success();
      _tts.speak("Настройки сохранены");
    } catch (e) {
      debugPrint("Error saving settings: $e");
      await _vibration.error();
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
                subtitle: Text(
                  _userEmail.isNotEmpty ? _userEmail : 'Email не указан',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                onTap: () {
                  _vibration.buttonPress();
                  _tts.speak("Профиль: $_userName. Email: ${_userEmail.isNotEmpty ? _userEmail : 'не указан'}");
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
                  _tts.setSpeechRate(value); // Применяем сразу
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
                  _tts.setVolume(value); // Применяем сразу
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
                  _tts.setPitch(value); // Применяем сразу
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

          // Авто-сканирование препятствий
          _buildSection(
            title: 'Авто-сканирование',
            icon: Icons.camera_alt,
            children: [
              ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('Период сканирования'),
                subtitle: Text('$_autoScanPeriod секунд'),
                onTap: () {
                  _vibration.buttonPress();
                  _tts.speak("Период сканирования $_autoScanPeriod секунд");
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPeriodButton(3),
                    _buildPeriodButton(5),
                    _buildPeriodButton(10),
                  ],
                ),
              ),
              const SizedBox(height: 8),
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
                      ? _connectedDeviceName.isEmpty ? 'Устройство' : _connectedDeviceName
                      : 'Нажмите для подключения',
                ),
                trailing: _isBluetoothConnected
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () async {
                          if (_connectedDeviceId != null) {
                            try {
                              await _bleDataSource.disconnectDevice(_connectedDeviceId!);
                            } catch (e) {
                              debugPrint('Error disconnecting: $e');
                            }
                          }
                          setState(() {
                            _isBluetoothConnected = false;
                            _connectedDeviceId = null;
                            _connectedDeviceName = '';
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

  Widget _buildPeriodButton(int seconds) {
    final isSelected = _autoScanPeriod == seconds;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _autoScanPeriod = seconds;
            });
            _vibration.buttonPress();
            _tts.speak("Период $seconds секунд");
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            foregroundColor: isSelected ? Colors.white : Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            '$seconds сек',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
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
    _tts.speak("Поиск устройств");

    showDialog(
      context: context,
      builder: (context) => _BluetoothScanDialog(
        bleDataSource: _bleDataSource,
        tts: _tts,
        vibration: _vibration,
        onDeviceConnected: (deviceId, deviceName) {
          setState(() {
            _isBluetoothConnected = true;
            _connectedDeviceId = deviceId;
            _connectedDeviceName = deviceName;
          });
        },
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
            onPressed: () async {
              Navigator.pop(context);
              _vibration.buttonPress();
              _tts.speak("Выход выполнен");

              // Реальный выход из Firebase Auth
              await AuthService().logout();

              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
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

// Виджет для сканирования и подключения BLE устройств
class _BluetoothScanDialog extends StatefulWidget {
  final BleDataSource bleDataSource;
  final TtsService tts;
  final VibrationService vibration;
  final Function(String deviceId, String deviceName) onDeviceConnected;

  const _BluetoothScanDialog({
    required this.bleDataSource,
    required this.tts,
    required this.vibration,
    required this.onDeviceConnected,
  });

  @override
  State<_BluetoothScanDialog> createState() => _BluetoothScanDialogState();
}

class _BluetoothScanDialogState extends State<_BluetoothScanDialog> {
  List<SmartDeviceModel> _devices = [];
  bool _isScanning = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    try {
      await for (final devices in widget.bleDataSource.scanForDevices()) {
        if (mounted) {
          setState(() {
            _devices = devices;
          });

          if (devices.isNotEmpty) {
            final deviceNames = devices.map((d) => d.name).join(', ');
            widget.tts.speak("Доступные устройства: $deviceNames");
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });

        if (e.toString().contains('Bluetooth is turned off')) {
          widget.tts.speak("Bluetooth отключен");
        } else if (e.toString().contains('permissions')) {
          widget.tts.speak("Необходимы разрешения Bluetooth");
        } else {
          widget.tts.speak("Ошибка поиска устройств");
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _connectToDevice(SmartDeviceModel device) async {
    widget.vibration.buttonPress();
    widget.tts.speak("Подключение к ${device.name}");

    try {
      final connectedDevice = await widget.bleDataSource.connectToDevice(device.id);

      if (mounted) {
        Navigator.pop(context);
        await widget.vibration.confirmation();
        widget.tts.speak("Подключено к ${connectedDevice.name}");
        widget.onDeviceConnected(device.id, device.name);
      }
    } catch (e) {
      if (mounted) {
        await widget.vibration.error();
        widget.tts.speak("Не удалось подключиться. ${e.toString()}");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка подключения: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Подключение Bluetooth'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isScanning) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Поиск устройств...'),
            ],
            if (_errorMessage != null) ...[
              Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _getErrorMessage(_errorMessage!),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            if (_devices.isEmpty && !_isScanning && _errorMessage == null) ...[
              const Icon(Icons.bluetooth_disabled, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Устройства не найдены'),
            ],
            if (_devices.isNotEmpty) ...[
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    return ListTile(
                      leading: const Icon(Icons.bluetooth),
                      title: Text(device.name),
                      subtitle: Text('RSSI: ${device.rssi} dBm'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _connectToDevice(device),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.vibration.buttonPress();
            widget.tts.announceButton("Отмена");
            Navigator.pop(context);
          },
          child: const Text('Отмена'),
        ),
        if (_errorMessage != null || (_devices.isEmpty && !_isScanning))
          TextButton(
            onPressed: _startScan,
            child: const Text('Повторить'),
          ),
      ],
    );
  }

  String _getErrorMessage(String error) {
    if (error.contains('Bluetooth is turned off')) {
      return 'Включите Bluetooth в настройках устройства';
    } else if (error.contains('permissions')) {
      return 'Необходимы разрешения Bluetooth.\nПредоставьте их в настройках приложения.';
    } else if (error.contains('not supported')) {
      return 'Bluetooth не поддерживается на этом устройстве';
    }
    return 'Ошибка: $error';
  }
}
