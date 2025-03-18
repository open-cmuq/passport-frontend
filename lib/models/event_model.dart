// lib/models/event_model.dart
class Event {
  final int id;
  final String name;
  final String description;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final int organizerId;
  final int pointsAllocation;
  final String iconUrl;
  final Map<String, dynamic>? organizer;
  final List<dynamic>? attendees;
  final List<dynamic>? awards;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.organizerId,
    required this.pointsAllocation,
    required this.iconUrl,
    this.organizer,
    this.attendees,
    this.awards,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as int? ?? 0, // Handle null or invalid type
      name: json['name'] as String? ?? 'Unnamed Event', // Handle null or invalid type
      description: json['description'] as String? ?? 'No description', // Handle null or invalid type
      location: json['location'] as String? ?? 'Unknown location', // Handle null or invalid type
      startTime: DateTime.parse(json['start_time'] as String? ?? '1970-01-01T00:00:00Z'), // Handle null or invalid type
      endTime: DateTime.parse(json['end_time'] as String? ?? '1970-01-01T00:00:00Z'), // Handle null or invalid type
      organizerId: json['organizer_id'] as int? ?? 0, // Handle null or invalid type
      pointsAllocation: json['points_allocation'] as int? ?? 0, // Handle null or invalid type
      iconUrl: json['icon_url'] as String? ?? '', // Handle null or invalid type
      organizer: json['organizer'] as Map<String, dynamic>?, // Handle null
      attendees: json['attendees'] as List<dynamic>?, // Handle null
      awards: json['awards'] as List<dynamic>?, // Handle null
    );
  }
}
