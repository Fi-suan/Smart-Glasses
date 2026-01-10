import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Обработчик фоновых сообщений (top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📬 Background message: ${message.notification?.title}');
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Инициализация push-уведомлений
  Future<void> initialize() async {
    try {
      // Запрос разрешений на уведомления
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Push notifications permission granted');

        // Получение FCM токена
        _fcmToken = await _firebaseMessaging.getToken();
        debugPrint('📱 FCM Token: $_fcmToken');

        // Слушаем изменения токена
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          debugPrint('📱 FCM Token refreshed: $newToken');
        });

        // Слушаем сообщения когда приложение на переднем плане
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Слушаем клики по уведомлениям когда приложение в фоне
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        // Проверяем если приложение было открыто через уведомление
        final initialMessage = await _firebaseMessaging.getInitialMessage();
        if (initialMessage != null) {
          _handleMessageOpenedApp(initialMessage);
        }

        // Регистрируем background handler
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      } else {
        debugPrint('⚠️ Push notifications permission denied');
      }
    } catch (e) {
      debugPrint('❌ Error initializing push notifications: $e');
    }
  }

  /// Обработка сообщений на переднем плане
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📬 Foreground message received');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // Здесь можно показать локальное уведомление или обновить UI
  }

  /// Обработка клика по уведомлению
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('📬 Message clicked, opening app');
    debugPrint('Data: ${message.data}');

    // Навигация в зависимости от типа уведомления
    final type = message.data['type'];
    switch (type) {
      case 'order':
        // Открыть экран заказа
        debugPrint('→ Navigate to order screen');
        break;
      case 'navigation':
        // Открыть экран навигации
        debugPrint('→ Navigate to navigation screen');
        break;
      default:
        debugPrint('→ Unknown notification type');
    }
  }

  /// Отправка тестового уведомления (через FCM API)
  Future<void> sendTestNotification(String title, String body) async {
    debugPrint('📤 Sending test notification: $title');
    // В реальном приложении это делается через backend
    // Здесь просто для демонстрации
  }

  /// Подписка на топик
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  /// Отписка от топика
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }
}
