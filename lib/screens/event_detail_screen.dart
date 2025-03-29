// lib/screens/event_detail_screen.dart
import 'package:flutter/material.dart';
import '../../models/event_model.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;

  const EventDetailScreen({required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event.name),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.iconUrl.isNotEmpty)
              Center(
                child: Image.network(
                  event.iconUrl,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              ),
            if (event.iconUrl.isEmpty) 
              Container(
                height: 200,
                color: Colors.grey[200],
                child: Icon(Icons.event, size: 50, color: Colors.grey),
              ),
            SizedBox(height: 20),
            Text(
              event.description,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            _buildDetailRow(Icons.location_on, event.location),
            _buildDetailRow(Icons.calendar_today, 
              '${_formatDate(event.startTime)} - ${_formatDate(event.endTime)}'),
            _buildDetailRow(Icons.person, 
              'Organizer: ${event.organizer?['name'] ?? 'Unknown'}'),
            _buildDetailRow(Icons.people, 
              'Attendees: ${event.attendees?.length ?? 0}'),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: () {
                  // Handle attend action
                },
                child: Text('Attend Event', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green[700]),
          SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
