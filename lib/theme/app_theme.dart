import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const yellow = Color(0xFFFFDA00);
const paleYellow = Color(0xFFFFF3A6);
const ink = Color(0xFF222222);
const paper = Color(0xFFFFFFFF);
const muted = Color(0xFF595959);
const line = Color(0xFFE2E2E2);
const green = Color(0xFF146C4E);
const red = Color(0xFFB42318);
const blue = Color(0xFF205E9B);
const wash = Color(0xFFF6F6F6);

ThemeData appTheme(bool highContrast) {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: yellow,
        brightness: Brightness.light,
      ).copyWith(
        primary: ink,
        onPrimary: paper,
        primaryContainer: paleYellow,
        onPrimaryContainer: ink,
        secondary: yellow,
        onSecondary: ink,
        surface: paper,
        surfaceContainerLowest: paper,
        surfaceContainerLow: paper,
        surfaceContainer: wash,
        onSurface: ink,
        outline: highContrast ? ink : line,
      );
  return ThemeData(
    useMaterial3: true,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    colorScheme: scheme,
    fontFamily: 'NotoSansJP',
    scaffoldBackgroundColor: paper,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 30,
        height: 1.45,
        fontWeight: FontWeight.w700,
        letterSpacing: -.8,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        height: 1.5,
        fontWeight: FontWeight.w700,
        letterSpacing: -.5,
      ),
      titleLarge: TextStyle(
        fontSize: 21,
        height: 1.5,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        height: 1.6,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.75),
      bodyMedium: TextStyle(fontSize: 14, height: 1.65),
      labelLarge: TextStyle(
        fontSize: 17,
        height: 1.5,
        fontWeight: FontWeight.w700,
      ),
      labelMedium: TextStyle(
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w600,
      ),
    ).apply(bodyColor: ink, displayColor: ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: paper,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    dividerTheme: const DividerThemeData(color: line, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      labelStyle: TextStyle(color: highContrast ? ink : muted),
      hintStyle: TextStyle(color: highContrast ? ink : muted),
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: highContrast ? ink : const Color(0xFF909090),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: highContrast ? ink : const Color(0xFF909090),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ink, width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: const BorderSide(color: line),
      selectedColor: paleYellow,
    ),
    splashFactory: InkSparkle.splashFactory,
  );
}
