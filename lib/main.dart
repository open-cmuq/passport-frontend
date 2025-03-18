// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/home_screen.dart';
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
        future: AuthService.getToken(),
        builder: (context, snapshot) {
          // Show a loading indicator while checking the token
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // If the token exists and is valid, navigate to HomeScreen
          if (snapshot.hasData && snapshot.data != null) {
            final token = snapshot.data!;
            if (AuthService.isTokenExpired(token)) {
              // Token is expired, log out and navigate to LoginScreen
              AuthService.logout();
              return LoginScreen();
            } else {
              // Token is valid, navigate to HomeScreen
              return HomeScreen();
            }
          }

          // No token or token is invalid, navigate to LoginScreen
          return LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/otp': (context) => OTPScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
