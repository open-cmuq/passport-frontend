import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class UserService {
  Future<User> getCurrentUser() async {
    try {
      // Get user ID from access token
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        throw Exception('Not authenticated');
      }

      // Parse JWT to get user ID
      final parts = accessToken.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid token');
      }

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      final userId = payload['user_id'];
      if (userId == null) {
        throw Exception('User ID not found in token');
      }

      // Fetch user data
      final response = await ApiService.get('/users/$userId');

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load user data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
      throw Exception('Failed to load user data: ${e.toString()}');
    }
  }

  Future<User> getUser(String userId) async {
    try {
      // Fetch user data
      final response = await ApiService.get('/users/$userId');

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else {
        throw Exception('Failed to load user data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
      throw Exception('Failed to load user data: ${e.toString()}');
    }
  }

  Future<User> updateUserProfile(User updatedUser) async {
    try {
      final response = await ApiService.patch('/users/${updatedUser.id}', {
        'name': updatedUser.name,
        'grad_year': updatedUser.gradYear,
        'title': updatedUser.title,
        'biography': updatedUser.biography,
        'department': updatedUser.department,
      });

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating user: $e');
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  Future<void> cacheCurrentUser() async {
    try {
      final user = await getCurrentUser();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint("Failed to cache user data: $e");
    }
  }

  // Admin-only methods
  Future<List<User>> getAllUsers() async {
    try {
      final response = await ApiService.get('/users/');
      if (response.statusCode == 200) {
        final List<dynamic> usersJson = json.decode(response.body);
        return usersJson.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
      throw Exception('Failed to load users: ${e.toString()}');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      final response = await ApiService.delete('/users/$userId');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting user: $e');
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }
}
