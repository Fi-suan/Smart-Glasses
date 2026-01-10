import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/route_history_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseSyncService {
  static final FirebaseSyncService _instance = FirebaseSyncService._internal();
  factory FirebaseSyncService() => _instance;

  FirebaseSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Синхронизация истории маршрутов
  Future<void> syncRouteHistory(List<RouteHistoryItem> localHistory) async {
    if (_userId == null) {
      debugPrint('⚠️ User not logged in, skipping sync');
      return;
    }

    try {
      final userDoc = _firestore.collection('users').doc(_userId);
      final routesCollection = userDoc.collection('route_history');

      // Загружаем историю с сервера
      final snapshot = await routesCollection
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      final serverHistory = snapshot.docs
          .map((doc) => RouteHistoryItem.fromJson(doc.data()))
          .toList();

      debugPrint('📡 Server history: ${serverHistory.length} items');
      debugPrint('📱 Local history: ${localHistory.length} items');

      // Объединяем локальную и серверную историю (удаляем дубликаты по timestamp)
      final Map<String, RouteHistoryItem> mergedMap = {};

      for (var item in serverHistory) {
        mergedMap[item.timestamp.toIso8601String()] = item;
      }

      for (var item in localHistory) {
        mergedMap[item.timestamp.toIso8601String()] = item;
      }

      final mergedHistory = mergedMap.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Загружаем обратно на сервер новые элементы
      for (var item in localHistory) {
        final docId = item.timestamp.millisecondsSinceEpoch.toString();
        await routesCollection.doc(docId).set(item.toJson(), SetOptions(merge: true));
      }

      debugPrint('✅ Route history synced: ${mergedHistory.length} total items');
    } catch (e) {
      debugPrint('❌ Firebase sync error: $e');
    }
  }

  // Загрузка истории с сервера
  Future<List<RouteHistoryItem>> loadRouteHistory() async {
    if (_userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('route_history')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => RouteHistoryItem.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Error loading route history: $e');
      return [];
    }
  }

  // Добавление маршрута
  Future<void> addRoute(RouteHistoryItem item) async {
    if (_userId == null) return;

    try {
      final docId = item.timestamp.millisecondsSinceEpoch.toString();
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('route_history')
          .doc(docId)
          .set(item.toJson());

      debugPrint('✅ Route added to Firestore');
    } catch (e) {
      debugPrint('❌ Error adding route: $e');
    }
  }

  // Синхронизация настроек пользователя
  Future<void> syncSettings() async {
    if (_userId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      final settingsDoc = _firestore.collection('users').doc(_userId);

      // Загружаем настройки с сервера
      final serverSettings = await settingsDoc.get();

      if (serverSettings.exists) {
        // Применяем серверные настройки
        final data = serverSettings.data()!;
        if (data['tts_enabled'] != null) {
          await prefs.setBool('tts_enabled', data['tts_enabled']);
        }
        if (data['speech_rate'] != null) {
          await prefs.setDouble('speech_rate', data['speech_rate']);
        }
        if (data['volume'] != null) {
          await prefs.setDouble('volume', data['volume']);
        }
        if (data['pitch'] != null) {
          await prefs.setDouble('pitch', data['pitch']);
        }
        if (data['vibration_enabled'] != null) {
          await prefs.setBool('vibration_enabled', data['vibration_enabled']);
        }
        if (data['user_name'] != null) {
          await prefs.setString('user_name', data['user_name']);
        }

        debugPrint('✅ Settings loaded from server');
      } else {
        // Сохраняем локальные настройки на сервер
        await _saveSettingsToServer();
      }
    } catch (e) {
      debugPrint('❌ Error syncing settings: $e');
    }
  }

  Future<void> _saveSettingsToServer() async {
    if (_userId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      await _firestore.collection('users').doc(_userId).set({
        'tts_enabled': prefs.getBool('tts_enabled') ?? true,
        'speech_rate': prefs.getDouble('speech_rate') ?? 0.45,
        'volume': prefs.getDouble('volume') ?? 1.0,
        'pitch': prefs.getDouble('pitch') ?? 1.0,
        'vibration_enabled': prefs.getBool('vibration_enabled') ?? true,
        'user_name': prefs.getString('user_name') ?? 'Гость',
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ Settings saved to server');
    } catch (e) {
      debugPrint('❌ Error saving settings: $e');
    }
  }

  // Сохранение настроек
  Future<void> saveSettings({
    bool? ttsEnabled,
    double? speechRate,
    double? volume,
    double? pitch,
    bool? vibrationEnabled,
    String? userName,
  }) async {
    if (_userId == null) return;

    try {
      final Map<String, dynamic> updates = {};

      if (ttsEnabled != null) updates['tts_enabled'] = ttsEnabled;
      if (speechRate != null) updates['speech_rate'] = speechRate;
      if (volume != null) updates['volume'] = volume;
      if (pitch != null) updates['pitch'] = pitch;
      if (vibrationEnabled != null) updates['vibration_enabled'] = vibrationEnabled;
      if (userName != null) updates['user_name'] = userName;

      updates['last_updated'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(_userId).set(updates, SetOptions(merge: true));

      debugPrint('✅ Settings saved to Firestore');
    } catch (e) {
      debugPrint('❌ Error saving settings: $e');
    }
  }

  // Очистка истории
  Future<void> clearHistory() async {
    if (_userId == null) return;

    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('route_history')
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('✅ History cleared from Firestore');
    } catch (e) {
      debugPrint('❌ Error clearing history: $e');
    }
  }

  // Проверка авторизации
  bool get isAuthenticated => _auth.currentUser != null;

  // Инициализация синхронизации при входе
  Future<void> initializeSync() async {
    if (!isAuthenticated) {
      debugPrint('⚠️ User not authenticated, skipping sync initialization');
      return;
    }

    debugPrint('🔄 Initializing Firebase sync...');
    await syncSettings();
    debugPrint('✅ Firebase sync initialized');
  }
}
