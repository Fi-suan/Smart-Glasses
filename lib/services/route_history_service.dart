import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/route_history_item.dart';
import 'auth_service.dart';

class RouteHistoryService {
  static final RouteHistoryService _instance = RouteHistoryService._internal();
  factory RouteHistoryService() => _instance;
  RouteHistoryService._internal();

  static const String _keyRouteHistory = 'route_history';
  static const int _maxHistoryItems = 50; // Максимум записей в истории

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();

  // Получить историю маршрутов
  Future<List<RouteHistoryItem>> getHistory() async {
    try {
      // Если пользователь авторизован - берем из Firebase
      if (_auth.isLoggedIn && _auth.currentUser != null) {
        final doc = await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('route_history')
            .orderBy('timestamp', descending: true)
            .limit(_maxHistoryItems)
            .get();

        return doc.docs
            .map((doc) => RouteHistoryItem.fromJson(doc.data()))
            .toList();
      }

      // Иначе из SharedPreferences (для незалогиненных)
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyRouteHistory);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((item) => RouteHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading route history: $e');
      return [];
    }
  }

  // Добавить маршрут в историю
  Future<void> addRoute(RouteHistoryItem item) async {
    try {
      // Если пользователь авторизован - сохраняем в Firebase
      if (_auth.isLoggedIn && _auth.currentUser != null) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('route_history')
            .add(item.toJson());
        debugPrint('✅ Route added to Firebase: ${item.destination}');
        return;
      }

      // Иначе в SharedPreferences
      final history = await getHistory();
      history.insert(0, item);

      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }

      await _saveHistory(history);
      debugPrint('Route added to history: ${item.destination}');
    } catch (e) {
      debugPrint('Error adding route to history: $e');
    }
  }

  // Удалить маршрут из истории
  Future<void> removeRoute(int index) async {
    try {
      // Если пользователь авторизован - удаляем из Firebase
      if (_auth.isLoggedIn && _auth.currentUser != null) {
        final docs = await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('route_history')
            .orderBy('timestamp', descending: true)
            .get();

        if (index >= 0 && index < docs.docs.length) {
          await docs.docs[index].reference.delete();
          debugPrint('✅ Route removed from Firebase at index: $index');
        }
        return;
      }

      // Иначе удаляем из SharedPreferences
      final history = await getHistory();
      if (index >= 0 && index < history.length) {
        history.removeAt(index);
        await _saveHistory(history);
        debugPrint('Route removed from history at index: $index');
      }
    } catch (e) {
      debugPrint('Error removing route from history: $e');
    }
  }

  // Очистить всю историю
  Future<void> clearHistory() async {
    try {
      // Если пользователь авторизован - очищаем Firebase
      if (_auth.isLoggedIn && _auth.currentUser != null) {
        final docs = await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('route_history')
            .get();

        for (var doc in docs.docs) {
          await doc.reference.delete();
        }
        debugPrint('✅ Route history cleared from Firebase');
        return;
      }

      // Иначе очищаем SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyRouteHistory);
      debugPrint('Route history cleared');
    } catch (e) {
      debugPrint('Error clearing route history: $e');
    }
  }

  // Получить последние N маршрутов
  Future<List<RouteHistoryItem>> getRecentRoutes({int limit = 10}) async {
    final history = await getHistory();
    return history.take(limit).toList();
  }

  // Найти похожие маршруты (по адресу)
  Future<List<RouteHistoryItem>> findSimilarRoutes(String destination) async {
    final history = await getHistory();
    final lowerDestination = destination.toLowerCase();

    return history
        .where((item) =>
            item.destination.toLowerCase().contains(lowerDestination) ||
            item.destinationAddress.toLowerCase().contains(lowerDestination))
        .toList();
  }

  // Сохранить историю
  Future<void> _saveHistory(List<RouteHistoryItem> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = history.map((item) => item.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await prefs.setString(_keyRouteHistory, jsonString);
    } catch (e) {
      debugPrint('Error saving route history: $e');
    }
  }
}
