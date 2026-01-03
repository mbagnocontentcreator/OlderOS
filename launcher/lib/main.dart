import 'package:flutter/material.dart';
import 'theme/olderos_theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const OlderOSApp());
}

class OlderOSApp extends StatelessWidget {
  const OlderOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OlderOS',
      debugShowCheckedModeBanner: false,
      theme: OlderOSTheme.theme,
      home: const HomeScreen(),
    );
  }
}
