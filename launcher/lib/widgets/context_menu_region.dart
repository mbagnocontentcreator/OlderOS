import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/olderos_theme.dart';

/// Widget che aggiunge un menu contestuale (tasto destro) per Copia/Incolla.
/// Avvolge qualsiasi widget che contiene campi di testo.
class ContextMenuRegion extends StatelessWidget {
  final Widget child;

  const ContextMenuRegion({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Builder personalizzato per il menu contestuale dei TextField
class OlderOSContextMenuBuilder {
  static Widget buildContextMenu(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    final List<ContextMenuButtonItem> buttonItems =
        editableTextState.contextMenuButtonItems;

    // Traduci le etichette in italiano
    final translatedItems = buttonItems.map((item) {
      String label = item.label ?? '';

      // Traduci le etichette standard
      if (label.toLowerCase() == 'cut') label = 'Taglia';
      if (label.toLowerCase() == 'copy') label = 'Copia';
      if (label.toLowerCase() == 'paste') label = 'Incolla';
      if (label.toLowerCase() == 'select all') label = 'Seleziona tutto';

      return ContextMenuButtonItem(
        onPressed: item.onPressed,
        label: label,
        type: item.type,
      );
    }).toList();

    return _OlderOSContextMenu(items: translatedItems);
  }
}

class _OlderOSContextMenu extends StatelessWidget {
  final List<ContextMenuButtonItem> items;

  const _OlderOSContextMenu({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OlderOSTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: items.map((item) {
              return _ContextMenuItem(
                label: item.label ?? '',
                icon: _getIconForType(item.type),
                onTap: item.onPressed,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(ContextMenuButtonType type) {
    switch (type) {
      case ContextMenuButtonType.cut:
        return Icons.content_cut;
      case ContextMenuButtonType.copy:
        return Icons.content_copy;
      case ContextMenuButtonType.paste:
        return Icons.content_paste;
      case ContextMenuButtonType.selectAll:
        return Icons.select_all;
      default:
        return Icons.more_horiz;
    }
  }
}

class _ContextMenuItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _ContextMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_ContextMenuItem> createState() => _ContextMenuItemState();
}

class _ContextMenuItemState extends State<_ContextMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onTap != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: _isHovered && isEnabled
              ? OlderOSTheme.primary.withAlpha(30)
              : Colors.transparent,
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 24,
                color: isEnabled
                    ? (_isHovered ? OlderOSTheme.primary : OlderOSTheme.textPrimary)
                    : OlderOSTheme.textSecondary,
              ),
              const SizedBox(width: 14),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: isEnabled
                      ? (_isHovered ? OlderOSTheme.primary : OlderOSTheme.textPrimary)
                      : OlderOSTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Estensione per TextField con menu contestuale personalizzato
class OlderOSTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final InputDecoration? decoration;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool obscureText;
  final bool autofocus;

  const OlderOSTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.style,
    this.hintStyle,
    this.decoration,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.obscureText = false,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      style: style,
      decoration: decoration?.copyWith(hintText: hintText) ??
          InputDecoration(
            hintText: hintText,
            hintStyle: hintStyle,
            border: InputBorder.none,
          ),
      maxLines: maxLines,
      minLines: minLines,
      expands: expands,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      obscureText: obscureText,
      autofocus: autofocus,
      contextMenuBuilder: OlderOSContextMenuBuilder.buildContextMenu,
    );
  }
}
