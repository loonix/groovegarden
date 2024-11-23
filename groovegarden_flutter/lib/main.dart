import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:groovegarden_flutter/utils/secure_storage.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'dart:html' as html;

void main() {
  runApp(GrooveGardenApp());
}

class GrooveGardenApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Check for token in URL
    final url = html.window.location.href;
    final uri = Uri.parse(url);
    final token = uri.queryParameters['token'];
    debugger();
    // Store the token in secure storage if present
    if (token != null) {
      SecureStorage.saveToken(token);
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GrooveGarden',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      // Navigate based on whether the token exists
      home: FutureBuilder<String?>(
        future: SecureStorage.getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final savedToken = snapshot.data;
          return savedToken != null ? HomeScreen(jwtToken: savedToken) : LoginScreen();
        },
      ),
    );
  }
}
