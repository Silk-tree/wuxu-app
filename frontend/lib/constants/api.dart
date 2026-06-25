class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const String apiV1 = '$baseUrl/api/v1';

  static const String items = '$apiV1/items';
  static String itemById(String id) => '$items/$id';

  static const String categories = '$apiV1/categories';

  static const String purchase = '$apiV1/purchase';

  static const String stats = '$apiV1/stats';

  static const int connectTimeout = 10000;
  static const int receiveTimeout = 15000;
}
