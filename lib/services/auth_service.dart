// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_service.dart';
import 'dart:convert'; // Add this import

class AuthService {
  static const String _tokenKey = 'auth_token';

  static Future<bool> login(String email, String password) async {
    final response = await ApiService.post('/login', {'email': email, 'password': password});
    if (response.statusCode == 200) {
      final token = jsonDecode(response.body)['token'];
      await _saveToken(token);
      return true;
    }
    return false;
  }

  static Future<bool> register(String name, String email, String password) async {
    // Validate email domain in Flutter (optional, but recommended for immediate feedback)
    final validEmail = RegExp(r'^[a-zA-Z0-9._%+-]+@(andrew\.cmu\.edu|qatar\.cmu\.edu|cmu\.edu)$');
    if (!validEmail.hasMatch(email)) {
      throw Exception("Email must be from @andrew.cmu.edu, @qatar.cmu.edu, or @cmu.edu");
    }

    final response = await ApiService.post('/register', {
      'name': name,
      'email': email,
      'password': password,
    });

    if (response.statusCode == 200) {
      if (dotenv.get('ENV') == 'development') {
        // In development, directly save the token
        final token = jsonDecode(response.body)['token'];
        await _saveToken(token);
      } else {
        // In production, expect an OTP to be sent
        print("OTP sent for verification");
      }
      return true;
    }
    return false;
  }

  static Future<bool> verifyOTP(String email, String otp) async {
    final response = await ApiService.post('/verify-OTP', {'email': email, 'otp': otp});
    if (response.statusCode == 200) {
      final token = jsonDecode(response.body)['token'];
      await _saveToken(token);
      return true;
    }
    return false;
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
