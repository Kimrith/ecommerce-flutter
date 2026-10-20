import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/BASE_API.dart';
import '../models/product.dart';
import '../models/categories.dart';
import 'auth_service.dart';

class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class ApiService {
  /// Server host from BaseApi configuration
  static String get serverHost => BaseApi.serverHost;

  /// Base API URL from BaseApi configuration
  static String get baseUrl => BaseApi.baseUrl;

  /// Uploads directory URL from BaseApi configuration
  static String get uploadsBaseUrl => BaseApi.uploadsBaseUrl;

  /// Endpoint for products
  static String get productEndpoint => BaseApi.productsEndpoint;

  /// Endpoint for categories
  static String get categoryEndpoint => BaseApi.categoriesEndpoint;

  /// Prepend base server host to relative image paths and format URLs safely
  static String buildFullImageUrl(String? path) => BaseApi.formatImageUrl(path);

  /// Fetch paginated list of products with optional categoryId and search filter
  static Future<ProductResponse> fetchProducts({
    int page = 1,
    int pageSize = 10,
    String? categoryId,
    String? search,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': pageSize.toString(),
    };
    if (categoryId != null && categoryId.trim().isNotEmpty) {
      queryParams['categoryId'] = categoryId.trim();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final uri = Uri.parse(productEndpoint).replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      return ProductResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load products: HTTP ${response.statusCode} - ${response.body}');
    }
  }

  /// Fetch single product details by ID
  static Future<Product> fetchProductById(String id) async {
    final uri = Uri.parse('$productEndpoint/$id');
    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final productData = decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>
          ? decoded['data']
          : decoded;
      return Product.fromJson(productData);
    } else {
      throw Exception('Failed to fetch product #$id: HTTP ${response.statusCode}');
    }
  }

  /// Fetch products by category ID
  static Future<ProductResponse> fetchProductsByCategory(
    String categoryId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    return fetchProducts(page: page, pageSize: pageSize, categoryId: categoryId);
  }

  /// Fetch list of categories with optional search filter
  static Future<CategoryResponse> fetchCategories({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final uri = queryParams.isEmpty
        ? Uri.parse(categoryEndpoint)
        : Uri.parse(categoryEndpoint).replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      return CategoryResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load categories: HTTP ${response.statusCode} - ${response.body}');
    }
  }

  /// Fetch single category by ID
  static Future<Category> fetchCategoryById(String id) async {
    final uri = Uri.parse('$categoryEndpoint/$id');
    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final catData = decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>
          ? decoded['data']
          : decoded;
      return Category.fromJson(catData);
    } else {
      throw Exception('Failed to fetch category #$id: HTTP ${response.statusCode}');
    }
  }

  /// Authenticate user (Login) using LoginDto
  static Future<AuthResponse> login(LoginDto dto) async {
    final uri = Uri.parse('${BaseApi.authEndpoint}/login');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(dto.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return AuthResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to login: HTTP ${response.statusCode}\n${response.body}');
    }
  }

  /// Register a new user using RegisterDto
  static Future<AuthResponse> register(RegisterDto dto) async {
    final uri = Uri.parse('${BaseApi.authEndpoint}/register');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(dto.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return AuthResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to register: HTTP ${response.statusCode}\n${response.body}');
    }
  }

  /// Refresh access token using RefreshTokenDto
  static Future<AuthResponse> refreshToken(RefreshTokenDto dto) async {
    final uri = Uri.parse('${BaseApi.authEndpoint}/refresh');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(dto.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return AuthResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to refresh token: HTTP ${response.statusCode}\n${response.body}');
    }
  }

  /// Create Order in backend database (POST /api/v1/orders)
  static Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required String shippingAddressString,
    String paymentMethod = 'BAKONG_KHQR',
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse(BaseApi.ordersEndpoint);
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'items': items,
        'shippingAddressString': shippingAddressString,
        'paymentMethod': paymentMethod,
      }),
    );

    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        return decoded['data'] as Map<String, dynamic>;
      }
      return decoded as Map<String, dynamic>;
    } else {
      final msg = decoded is Map && decoded['message'] != null ? decoded['message'] : 'HTTP ${response.statusCode}';
      throw Exception(msg is List ? msg.join(', ') : msg.toString());
    }
  }

  /// Generate Bakong KHQR for an order (POST /api/v1/payments/khqr/generate)
  static Future<Map<String, dynamic>> generateKhqr({
    required String orderId,
    String currency = 'USD',
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${BaseApi.paymentsEndpoint}/khqr/generate');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'orderId': orderId,
        'currency': currency,
      }),
    );

    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        return decoded['data'] as Map<String, dynamic>;
      }
      return decoded as Map<String, dynamic>;
    } else {
      final msg = decoded is Map && decoded['message'] != null ? decoded['message'] : 'HTTP ${response.statusCode}';
      throw Exception(msg is List ? msg.join(', ') : msg.toString());
    }
  }

  /// Verify Bakong KHQR payment transaction status (POST /api/v1/payments/khqr/verify)
  static Future<Map<String, dynamic>> verifyKhqr({
    required String orderId,
    required String md5,
  }) async {
    final uri = Uri.parse('${BaseApi.paymentsEndpoint}/khqr/verify');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'orderId': orderId,
        'md5': md5,
      }),
    );

    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        return decoded['data'] as Map<String, dynamic>;
      }
      return decoded as Map<String, dynamic>;
    } else {
      final msg = decoded is Map && decoded['message'] != null ? decoded['message'] : 'HTTP ${response.statusCode}';
      throw Exception(msg is List ? msg.join(', ') : msg.toString());
    }
  }
}