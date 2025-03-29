// lib/services/event_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/event_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class EventService {
  static Future<List<Event>> getEvents({int limit = 50}) async {
    final token = await AuthService.getAccessToken(); // Retrieve the token
    if (token == null) {
      throw Exception('User is not authenticated');
    }

    try {
      final response = await ApiService.get('/events?limit=$limit', token: token); // Pass the token
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Event.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch events: $e');
    }
  }
}
