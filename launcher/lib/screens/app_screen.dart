import 'package:flutter/material.dart';
import '../theme/olderos_theme.dart';
import '../widgets/top_bar.dart';

class AppScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const AppScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TopBar(
            title: title,
            onGoHome: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 120,
                    color: color,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Questa funzione sara disponibile presto',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: OlderOSTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
