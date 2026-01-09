import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../services/vibration_service.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final TtsService _tts = TtsService();
  final VibrationService _vibration = VibrationService();

  @override
  void initState() {
    super.initState();
    _tts.speak("Справка и помощь. Здесь вы найдете ответы на частые вопросы и инструкции.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Справка'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _vibration.buttonPress();
            _tts.announceButton("Назад");
            Navigator.pop(context);
          },
          tooltip: "Назад",
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Вступление
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Добро пожаловать!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Это приложение помогает незрячим людям ориентироваться в пространстве с помощью AI и голосового помощника.',
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Основные функции
          _buildSection(
            title: 'Основные функции',
            icon: Icons.apps,
            items: [
              _HelpItem(
                icon: Icons.navigation,
                title: 'Навигация',
                description:
                    'Построение маршрутов с голосовыми подсказками. Скажите "Построй маршрут до [адрес]" или введите адрес вручную.',
              ),
              _HelpItem(
                icon: Icons.camera_alt,
                title: 'Что впереди?',
                description:
                    'AI камера анализирует сцену и сообщает о препятствиях, переходах, текстах и объектах. Нажмите большую кнопку для анализа.',
              ),
              _HelpItem(
                icon: Icons.shopping_bag,
                title: 'Магазин',
                description:
                    'Каталог умных устройств для незрячих: очки, трости, часы. Добавляйте товары в корзину и оформляйте заказ.',
              ),
              _HelpItem(
                icon: Icons.settings,
                title: 'Настройки',
                description:
                    'Управление голосовым помощником, вибрацией, подключение Bluetooth устройств.',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // FAQ
          _buildSection(
            title: 'Частые вопросы',
            icon: Icons.help,
            items: [
              _HelpItem(
                icon: Icons.record_voice_over,
                title: 'Как включить/выключить голос?',
                description:
                    'Зайдите в Настройки → Голосовой помощник → Включить голос. Там же можно настроить скорость, громкость и высоту голоса.',
              ),
              _HelpItem(
                icon: Icons.bluetooth,
                title: 'Как подключить умные очки?',
                description:
                    'Зайдите в Настройки → Умные очки → Нажмите на "Не подключено" → Выберите устройство из списка.',
              ),
              _HelpItem(
                icon: Icons.map,
                title: 'Почему не строится маршрут?',
                description:
                    'Убедитесь что GPS включен и вы дали разрешение на геолокацию. Также проверьте интернет-соединение.',
              ),
              _HelpItem(
                icon: Icons.camera,
                title: 'AI камера не работает?',
                description:
                    'Дайте разрешение на доступ к камере. Если используете MOCK режим (без API ключа), анализ будет тестовым.',
              ),
              _HelpItem(
                icon: Icons.battery_alert,
                title: 'Как экономить батарею?',
                description:
                    'Отключите вибрацию в настройках, используйте навигацию только при необходимости, закрывайте камеру после использования.',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Советы
          _buildSection(
            title: 'Полезные советы',
            icon: Icons.tips_and_updates,
            items: [
              _HelpItem(
                icon: Icons.touch_app,
                title: 'Тройное касание',
                description:
                    'Во многих экранах тройное касание по экрану активирует главную функцию (навигация, камера).',
              ),
              _HelpItem(
                icon: Icons.vibration,
                title: 'Вибрация',
                description:
                    'Короткая вибрация = нажатие кнопки. Длинная вибрация = обнаружено препятствие. Частая вибрация = ошибка.',
              ),
              _HelpItem(
                icon: Icons.volume_up,
                title: 'Голосовые команды',
                description:
                    'Говорите четко и ждите завершения фразы помощника перед новой командой.',
              ),
              _HelpItem(
                icon: Icons.shopping_cart,
                title: 'Корзина магазина',
                description:
                    'В магазине нажмите на карточку товара чтобы услышать описание. Нажмите на кнопку внизу чтобы добавить в корзину.',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Контакты
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.support_agent,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Поддержка',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildContactItem(Icons.email, 'Email', 'support@smartglasses.com'),
                  const SizedBox(height: 12),
                  _buildContactItem(Icons.phone, 'Телефон', '+7 (800) 555-35-35'),
                  const SizedBox(height: 12),
                  _buildContactItem(Icons.schedule, 'Время работы', 'Пн-Пт: 9:00-18:00'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Кнопка обратной связи
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                _vibration.buttonPress();
                _tts.speak("Отправка отзыва. Функция в разработке.");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Функция отправки отзыва будет добавлена в следующей версии'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              icon: const Icon(Icons.feedback),
              label: const Text(
                'Отправить отзыв',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Версия
          Center(
            child: Text(
              'Версия 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
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
    required List<_HelpItem> items,
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
          ...items.map((item) => _buildHelpItem(item)),
        ],
      ),
    );
  }

  Widget _buildHelpItem(_HelpItem item) {
    return InkWell(
      onTap: () {
        _vibration.buttonPress();
        _tts.speak("${item.title}. ${item.description}");
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              item.icon,
              color: Theme.of(context).colorScheme.secondary,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return InkWell(
      onTap: () {
        _vibration.buttonPress();
        _tts.speak("$label: $value");
      },
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HelpItem {
  final IconData icon;
  final String title;
  final String description;

  _HelpItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
