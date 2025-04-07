// lib/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_service.dart';
import 'dart:convert';
import 'user_service.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static bool _isRefreshing = false;
  static bool _refreshFailed = false;

  static Future<String?> login(String email, String password) async {
    try {
      final response = await ApiService.post('/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final tokens = jsonDecode(response.body);
        await _saveTokens(tokens['access_token'], tokens['refresh_token']);
        await UserService().cacheCurrentUser();
        return null; // No error means success
      } else if (response.statusCode == 401) {
        // Parse the error message from backend
        final errorResponse = jsonDecode(response.body);
        return errorResponse['error'] ?? 'Invalid email or password';
      } else {
        return 'An unexpected error occurred (${response.statusCode})';
      }
    } catch (e) {
      return 'Network error: ${e.toString()}';
    }
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final validEmail = RegExp(
        r'^[a-zA-Z0-9._%+-]+@(andrew\.cmu\.edu|qatar\.cmu\.edu|cmu\.edu)$',
      );
      if (!validEmail.hasMatch(email)) {
        return {'success': false, 'message': 'Invalid email domain'};
      }

      final response = await ApiService.post('/register', {
        'name': name,
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (dotenv.get('ENV') == 'development') {
          await _saveTokens(
            responseData['access_token'],
            responseData['refresh_token'],
          );
          await UserService().cacheCurrentUser();
          return {'success': true, 'requiresOTP': false};
        } else {
          return {'success': true, 'requiresOTP': true};
        }
      } else {
        final errorResponse = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorResponse['error'] ?? 'Registration failed'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration failed: ${e.toString()}'
      };
    }
  }

  static Future<bool> verifyOTP(String email, String otp) async {
    final response = await ApiService.post('/verify-otp', {
      'email': email,
      'otp': otp,
    });
    if (response.statusCode == 200) {
      final tokens = jsonDecode(response.body);
      await _saveTokens(tokens['access_token'], tokens['refresh_token']);
      await UserService().cacheCurrentUser();
      return true;
    }
    return false;
  }

  static Future<String?> resendOTP(String email) async {
    try {
      final response = await ApiService.post('/resend-otp', {
        'email': email,
      });

      if (response.statusCode == 200) {
        return null; // Success
      } else if (response.statusCode == 429) {
        final errorResponse = jsonDecode(response.body);
        final retryAfter = errorResponse['retry_after']?.toDouble() ?? 30.0;
        return 'Please wait ${retryAfter.toStringAsFixed(0)} seconds before resending';
      } else {
        final errorResponse = jsonDecode(response.body);
        return errorResponse['error'] ?? 'Failed to resend OTP';
      }
    } catch (e) {
      return 'Failed to resend OTP: ${e.toString()}';
    }
  }

  static Future<String?> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final response = await ApiService.post('/change-password', {
        'old_password': oldPassword,
        'new_password': newPassword,
      });

      if (response.statusCode == 200) {
        // Password changed successfully - update tokens
        final tokens = jsonDecode(response.body);
        await _saveTokens(tokens['access_token'], tokens['refresh_token']);
        return null;
      } else if (response.statusCode == 401) {
        return 'Invalid old password';
      } else {
        final errorResponse = jsonDecode(response.body);
        return errorResponse['error'] ?? 'Password change failed';
      }
    } catch (e) {
      return 'Password change failed: ${e.toString()}';
    }
  }

  static Future<String?> forgotPassword(String email) async {
    try {
      final response = await ApiService.post('/forgot-password', {
        'email': email,
      });

      if (response.statusCode == 200) {
        return null; // Success - always return success regardless of email existence
      } else if (response.statusCode == 429) {
        final errorResponse = jsonDecode(response.body);
        final retryAfter = errorResponse['retry_after']?.toDouble() ?? 30.0;
        return 'Please wait ${retryAfter.toStringAsFixed(0)} seconds before requesting new OTP';
      } else {
        return 'Failed to initiate password reset';
      }
    } catch (e) {
      return 'Failed to initiate password reset: ${e.toString()}';
    }
  }

  static Future<String?> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      final response = await ApiService.post('/reset-password', {
        'email': email,
        'otp': otp,
        'password': newPassword,
      });

      if (response.statusCode == 200) {
        // Password reset successful - clear existing tokens
        await logout();
        return null;
      } else if (response.statusCode == 400) {
        final errorResponse = jsonDecode(response.body);
        return errorResponse['error'] ?? 'Invalid OTP or expired';
      } else {
        return 'Password reset failed';
      }
    } catch (e) {
      return 'Password reset failed: ${e.toString()}';
    }
  }

  static Future<void> _saveTokens(
    String accessToken,
    String refreshToken,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  static Future<bool> refreshToken() async {
    // Prevent multiple concurrent refresh attempts
    if (_isRefreshing) return false;
    if (_refreshFailed) return false;

    _isRefreshing = true;
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || isAccessTokenExpired(refreshToken)) {
      debugPrint("We have no refresh token or our refreshToken is expired");
      return false;
    }

    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || isAccessTokenExpired(refreshToken)) {
        debugPrint("Refresh token invalid or expired");
        _refreshFailed = true;
        return false;
      }

      final response = await ApiService.post(
        '/refresh-token',
        {'refresh_token': refreshToken},
        skipAuthRetry: true, // Important! Don't retry refresh token calls
      );

      if (response.statusCode == 200) {
        final tokens = jsonDecode(response.body);
        await _saveTokens(tokens['access_token'], refreshToken);
        await UserService().cacheCurrentUser();
        _refreshFailed = false;
        return true;
      } else {
        _refreshFailed = true;
        return false;
      }
    } catch (e) {
      _refreshFailed = true;
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  static bool isAccessTokenExpired(String? token) {
    if (token == null) return false;
    final payload = decodeToken(token);
    if (payload == null || !payload.containsKey('exp')) {
      return true;
    }
    final expiryDate = DateTime.fromMillisecondsSinceEpoch(
      payload['exp'] * 1000,
    );
    return expiryDate.isBefore(DateTime.now());
  }

  static Map<String, dynamic>? decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }
      final payload = _decodeBase64(parts[1]);
      final payloadMap = jsonDecode(payload);
      if (payloadMap is Map<String, dynamic>) {
        return payloadMap;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');

    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Illegal base64url string!');
    }

    return utf8.decode(base64Url.decode(output));
  }

  static Future<bool> areTokensExpired() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();

    if (accessToken == null && refreshToken == null) {
      return false;
    }

    return isAccessTokenExpired(accessToken) &&
        isAccessTokenExpired(refreshToken);
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');

    if (userData == null) return null;

    final user = User.fromJson(jsonDecode(userData));
    return user.role;
  }
}
