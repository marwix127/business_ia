import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF475569), // Slate blue - complementa con modo oscuro
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE2E8F0), // Slate muy suave
      onPrimaryContainer: Color(0xFF1E293B),
      secondary: Color(0xFF64748B), // Slate medio para acentos
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFF1F5F9),
      onSecondaryContainer: Color(0xFF334155),
      tertiary: Color(0xFF0EA5E9), // Sky blue para detalles
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFE0F2FE),
      onTertiaryContainer: Color(0xFF0C4A6E),
      error: Color(0xFFDC2626),
      onError: Colors.white,
      errorContainer: Color(0xFFFEE2E2),
      onErrorContainer: Color(0xFF7F1D1D),
      surface: Color(0xFFF8FAFC), // Gris muy claro en lugar de blanco puro
      onSurface: Color(0xFF1E293B),
      onSurfaceVariant: Color(0xFF475569),
      outline: Color(0xFFCBD5E1),
    ),
    scaffoldBackgroundColor: const Color(
      0xFFF1F5F9,
    ), // Fondo suave gris-azulado
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF475569),
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontSize: 16, letterSpacing: 0.15),
      bodyMedium: TextStyle(fontSize: 14, letterSpacing: 0.25),
    ),
    cardTheme: CardThemeData(
      color: const Color(
        0xFFFFFFFE,
      ), // Blanco muy suave (casi imperceptible tinte)
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      filled: true,
      fillColor: Color(0xFFE2E8F0), // Gris-azul claro
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Color(0xFF475569), width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF475569),
        foregroundColor: Colors.white,
        elevation: 1,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF475569),
      foregroundColor: Colors.white,
      elevation: 3,
    ),
    iconTheme: const IconThemeData(color: Color(0xFF475569), size: 24),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE2E8F0),
      thickness: 1,
    ),
  );
  // Dark Theme

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF64748B), // Slate - armoniza con fondos
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFF334155), // Slate más oscuro
      onPrimaryContainer: Color(0xFFE2E8F0),
      secondary: Color(0xFF475569), // Slate medio para acentos
      onSecondary: Color(0xFFF1F5F9),
      secondaryContainer: Color(0xFF1E293B),
      onSecondaryContainer: Color(0xFFCBD5E1),
      tertiary: Color(0xFF0EA5E9), // Sky blue solo para detalles puntuales
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFF0C4A6E),
      onTertiaryContainer: Color(0xFFBAE6FD),
      error: Color(0xFFEF4444),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFF7F1D1D),
      onErrorContainer: Color(0xFFFEE2E2),
      surface: Color(0xFF1A1F2E), // Azul-gris oscuro
      onSurface: Colors.white,
      onSurfaceVariant: Colors.white,
      outline: Color(0xFF475569),
      surfaceContainerHighest: Color(0xFF252D3D),
    ),
    scaffoldBackgroundColor: const Color(0xFF0F1419), // Negro azulado profundo
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1F2E),
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Color(0xFFF1F5F9),
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
      iconTheme: IconThemeData(color: Color(0xFFF1F5F9)),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: Color(0xFFF1F5F9),
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFFE2E8F0),
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        letterSpacing: 0.15,
        color: Color(0xFFE2E8F0),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        letterSpacing: 0.25,
        color: Color(0xFFCBD5E1),
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A1F2E),
      elevation: 2,
      shadowColor: Colors.black.withAlpha(150),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      filled: true,
      fillColor: Color(0xFF252D3D),
      hintStyle: TextStyle(color: Color(0xFF64748B)),
      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Color(0xFF64748B), width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF64748B),
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withAlpha(150),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF64748B),
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    iconTheme: const IconThemeData(color: Color(0xFFCBD5E1), size: 24),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF334155),
      thickness: 1,
    ),
  );
}
