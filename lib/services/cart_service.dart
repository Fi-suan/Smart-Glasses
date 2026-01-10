import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import 'auth_service.dart';

class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();

  static const String _keyCart = 'cart_items';
  bool _isInitialized = false;

  List<CartItem> get items => _items;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  // Инициализация - загрузка корзины
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadCart();
      _isInitialized = true;

      // Слушаем изменения авторизации
      _auth.addListener(_onAuthChanged);
    } catch (e) {
      debugPrint('Error initializing cart: $e');
    }
  }

  void _onAuthChanged() async {
    // При смене пользователя - перезагружаем корзину
    await _loadCart();
  }

  // Загрузить корзину
  Future<void> _loadCart() async {
    try {
      _items.clear();

      // Если пользователь авторизован - загружаем из Firebase
      if (_auth.isLoggedIn && _auth.currentUser != null) {
        final doc = await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('cart')
            .doc('current')
            .get();

        if (doc.exists && doc.data() != null) {
          final List<dynamic> itemsJson = doc.data()!['items'] ?? [];
          _items.addAll(
            itemsJson.map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          );
          debugPrint('✅ Cart loaded from Firebase: ${_items.length} items');
        }
      } else {
        // Иначе из SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final jsonString = prefs.getString(_keyCart);

        if (jsonString != null && jsonString.isNotEmpty) {
          final List<dynamic> itemsJson = json.decode(jsonString);
          _items.addAll(
            itemsJson.map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          );
          debugPrint('Cart loaded from SharedPreferences: ${_items.length} items');
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cart: $e');
    }
  }

  // Сохранить корзину
  Future<void> _saveCart() async {
    try {
      final itemsJson = _items.map((item) => item.toJson()).toList();

      // Если пользователь авторизован - сохраняем в Firebase
      if (_auth.isLoggedIn && _auth.currentUser != null) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('cart')
            .doc('current')
            .set({
          'items': itemsJson,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Cart saved to Firebase: ${_items.length} items');
      } else {
        // Иначе в SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final jsonString = json.encode(itemsJson);
        await prefs.setString(_keyCart, jsonString);
        debugPrint('Cart saved to SharedPreferences: ${_items.length} items');
      }
    } catch (e) {
      debugPrint('Error saving cart: $e');
    }
  }

  void addToCart(Product product) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }

    _saveCart();
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      _saveCart();
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    _saveCart();
    notifyListeners();
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  bool isInCart(String productId) {
    return _items.any((item) => item.product.id == productId);
  }
}
