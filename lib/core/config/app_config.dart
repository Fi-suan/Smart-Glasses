class AppConfig {
  // Feature flags
  static const bool useApiForProducts = true; // Switch to API for products
  static const bool useApiForCart = true; // Switch to API for cart

  // Set to false to use mock data (for testing without server)
  static const bool enableApi = true;

  static bool get useMockData => !enableApi;
}
