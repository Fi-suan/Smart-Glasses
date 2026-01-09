import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/config/api_config.dart';
import '../models/product.dart';

class ProductService {
  final Dio _dio = ApiClient.dio;

  Future<List<Product>> getProducts({
    String? category,
    int? minPrice,
    int? maxPrice,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (minPrice != null) queryParams['min_price'] = minPrice;
      if (maxPrice != null) queryParams['max_price'] = maxPrice;
      if (search != null) queryParams['search'] = search;

      final response = await _dio.get(
        ApiConfig.productsEndpoint,
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final List<dynamic> productsData = response.data['data']['products'];
        return productsData.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Cannot connect to server. Make sure:\n'
          '1. Mock server is running on your computer\n'
          '2. Phone and computer are on the same WiFi\n'
          '3. Server address is correct: ${ApiConfig.baseUrl}',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<Product> getProductById(String id) async {
    try {
      final response = await _dio.get('${ApiConfig.productsEndpoint}/$id');

      if (response.data['success'] == true) {
        return Product.fromJson(response.data['data']);
      } else {
        throw Exception('Product not found');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Product not found');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
