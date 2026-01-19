import 'package:flutter/material.dart';
import '../theme/olderos_theme.dart';

/// Tastierino numerico ottimizzato per anziani
class PinKeypad extends StatelessWidget {
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onDelete;
  final VoidCallback? onConfirm;
  final double buttonSize;
  final bool showConfirm;
  final bool enabled;

  const PinKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onDelete,
    this.onConfirm,
    this.buttonSize = 80,
    this.showConfirm = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Riga 1-2-3
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 16),
        // Riga 4-5-6
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 16),
        // Riga 7-8-9
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 16),
        // Riga Cancella-0-Conferma
        _buildBottomRow(),
      ],
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: digits.map((digit) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _PinButton(
            label: digit,
            size: buttonSize,
            enabled: enabled,
            onPressed: () => onDigitPressed(digit),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsante Cancella
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _PinActionButton(
            icon: Icons.backspace_outlined,
            label: 'Cancella',
            size: buttonSize,
            enabled: enabled,
            onPressed: onDelete,
            color: OlderOSTheme.danger,
          ),
        ),
        // Pulsante 0
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _PinButton(
            label: '0',
            size: buttonSize,
            enabled: enabled,
            onPressed: () => onDigitPressed('0'),
          ),
        ),
        // Pulsante Conferma o spazio vuoto
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: showConfirm && onConfirm != null
              ? _PinActionButton(
                  icon: Icons.check,
                  label: 'OK',
                  size: buttonSize,
                  enabled: enabled,
                  onPressed: onConfirm!,
                  color: OlderOSTheme.success,
                )
              : SizedBox(width: buttonSize, height: buttonSize),
        ),
      ],
    );
  }
}

/// Pulsante numerico del tastierino
class _PinButton extends StatelessWidget {
  final String label;
  final double size;
  final VoidCallback onPressed;
  final bool enabled;

  const _PinButton({
    required this.label,
    required this.size,
    required this.onPressed,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(size / 2),
        splashColor: OlderOSTheme.primary.withValues(alpha: 0.3),
        highlightColor: OlderOSTheme.primary.withValues(alpha: 0.1),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey[200],
            shape: BoxShape.circle,
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
                color: enabled ? OlderOSTheme.textPrimary : Colors.grey[400],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pulsante azione (Cancella/Conferma)
class _PinActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final double size;
  final VoidCallback onPressed;
  final Color color;
  final bool enabled;

  const _PinActionButton({
    required this.icon,
    required this.label,
    required this.size,
    required this.onPressed,
    required this.color,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : Colors.grey[400]!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(size / 2),
        splashColor: effectiveColor.withValues(alpha: 0.3),
        highlightColor: effectiveColor.withValues(alpha: 0.1),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: effectiveColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: effectiveColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: size * 0.35,
              color: effectiveColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget per visualizzare il PIN inserito come pallini
class PinDisplay extends StatelessWidget {
  final int length;
  final int maxLength;
  final bool hasError;
  final double dotSize;

  const PinDisplay({
    super.key,
    required this.length,
    this.maxLength = 6,
    this.hasError = false,
    this.dotSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxLength, (index) {
        final isFilled = index < length;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: isFilled
                ? (hasError ? OlderOSTheme.danger : OlderOSTheme.primary)
                : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: hasError
                  ? OlderOSTheme.danger
                  : (isFilled ? OlderOSTheme.primary : Colors.grey[400]!),
              width: 3,
            ),
          ),
        );
      }),
    );
  }
}

/// Animazione shake per errore PIN
class ShakeAnimation extends StatefulWidget {
  final Widget child;
  final bool shake;
  final VoidCallback? onShakeComplete;

  const ShakeAnimation({
    super.key,
    required this.child,
    required this.shake,
    this.onShakeComplete,
  });

  @override
  State<ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticIn),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reset();
        widget.onShakeComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(ShakeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final offset = _animation.value * 20 * _shakeOffset(_animation.value);
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }

  double _shakeOffset(double progress) {
    // Oscillazione che diminuisce nel tempo
    return (1 - progress) * (progress * 10).remainder(1) > 0.5 ? 1 : -1;
  }
}
