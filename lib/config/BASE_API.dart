// ignore_for_file: file_names

class BaseApi {
  // API server host URL
  static const String serverHost = "http://localhost:3300";

  /// REST API Base URL (e.g. http://localhost:3300/api/v1)
  static String get baseUrl => "$serverHost/api/v1";

  /// Static file uploads directory (e.g. http://localhost:3300/uploads)
  static String get uploadsBaseUrl => "$serverHost/uploads";

  // Core endpoints
  static String get productsEndpoint => "$baseUrl/products";
  static String get categoriesEndpoint => "$baseUrl/categories";
  static String get authEndpoint => "$baseUrl/auth";
  static String get ordersEndpoint => "$baseUrl/orders";
  static String get paymentsEndpoint => "$baseUrl/payments";
  static String get uploadEndpoint => "$baseUrl/upload";

  /// Prepend base server host to relative image paths (/uploads/...) and format URLs safely
  static String formatImageUrl(String? path) {
    if (path == null) return '';
    var trimmed = path.trim();
    if (trimmed.isEmpty) return '';

    // Ignore dummy placeholder values from OpenAPI/Swagger schemas
    final lower = trimmed.toLowerCase();
    if (lower == 'string' || lower == 'null' || lower == 'undefined' || lower == 'none') {
      return '';
    }

    // Replace Windows backslashes with Web slashes
    trimmed = trimmed.replaceAll('\\', '/');

    // Handle raw Base64 strings without data: header
    if (trimmed.startsWith('iVBORw0KGgo') ||
        trimmed.startsWith('/9j/') ||
        trimmed.startsWith('R0lGOD') ||
        trimmed.startsWith('Qk')) {
      return 'data:image/png;base64,$trimmed';
    }

    // If already absolute URL or Data URI, return directly
    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('data:image')) {
      return trimmed;
    }

    final cleanHost = serverHost.endsWith('/')
        ? serverHost.substring(0, serverHost.length - 1)
        : serverHost;
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';

    return '$cleanHost$cleanPath';
  }
}
