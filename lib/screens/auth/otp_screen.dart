// lib/screens/auth/otp_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/auth_service.dart';
import '../home_screen.dart';
import 'register_screen.dart';

class OTPScreen extends StatelessWidget {
  final _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final email = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(title: Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Enter OTP sent to $email'),
            TextField(controller: _otpController, decoration: InputDecoration(labelText: 'OTP')),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final otp = _otpController.text.trim();
                if (otp.isEmpty) {
                  Fluttertoast.showToast(msg: 'Please enter OTP');
                  return;
                }

                final success = await AuthService.verifyOTP(email, otp);
                if (success) {
                  Navigator.pushReplacementNamed(context, '/home');
                } else {
                  Fluttertoast.showToast(msg: 'Invalid or expired OTP');
                }
              },
              child: Text('Verify OTP'),
            ),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
              child: Text('No registration found? Register'),
            ),
          ],
        ),
      ),
    );
  }
}
