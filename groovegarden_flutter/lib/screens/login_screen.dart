import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _loginWithGoogle() async {
    final url = Uri.parse('http://localhost:8081/google/login');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: _loginWithGoogle,
          child: const Text('Login with Google'),
        ),
      ),
    );
  }
}
