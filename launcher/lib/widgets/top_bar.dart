import 'package:flutter/material.dart';
import '../theme/olderos_theme.dart';

class TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onGoHome;

  const TopBar({
    super.key,
    required this.title,
    required this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OlderOSTheme.marginScreen,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: OlderOSTheme.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _HomeButton(onTap: onGoHome),
          const Spacer(),
          Text(
            title,
            style: Theme.of(context).textTheme.displayMedium,
          ),
        ],
      ),
    );
  }
}

class _HomeButton extends StatefulWidget {
  final VoidCallback onTap;

  const _HomeButton({required this.onTap});

  @override
  State<_HomeButton> createState() => _HomeButtonState();
}

class _HomeButtonState extends State<_HomeButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.identity()
            ..scale(_isPressed ? 0.98 : 1.0),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered ? OlderOSTheme.primary : OlderOSTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: OlderOSTheme.primary,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.home_rounded,
                size: 32,
                color: _isHovered ? Colors.white : OlderOSTheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'TORNA A CASA',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _isHovered ? Colors.white : OlderOSTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
