class ApiConfig {
  // Base URL for real device on same WiFi network
  static const String baseUrl = 'http://192.168.0.101:3000/v1';

  // For Android emulator use: 'http://10.0.2.2:3000/v1'
  // For iOS simulator use: 'http://localhost:3000/v1'

  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000;

  // API endpoints
  static const String productsEndpoint = '/products';
  static const String cartEndpoint = '/cart';
  static const String ordersEndpoint = '/orders';
}
