import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(GrooveGardenApp());
}

class GrooveGardenApp extends StatelessWidget {
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
