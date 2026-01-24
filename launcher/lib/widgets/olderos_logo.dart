import 'package:flutter/material.dart';
import '../theme/olderos_theme.dart';

/// Logo OlderOS - Widget cross-platform con emoji anziano
class OlderOSLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const OlderOSLogo({
    super.key,
    this.size = 100,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Emoji anziano come immagine (funziona su tutte le piattaforme)
        Image.asset(
          'assets/images/elderly_emoji.png',
          width: size,
          height: size,
          filterQuality: FilterQuality.high,
        ),
        if (showText) ...[
          SizedBox(height: size * 0.24),
          Text(
            'OlderOS',
            style: TextStyle(
              fontSize: size * 0.36,
              fontWeight: FontWeight.bold,
              color: OlderOSTheme.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}
