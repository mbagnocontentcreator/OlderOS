import 'package:flutter/material.dart';
import '../services/user_service.dart';

/// Colori disponibili per gli avatar utente
class UserAvatarColors {
  static const List<Color> colors = [
    Color(0xFF2196F3), // Blu
    Color(0xFF4CAF50), // Verde
    Color(0xFFE91E63), // Rosa
    Color(0xFF9C27B0), // Viola
    Color(0xFFFF5722), // Arancione
    Color(0xFF00BCD4), // Ciano
    Color(0xFF795548), // Marrone
    Color(0xFF607D8B), // Grigio blu
  ];

  static Color getColor(int index) {
    return colors[index % colors.length];
  }
}

/// Widget per visualizzare l'avatar di un utente
class UserAvatar extends StatelessWidget {
  final User? user;
  final double size;
  final bool showName;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;

  /// Avatar per un utente specifico
  const UserAvatar({
    super.key,
    required this.user,
    this.size = 120,
    this.showName = false,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return _buildEmptyAvatar();
    }

    final avatarColor = UserAvatarColors.getColor(user!.avatarColorIndex);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: avatarColor,
              shape: BoxShape.circle,
              border: showBorder
                  ? Border.all(
                      color: borderColor ?? Colors.white,
                      width: 4,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: avatarColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                user!.initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (showName) ...[
            const SizedBox(height: 12),
            Text(
              user!.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: Colors.grey[600],
      ),
    );
  }
}

/// Widget per lo slot di aggiunta nuovo utente
class AddUserSlot extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  const AddUserSlot({
    super.key,
    this.size = 120,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey[400]!,
                width: 3,
                style: BorderStyle.solid,
              ),
            ),
            child: Icon(
              Icons.add,
              size: size * 0.4,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Aggiungi',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget per la selezione del colore avatar
class AvatarColorPicker extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onColorSelected;
  final double itemSize;

  const AvatarColorPicker({
    super.key,
    required this.selectedIndex,
    required this.onColorSelected,
    this.itemSize = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: List.generate(
        UserAvatarColors.colors.length,
        (index) => _buildColorItem(index),
      ),
    );
  }

  Widget _buildColorItem(int index) {
    final color = UserAvatarColors.colors[index];
    final isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: () => onColorSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: itemSize,
        height: itemSize,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: Colors.white,
                  width: 4,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 32,
              )
            : null,
      ),
    );
  }
}
