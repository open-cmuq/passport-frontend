// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/auth_service.dart';
import 'otp_screen.dart';
import '../main_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo Placeholder
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green[100],
                ),
                child: Icon(Icons.eco, size: 60, color: Colors.green[700]),
              ),
              SizedBox(height: 20),
              Text(
                'EcoCampus Registration',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              SizedBox(height: 30),
              // Name Field
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person, color: Colors.green[700]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 15),
              // Email Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email, color: Colors.green[700]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 15),
              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock, color: Colors.green[700]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              // Register Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isLoading ? null : _handleRegistration,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Register',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
              ),
              SizedBox(height: 15),
              // Login Button
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.pushReplacementNamed(context, '/login'),
                child: Text(
                  "Have an account? Login",
                  style: TextStyle(
                      color: Colors.green[800], fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegistration() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validate fields
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(msg: 'Please fill all fields');
      return;
    }

    if (password.length < 8) {
      Fluttertoast.showToast(msg: 'Password must be at least 8 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.register(name, email, password);

      if (result['success'] == true) {
        if (result['requiresOTP'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OTPScreen(),
              settings: RouteSettings(arguments: email),
            ),
          );
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? 'Registration failed',
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'An error occurred: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
