import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const GrooveGardenApp());
}

class GrooveGardenApp extends StatelessWidget {
  const GrooveGardenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GrooveGarden',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: HomeScreen(),
    );
  }
}
