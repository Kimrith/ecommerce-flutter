import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/BASE_API.dart';
import '../models/auth.dart';

export '../models/auth.dart';

/// Backwards compatibility alias for UserPayload
typedef UserModel = UserPayload;

class AuthService {
  static const String _tokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _userKey = 'auth_user_data';

  /// Check if user is currently authenticated with a token
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.trim().isNotEmpty;
  }

  /// Get stored JWT access token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Get stored JWT refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// Get currently stored user profile from SharedPreferences
  static Future<UserPayload?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null || userJson.isEmpty) return null;
    try {
      return UserPayload.fromJson(jsonDecode(userJson));
    } catch (_) {
      return null;
    }
  }

  /// Save authentication session into SharedPreferences
  static Future<void> saveSession(AuthResponse authResponse) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, authResponse.accessToken);
    await prefs.setString(_refreshTokenKey, authResponse.refreshToken);
    await prefs.setString(_userKey, jsonEncode(authResponse.user.toJson()));
  }

  static Future<void> _saveSession(AuthResponse authResponse) async => saveSession(authResponse);

  /// Log in with email and password (POST /api/v1/auth/login)
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final loginDto = LoginDto(email: email, password: password);
      final uri = Uri.parse('${BaseApi.authEndpoint}/login');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(loginDto.toJson()),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300 && data['success'] == true) {
        final authResponse = AuthResponse.fromJson(data);
        await _saveSession(authResponse);

        return {
          'success': true,
          'message': data['message'] ?? 'Login successful',
          'auth': authResponse,
          'user': authResponse.user,
        };
      } else {
        final message = data['message'] ?? 'Login failed. Please check your credentials.';
        return {
          'success': false,
          'message': message is List ? message.join(', ') : message.toString(),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to server: ${e.toString()}',
      };
    }
  }

  /// Register a new user account (POST /api/v1/auth/register)
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String role = 'USER',
  }) async {
    try {
      final registerDto = RegisterDto(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );
      final uri = Uri.parse('${BaseApi.authEndpoint}/register');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(registerDto.toJson()),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300 && data['success'] == true) {
        final authResponse = AuthResponse.fromJson(data);
        await _saveSession(authResponse);

        return {
          'success': true,
          'message': data['message'] ?? 'Registration successful',
          'auth': authResponse,
          'user': authResponse.user,
        };
      } else {
        final message = data['message'] ?? 'Registration failed.';
        return {
          'success': false,
          'message': message is List ? message.join(', ') : message.toString(),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to server: ${e.toString()}',
      };
    }
  }

  /// Refresh token pair (POST /api/v1/auth/refresh)
  static Future<bool> refreshToken() async {
    final currentRefreshToken = await getRefreshToken();
    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      return false;
    }

    try {
      final uri = Uri.parse('${BaseApi.authEndpoint}/refresh');
      final dto = RefreshTokenDto(refreshToken: currentRefreshToken);

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(dto.toJson()),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300 && data['success'] == true) {
        final payload = data['data'];
        final newAccess = payload['accessToken'] as String?;
        final newRefresh = payload['refreshToken'] as String?;

        final prefs = await SharedPreferences.getInstance();
        if (newAccess != null) await prefs.setString(_tokenKey, newAccess);
        if (newRefresh != null) await prefs.setString(_refreshTokenKey, newRefresh);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Fetch authenticated user profile from remote backend (GET /api/v1/auth/me)
  static Future<UserPayload?> getProfile() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return null;

    try {
      final uri = Uri.parse('${BaseApi.authEndpoint}/me');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userData = (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>)
            ? data['data'] as Map<String, dynamic>
            : (data is Map<String, dynamic> ? data : null);

        if (userData != null) {
          final profile = UserPayload.fromJson(userData);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userKey, jsonEncode(profile.toJson()));
          return profile;
        }
      } else if (response.statusCode == 401) {
        // Attempt to refresh token once if unauthorized
        final refreshed = await refreshToken();
        if (refreshed) {
          return getProfile();
        }
      }
    } catch (_) {}

    // Fall back to locally cached profile if offline
    return getCurrentUser();
  }

  /// Log out and clear all saved auth credentials
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
  }
}
