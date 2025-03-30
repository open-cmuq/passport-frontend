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
import 'constants/app_colors.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoCampus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: Colors.white,
          background: AppColors.background,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.textPrimary,
          onBackground: AppColors.textPrimary,
          brightness: Brightness.light,
        ),
        primaryColor: AppColors.primary,
        hintColor: AppColors.textSecondary,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          iconTheme: IconThemeData(color: AppColors.primary),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 25,
          ),
          elevation: 0,
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(color: AppColors.textPrimary),
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textSecondary),
          labelLarge: TextStyle(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.primary),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          elevation: 8,
        ),
      ),
      home: FutureBuilder<String?>(
        future: _getValidToken(),
        builder: (context, snapshot) {
          debugPrint("Loading init point");
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            debugPrint("Going to mainscreen");
            return MainScreen();
          }

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
