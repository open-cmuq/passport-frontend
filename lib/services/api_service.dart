// lib/services/api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException(this.message);
}

class ApiService {
  static final String _baseUrl = dotenv.get('API_BASE_URL');

  static Future<http.Response> get(String endpoint, {String? token}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders(token);
    return await _makeRequest(() => http.get(url, headers: headers));
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body, {String? token, bool skipAuthRetry = false}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders(token);
    final bodyJson = jsonEncode(body);
    return await _makeRequest(
      () => http.post(url, headers: headers, body: bodyJson),
      requestBody: bodyJson,
      skipAuthRetry: skipAuthRetry,
    );
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body, {String? token}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders(token);
    final bodyJson = jsonEncode(body);
    return await _makeRequest(
      () => http.put(url, headers: headers, body: bodyJson),
      requestBody: bodyJson,
    );
  }

  static Future<http.Response> delete(String endpoint, {String? token}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders(token);
    return await _makeRequest(() => http.delete(url, headers: headers));
  }

  static Future<Map<String, String>> _getHeaders(String? token) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    } else {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken != null) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    return headers;
  }
  
  static Future<http.Response> _makeRequest(
    Future<http.Response> Function() request, {
    String? requestBody,
    bool skipAuthRetry = false
  }) async {
    // First attempt the request
    var response = await request();

    if (response.statusCode == 401 && !skipAuthRetry) {
      debugPrint("Unauthorized request detected, trying to refresh token");
      final refreshed = await AuthService.refreshToken();
      
      if (refreshed) {
        debugPrint("Token refreshed successfully, retrying request");
        final newAccessToken = await AuthService.getAccessToken();
        
        if (newAccessToken != null) {
          // Create new headers with refreshed token
          final headers = await _getHeaders(newAccessToken);
          
          // Recreate the original request
          final originalRequest = response.request;
          if (originalRequest == null) {
            throw TokenExpiredException('Failed to recreate request');
          }
          
          // Create a new request based on the original method
          switch (originalRequest.method) {
            case 'GET':
              return await http.get(originalRequest.url, headers: headers);
            case 'POST':
              return await http.post(
                originalRequest.url,
                headers: headers,
                body: requestBody, // Use the stored request body
              );
            case 'PUT':
              return await http.put(
                originalRequest.url,
                headers: headers,
                body: requestBody, // Use the stored request body
              );
            case 'DELETE':
              return await http.delete(originalRequest.url, headers: headers);
            default:
              throw TokenExpiredException('Unsupported HTTP method');
          }
        }
      }
      
      throw TokenExpiredException('Failed to refresh token. Please log in again.');
    }
    return response;
  }
}
