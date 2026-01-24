import 'package:flutter/material.dart';
import '../theme/olderos_theme.dart';

/// Logo OlderOS - Widget cross-platform che non dipende da emoji
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
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                OlderOSTheme.primary,
                OlderOSTheme.primary.withValues(alpha: 0.7),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: OlderOSTheme.primary.withValues(alpha: 0.4),
                blurRadius: size * 0.2,
                offset: Offset(0, size * 0.08),
              ),
            ],
          ),
          child: Icon(
            Icons.elderly,
            size: size * 0.55,
            color: Colors.white,
          ),
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
