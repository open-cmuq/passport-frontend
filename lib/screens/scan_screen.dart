// lib/screens/scan_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/event_service.dart';
import '../models/event_model.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanScreen extends StatefulWidget {
  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<Event> _events = [];
  Event? _selectedEvent;
  bool _isLoadingEvents = true;
  bool _isScanning = false;
  bool _showCamera = false;
  final List<String> _scannedIds = [];
  final List<String> _processedIds = [];
  final MobileScannerController _cameraController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    try {
      final events = await EventService.getEvents(limit: 10);
      setState(() {
        _events = events;
        _isLoadingEvents = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingEvents = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load events: $e')),
      );
    }
  }

  void _handleScan(Barcode barcode) {
    if (barcode.rawValue == null || _selectedEvent == null) return;

    // Check if we've already scanned this ID
    if (_scannedIds.contains(barcode.rawValue)) return;

    setState(() {
      _scannedIds.add(barcode.rawValue!);
    });

    // Process the attendance
    _processAttendance(barcode.rawValue!);
  }

  Future<void> _processAttendance(String userId) async {
    try {
      final result = await EventService.addAttendance(
        eventId: _selectedEvent!.id.toString(),
        identifiers: [userId],
      );

      setState(() {
        if (result['success'] == true) {
          _processedIds.add(userId);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully processed user $userId')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process user $userId: $e')),
      );
    }
  }

  Future<bool> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      return true;
    } else {
      final result = await Permission.camera.request();
      if (result.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Camera permission is permanently denied. Please enable it in app settings'),
            action: SnackBarAction(
              label: 'SETTINGS',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return false;
      }
      return result.isGranted;
    }
  }

  Widget _buildEventSelection() {
    if (_isLoadingEvents) {
      return Center(child: CircularProgressIndicator());
    }

    if (_events.isEmpty) {
      return Center(child: Text('No events available'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select an Event',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        DropdownButton<Event>(
          value: _selectedEvent,
          hint: Text('Choose an event'),
          items: _events.map((event) {
            return DropdownMenuItem<Event>(
              value: event,
              child: Text(event.name),
            );
          }).toList(),
          onChanged: (Event? event) {
            setState(() {
              _selectedEvent = event;
            });
          },
        ),
        SizedBox(height: 24),
        if (_selectedEvent != null)
          ElevatedButton(
            onPressed: () async {
              final hasPermission = await _checkCameraPermission();
              if (hasPermission) {
                setState(() {
                  _showCamera = true;
                  _isScanning = true;
                });
              }
            },
            child: Text('Start Scanning'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
      ],
    );
  }

  Widget _buildScanner() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              MobileScanner(
                controller: _cameraController,
                onDetect: (BarcodeCapture capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    _handleScan(barcode);
                  }
                },
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildScanLog(),
      ],
    );
  }

  Widget _buildScanLog() {
    return Container(
      height: 120,
      padding: EdgeInsets.all(8),
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scan Log:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _scannedIds.length,
              itemBuilder: (context, index) {
                final id = _scannedIds[index];
                final isProcessed = _processedIds.contains(id);
                return ListTile(
                  leading: Icon(
                    isProcessed ? Icons.check_circle : Icons.error,
                    color: isProcessed ? Colors.green : Colors.red,
                  ),
                  title: Text('ID: $id'),
                  subtitle: Text(
                    isProcessed ? 'Registered' : 'Processing...',
                    style: TextStyle(
                      color: isProcessed ? Colors.green : Colors.red,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showCamera ? 'Scanning...' : 'Select Event'),
        actions: [
          if (_showCamera)
            IconButton(
              icon: Icon(_isScanning ? Icons.pause : Icons.play_arrow),
              onPressed: () {
                setState(() {
                  _isScanning = !_isScanning;
                  if (_isScanning) {
                    _cameraController.start();
                  } else {
                    _cameraController.stop();
                  }
                });
              },
            ),
        ],
      ),
      body: _showCamera ? _buildScanner() : _buildEventSelection(),
      floatingActionButton: _showCamera
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _showCamera = false;
                  _scannedIds.clear();
                  _processedIds.clear();
                });
              },
              child: Icon(Icons.arrow_back),
            )
          : null,
    );
  }
}

