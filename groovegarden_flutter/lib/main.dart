import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:groovegarden_flutter/utils/secure_storage.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'dart:html' as html;
import 'dart:async';

void main() {
  runApp(const GrooveGardenApp());
}

class GrooveGardenApp extends StatefulWidget {
  // Add a key parameter to the constructor
  const GrooveGardenApp({super.key});

  @override
  // Use public class for the state
  State<GrooveGardenApp> createState() => GrooveGardenAppState();
}

class GrooveGardenAppState extends State<GrooveGardenApp> {
  // Flag to force refresh of token state
  bool _forceRefresh = false;
  late StreamSubscription<html.Event> _storageListener;

  @override
  void initState() {
    super.initState();

    // Listen for storage changes from other tabs
    _storageListener = html.window.onStorage.listen((html.StorageEvent event) {
      if (event.key == 'oauth_token_received') {
        log('Detected token update from another tab');

        // Force token refresh and UI update
        setState(() {
          _forceRefresh = true;
        });

        // Remove the marker from localStorage
        html.window.localStorage.remove('oauth_token_received');
      }
    });

    // Check if we should store a new token from URL
    _processUrlToken();
  }

  @override
  void dispose() {
    _storageListener.cancel();
    super.dispose();
  }

  // Process any token in the URL
  void _processUrlToken() {
    try {
      final url = html.window.location.href;
      final uri = Uri.parse(url);
      final token = uri.queryParameters['token'];
      log('Checking for token in URL: ${token != null ? "Token found" : "No token"}');

      if (token != null) {
        // Store the token
        SecureStorage.saveToken(token);

        // Remove the token from the URL for security
        html.window.history.pushState({}, '', uri.origin + uri.path);

        // Notify other tabs that token was received
        html.window.localStorage['oauth_token_received'] = 'true';

        // Also update current tab
        setState(() {
          _forceRefresh = true;
        });
      }
    } catch (e) {
      log('Error processing URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GrooveGarden',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      // Navigate based on whether the token exists
      home: FutureBuilder<String?>(
        // Force rebuild by adding _forceRefresh to the future
        future: _forceRefresh
            ? SecureStorage.getToken().then((token) {
                // Reset the flag after refresh
                Future.microtask(() => setState(() => _forceRefresh = false));
                return token;
              })
            : SecureStorage.getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final savedToken = snapshot.data;
          return savedToken != null ? HomeScreen(jwtToken: savedToken) : const LoginScreen();
        },
      ),
    );
  }
}
