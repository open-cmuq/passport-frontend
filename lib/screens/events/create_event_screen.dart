import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/event_service.dart';
import '../../models/event_model.dart';

class CreateEventScreen extends StatefulWidget {
  @override
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _pointsController = TextEditingController();
  final _awardsController = TextEditingController();
  final _imageUrlController = TextEditingController();
  DateTime? _startTime;
  DateTime? _endTime;

  Future<void> _selectDate(BuildContext context, bool isStartTime) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        final dateTime =
            picked.add(Duration(hours: time.hour, minutes: time.minute));
        setState(() {
          if (isStartTime) {
            _startTime = dateTime;
          } else {
            _endTime = dateTime;
          }
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final newEvent = await EventService.createEvent(
          name: _nameController.text,
          description: _descriptionController.text,
          location: _locationController.text,
          startTime: _startTime,
          endTime: _endTime,
          pointsAllocation: int.parse(_pointsController.text),
          awardIDs: _awardsController.text.split(',').map(int.parse).toList(),
          imageURL: _imageUrlController.text,
        );

        Navigator.pop(context, true); // Return success
        Fluttertoast.showToast(msg: 'Event created successfully!');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Error creating event: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Event'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Event Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: 'Location'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              ListTile(
                title: Text(_startTime != null
                    ? 'Start: ${_startTime!.toLocal()}'
                    : 'Select Start Time'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, true),
              ),
              ListTile(
                title: Text(_endTime != null
                    ? 'End: ${_endTime!.toLocal()}'
                    : 'Select End Time'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, false),
              ),
              TextFormField(
                controller: _pointsController,
                decoration: InputDecoration(labelText: 'Points Allocation'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _awardsController,
                decoration: InputDecoration(
                    labelText: 'Award IDs (comma separated)',
                    hintText: 'e.g., 1,2,3'),
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(labelText: 'Image URL'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Create Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
