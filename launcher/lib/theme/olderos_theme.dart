import 'dart:io' show Platform;
import 'package:flutter/material.dart';

class OlderOSTheme {
  // Colori dalla specifica
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color primary = Color(0xFF2563EB);
  static const Color success = Color(0xFF16A34A);
  static const Color danger = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);

  // Colori per le icone delle app
  static const Color internetColor = Color(0xFF2563EB);
  static const Color emailColor = Color(0xFFDC2626);
  static const Color writerColor = Color(0xFF16A34A);
  static const Color photosColor = Color(0xFFF59E0B);
  static const Color videoCallColor = Color(0xFF7C3AED);
  static const Color settingsColor = Color(0xFF6B7280);
  static const Color calculatorColor = Color(0xFF059669);   // Verde smeraldo
  static const Color calendarColor = Color(0xFFE11D48);     // Rosa/Rosso
  static const Color tableColor = Color(0xFF0891B2);        // Ciano/Teal
  static const Color contactsColor = Color(0xFFEA580C);     // Arancione

  // Spaziature
  static const double paddingCard = 24.0;
  static const double gapElements = 20.0;
  static const double marginScreen = 32.0;
  static const double borderRadiusCard = 16.0;

  // Dimensioni minime per accessibilita
  static const double minTouchTarget = 60.0;
  static const double appCardSize = 200.0;
  static const double iconSize = 64.0;

  // Font cross-platform: Ubuntu su Linux, SF Pro su macOS
  static String get _fontFamily {
    if (Platform.isLinux) {
      return 'Ubuntu';
    } else if (Platform.isMacOS) {
      return '.SF Pro Text';
    }
    return 'Roboto';
  }

  // Font fallback per garantire compatibilità cross-platform
  static const List<String> _fontFallback = [
    'Ubuntu',
    'Roboto',
    'DejaVu Sans',
    'Liberation Sans',
    'sans-serif',
  ];

  static ThemeData get theme {
    final font = _fontFamily;

    return ThemeData(
      useMaterial3: true,
      fontFamily: font,
      fontFamilyFallback: _fontFallback,
      colorScheme: ColorScheme.light(
        surface: background,
        primary: primary,
        onPrimary: Colors.white,
        secondary: textSecondary,
        error: danger,
      ),
      scaffoldBackgroundColor: background,
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFamily: font,
          fontFamilyFallback: _fontFallback,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: font,
          fontFamilyFallback: _fontFallback,
        ),
        titleLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          fontFamily: font,
          fontFamilyFallback: _fontFallback,
        ),
        titleMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          fontFamily: font,
          fontFamilyFallback: _fontFallback,
        ),
        bodyLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          fontFamily: font,
          fontFamilyFallback: _fontFallback,
        ),
        bodyMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.normal,
          color: textSecondary,
          fontFamily: font,
          fontFamilyFallback: _fontFallback,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusCard),
          ),
          textStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusCard),
        ),
      ),
    );
  }
}
