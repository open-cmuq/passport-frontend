// lib/services/event_service.dart
import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/event_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class EventService {
  static Future<List<Event>> getEvents({
    int limit = 10,
    DateTime? beforeTime,
  }) async {
    final token = await AuthService.getAccessToken();
    if (token == null) throw Exception('User is not authenticated');

    String url = '/events/?limit=$limit';
    if (beforeTime != null) {
      url += '&before_time=${beforeTime.toIso8601String()}';
    }

    try {
      final response = await ApiService.get(url, token: token);
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

  static Future<Event> updateEvent(
    String eventId,
    Map<String, dynamic> updateData,
  ) async {
    final token = await AuthService.getAccessToken();
    if (token == null) throw Exception('User is not authenticated');

    final url = '/events/$eventId';

    try {
      final response = await ApiService.patch(url, updateData, token: token);

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        return Event.fromJson(data);
      } else {
        throw Exception('Failed to update event: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  static Future<Event> createEvent({
    required String name,
    required String description,
    required String location,
    DateTime? startTime,
    DateTime? endTime,
    required int pointsAllocation,
    List<int> awardIDs = const [],
    String imageURL = '',
  }) async {
    final token = await AuthService.getAccessToken();
    if (token == null) throw Exception('User is not authenticated');

    final body = {
      'name': name,
      'description': description,
      'location': location,
      'start_time': startTime?.toUtc().toIso8601String(),
      'end_time': endTime?.toUtc().toIso8601String(),
      'points_allocation': pointsAllocation,
      'award_ids': awardIDs,
      'image_url': imageURL,
    };

    try {
      final response = await ApiService.post('/events/', body, token: token);
      if (response.statusCode == 201) {
        final dynamic data = jsonDecode(response.body);
        return Event.fromJson(data);
      } else {
        throw Exception('Failed to create event: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  static Future<void> deleteEvent(int eventId) async {
    final token = await AuthService.getAccessToken();
    if (token == null) throw Exception('User is not authenticated');

    final url = '/events/$eventId';

    try {
      final response = await ApiService.delete(url, token: token);
      if (response.statusCode != 200) {
        throw Exception('Failed to delete event: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  static Future<Map<String, dynamic>> addAttendance({
    required String eventId,
    required List<String> identifiers,
  }) async {
    final token = await AuthService.getAccessToken();
    if (token == null) throw Exception('User is not authenticated');

    // Validate identifiers (either emails or numeric user IDs)
    final validIdentifiers = identifiers.where((identifier) {
      return identifier.contains('@') || // Simple email check
          RegExp(r'^\d+$').hasMatch(identifier); // Numeric ID check
    }).toList();

    if (validIdentifiers.isEmpty) {
      throw Exception('No valid identifiers provided');
    }

    final body = {
      'identifiers': validIdentifiers,
    };

    try {
      final response = await ApiService.post(
        '/events/$eventId/attendances',
        body,
        token: token,
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Attendance processed',
          'newAttendees': data['new_attendees'] ?? 0,
          'duplicates': data['duplicates'] ?? 0,
          'pointsAdded': data['points_added'] ?? 0,
          'newAwardsGranted': data['new_awards_granted'] ?? 0,
          'processedUsers': List<String>.from(data['processed_users'] ?? []),
          'invalidIdentifiers':
              List<String>.from(data['invalid_identifiers'] ?? []),
        };
      } else {
        throw Exception('Failed to add attendance: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to add attendance: $e');
    }
  }
}
