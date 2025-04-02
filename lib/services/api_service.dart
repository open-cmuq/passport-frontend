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

  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
    bool skipAuthRetry = false,
  }) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders(token);
    final bodyJson = jsonEncode(body);
    return await _makeRequest(
      () => http.post(url, headers: headers, body: bodyJson),
      requestBody: bodyJson,
      skipAuthRetry: skipAuthRetry,
    );
  }

  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
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

  static Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
    bool skipAuthRetry = false,
  }) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders(token);
    final bodyJson = jsonEncode(body);
    return await _makeRequest(
      () => http.patch(url, headers: headers, body: bodyJson),
      requestBody: bodyJson,
      skipAuthRetry: skipAuthRetry,
    );
  }

  static Future<Map<String, String>> _getHeaders(String? token) async {
    final headers = {'Content-Type': 'application/json'};

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
    bool skipAuthRetry = false,
    int redirectCount = 0,
  }) async {
    const maxRedirects = 5;
    if (redirectCount >= maxRedirects) {
      throw Exception('Too many redirects (max $maxRedirects)');
    }

    // First attempt the request
    var response = await request();

    // Handle 401 Unauthorized
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

          // Create a new request with refreshed token
          Future<http.Response> newRequest() {
            switch (originalRequest.method) {
              case 'GET':
                return http.get(originalRequest.url, headers: headers);
              case 'POST':
                return http.post(
                  originalRequest.url,
                  headers: headers,
                  body: requestBody,
                );
              case 'PUT':
                return http.put(
                  originalRequest.url,
                  headers: headers,
                  body: requestBody,
                );
              case 'PATCH':
                return http.patch(
                  originalRequest.url,
                  headers: headers,
                  body: requestBody,
                );
              case 'DELETE':
                return http.delete(originalRequest.url, headers: headers);
              default:
                throw TokenExpiredException('Unsupported HTTP method');
            }
          }

          // Retry with new token and return through redirect handler
          return await _makeRequest(
            newRequest,
            requestBody: requestBody,
            skipAuthRetry: true,
            redirectCount: redirectCount,
          );
        }
      }
      throw TokenExpiredException(
        'Failed to refresh token. Please log in again.',
      );
    }

    // Handle redirects (3xx status codes)
    if (response.statusCode >= 300 && response.statusCode < 400) {
      final location = response.headers['location'];
      if (location == null) {
        throw Exception('Redirect location missing in response');
      }

      final originalRequest = response.request;
      if (originalRequest == null) {
        throw Exception('Original request information missing');
      }

      final newUrl = Uri.parse(location);
      debugPrint("Redirecting to $newUrl");

      // Create new request for redirect location
      Future<http.Response> redirectRequest() {
        switch (originalRequest.method) {
          case 'GET':
            return http.get(newUrl, headers: originalRequest.headers);
          case 'POST':
            return http.post(
              newUrl,
              headers: originalRequest.headers,
              body: requestBody,
            );
          case 'PUT':
            return http.put(
              newUrl,
              headers: originalRequest.headers,
              body: requestBody,
            );
          case 'PATCH':
            return http.patch(
              newUrl,
              headers: originalRequest.headers,
              body: requestBody,
            );
          case 'DELETE':
            return http.delete(newUrl, headers: originalRequest.headers);
          default:
            throw Exception('Unsupported HTTP method for redirect');
        }
      }

      return await _makeRequest(
        redirectRequest,
        requestBody: requestBody,
        skipAuthRetry: skipAuthRetry,
        redirectCount: redirectCount + 1,
      );
    }

    return response;
  }
}
