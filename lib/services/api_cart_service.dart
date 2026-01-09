import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/config/api_config.dart';
import '../models/product.dart';
import '../models/cart_item.dart';

class ApiCartService {
  final Dio _dio = ApiClient.dio;

  Future<CartData> getCart() async {
    try {
      final response = await _dio.get(ApiConfig.cartEndpoint);

      if (response.data['success'] == true) {
        return CartData.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to load cart');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to server');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  Future<void> addToCart(String productId, int quantity) async {
    try {
      await _dio.post(
        '${ApiConfig.cartEndpoint}/items',
        data: {
          'product_id': productId,
          'quantity': quantity,
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Product not found');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Product is out of stock');
      } else {
        throw Exception('Failed to add to cart: ${e.message}');
      }
    }
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    try {
      await _dio.put(
        '${ApiConfig.cartEndpoint}/items/$cartItemId',
        data: {'quantity': quantity},
      );
    } on DioException catch (e) {
      throw Exception('Failed to update quantity: ${e.message}');
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    try {
      await _dio.delete('${ApiConfig.cartEndpoint}/items/$cartItemId');
    } on DioException catch (e) {
      throw Exception('Failed to remove item: ${e.message}');
    }
  }

  Future<void> clearCart() async {
    try {
      await _dio.delete(ApiConfig.cartEndpoint);
    } on DioException catch (e) {
      throw Exception('Failed to clear cart: ${e.message}');
    }
  }
}

// Cart data model from API
class CartData {
  final String cartId;
  final List<ApiCartItem> items;
  final CartSummary summary;

  CartData({
    required this.cartId,
    required this.items,
    required this.summary,
  });

  factory CartData.fromJson(Map<String, dynamic> json) {
    return CartData(
      cartId: json['cart_id'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => ApiCartItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      summary: CartSummary.fromJson(json['summary'] as Map<String, dynamic>),
    );
  }
}

class ApiCartItem {
  final String cartItemId;
  final ProductInCart product;
  final int quantity;
  final int subtotal;

  ApiCartItem({
    required this.cartItemId,
    required this.product,
    required this.quantity,
    required this.subtotal,
  });

  factory ApiCartItem.fromJson(Map<String, dynamic> json) {
    return ApiCartItem(
      cartItemId: json['cart_item_id'] as String,
      product: ProductInCart.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      subtotal: json['subtotal'] as int,
    );
  }

  // Convert to local CartItem model
  CartItem toCartItem() {
    return CartItem(
      product: Product(
        id: product.id,
        name: product.name,
        category: '', // Not provided by API cart item
        price: product.price,
        description: '',
        imageUrl: product.imageUrl,
      ),
      quantity: quantity,
    );
  }
}

class ProductInCart {
  final String id;
  final String name;
  final int price;
  final String? imageUrl;
  final bool isAvailable;

  ProductInCart({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    required this.isAvailable,
  });

  factory ProductInCart.fromJson(Map<String, dynamic> json) {
    return ProductInCart(
      id: json['id'] as String,
      name: json['name'] as String,
      price: json['price'] as int,
      imageUrl: json['image_url'] as String?,
      isAvailable: json['is_available'] as bool,
    );
  }
}

class CartSummary {
  final int itemsCount;
  final int subtotal;
  final int discount;
  final int shipping;
  final int total;

  CartSummary({
    required this.itemsCount,
    required this.subtotal,
    required this.discount,
    required this.shipping,
    required this.total,
  });

  factory CartSummary.fromJson(Map<String, dynamic> json) {
    return CartSummary(
      itemsCount: json['items_count'] as int,
      subtotal: json['subtotal'] as int,
      discount: json['discount'] as int,
      shipping: json['shipping'] as int,
      total: json['total'] as int,
    );
  }
}
