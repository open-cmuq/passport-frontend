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

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body, {String? token}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders(token);
    return await _makeRequest(() => http.post(url, headers: headers, body: jsonEncode(body)));
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
  //
  // static Future<http.Response> _makeRequest(Future<http.Response> Function() request) async {
  //   final accessToken = await AuthService.getAccessToken();
  //   final refreshToken = await AuthService.getRefreshToken();
  //
  //   // Check if both tokens are expired
  //   if (await AuthService.areTokensExpired()) {
  //     throw TokenExpiredException('Both tokens are expired. Please log in again.');
  //   }
  //
  //   // Check if the access token is expired and refresh it if necessary
  //   if (AuthService.isAccessTokenExpired(accessToken)) {
  //     final refreshed = await AuthService.refreshToken();
  //     if (!refreshed) {
  //       throw TokenExpiredException('Failed to refresh token. Please log in again.');
  //     }
  //   }
  //
  //   // Make the request
  //   final response = await request();
  //
  //   // If the request fails with a 401, try refreshing the token and retry
  //   if (response.statusCode == 401) {
  //     final refreshed = await AuthService.refreshToken();
  //     if (refreshed) {
  //       return await request();
  //     } else {
  //       throw TokenExpiredException('Failed to refresh token. Please log in again.');
  //     }
  //   }
  //
  //   return response;
  // }
  
  static Future<http.Response> _makeRequest(Future<http.Response> Function() request) async {
    // First attempt the request
    var response = await request();

    if (response.statusCode == 401) {
      debugPrint("Unauthorized request detected, trying to refresh token");
      final refreshed = await AuthService.refreshToken();
      
      if (refreshed) {
        debugPrint("Token refreshed successfully, retrying request");
        // Get the new access token
        final newAccessToken = await AuthService.getAccessToken();
        
        if (newAccessToken != null) {
          // Create a new request function with updated headers
          final newRequest = () async {
            final headers = await _getHeaders(newAccessToken);
            // Recreate the original request with new headers
            if (request is Future<http.Response> Function()) {
              // For GET requests
              final originalRequest = request as Future<http.Response> Function();
              final originalResponse = await originalRequest();
              final newUrl = originalResponse.request?.url;
              if (newUrl != null) {
                return http.get(newUrl, headers: headers);
              }
            }
            // For other methods, you'd need to handle them similarly
            return request();
          };
          
          // Execute the new request with updated token
          return await newRequest();
        }
      }
      
      throw TokenExpiredException('Failed to refresh token. Please log in again.');
    }
    return response;
  }
}
