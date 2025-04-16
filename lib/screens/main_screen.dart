// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'events/events_screen.dart';
import 'profile_screen.dart';
import 'awards_screen.dart';
import 'scan_screen.dart'; // You'll need to create this screen
import '../models/user_model.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  User? _currentUser;
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');

    if (userJson != null) {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      setState(() {
        _currentUser = User.fromJson(userMap);
        _isAdmin = _currentUser?.role?.toLowerCase() == 'admin' ||
            _currentUser?.role?.toLowerCase() == 'staff';
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Widget> get _widgetOptions {
    return <Widget>[
      EventsScreen(),
      ProfileScreen(),
      AwardsScreen(),
      if (_isAdmin) ScanScreen(), // Only include if admin
    ];
  }

  List<BottomNavigationBarItem> get _navBarItems {
    final baseItems = [
      BottomNavigationBarItem(
        icon: Icon(Icons.event),
        label: 'Events',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profile',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.emoji_events),
        label: 'Awards',
      ),
    ];

    if (_isAdmin) {
      return [
        ...baseItems,
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner),
          label: 'Scan',
        ),
      ];
    }
    return baseItems;
  }

  void _onItemTapped(int index) {
    // If not admin and trying to access scan (index 3), don't allow
    if (!_isAdmin && index >= 3) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.grey[600],
        items: _navBarItems,
        type: BottomNavigationBarType.fixed, // For more than 3 items
      ),
    );
  }
}
