// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoCampus',
      theme: ThemeData(primarySwatch: Colors.green),
      home: FutureBuilder<String?>(
        future: _getValidToken(),
        builder: (context, snapshot) {
          debugPrint("Loading init point");
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // If we have a valid token (either existing or refreshed)
          if (snapshot.hasData && snapshot.data != null) {
            debugPrint("Going to mainscreen");  // More reliable than print()
            return MainScreen();
          }

          // If no valid token could be obtained
          debugPrint("Going to login");
          return LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/otp': (context) => OTPScreen(),
        '/home': (context) => MainScreen(),
      },
    );
  }

  Future<String?> _getValidToken() async {
    final token = await AuthService.getAccessToken();
    
    // If no token exists at all
    if (token == null) return null;
    
    debugPrint("Checking in main if isAccessTokenExpired");
    // If token is still valid
    if (!AuthService.isAccessTokenExpired(token)) return token;
    debugPrint("It isn't, attempt to refresh it");
    // Attempt to refresh token
    try {
      final refreshed = await AuthService.refreshToken();
      if (refreshed) {
        debugPrint("Successfully refreshed on the main dart");
        return await AuthService.getAccessToken();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
