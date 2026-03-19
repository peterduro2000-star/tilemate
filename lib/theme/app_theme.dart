import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  AppTheme._();

  // ── Palette ─────────────────────────────────────────────────────────────────
  static const Color bg         = Color(0xFF0F0F0F); // near-black
  static const Color surface    = Color(0xFF1A1A1A); // card surface
  static const Color surfaceAlt = Color(0xFF242424); // elevated card
  static const Color border     = Color(0xFF2E2E2E); // subtle border
  static const Color amber      = Color(0xFFF5A623); // grout amber — primary accent
  static const Color amberDark  = Color(0xFFB87A14); // pressed / dark amber
  static const Color amberGlow  = Color(0x33F5A623); // amber at 20% opacity
  static const Color textHigh   = Color(0xFFF0EDE8); // primary text (warm white)
  static const Color textMid    = Color(0xFF9A9590);  // secondary text
  static const Color textLow    = Color(0xFF5C5855);  // disabled / hint
  static const Color success    = Color(0xFF4CAF6E);
  static const Color error      = Color(0xFFE05252);
  static const Color info       = Color(0xFF5B9FE0);

  // ── Typography ───────────────────────────────────────────────────────────────
  // Using Google Fonts via pubspec — add:
  //   google_fonts: ^6.1.0
  // For now we use a bold TextTheme with adjusted letterSpacing.
  static TextTheme get _textTheme => const TextTheme(
        displayLarge: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.5,
          color: textHigh,
          height: 1.05,
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
          color: textHigh,
          height: 1.1,
        ),
        headlineLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: textHigh,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: textHigh,
        ),
        headlineSmall: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: textHigh,
        ),
        titleLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: textHigh,
        ),
        titleMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: textMid,
        ),
        titleSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: textMid,
        ),
        bodyLarge: TextStyle(fontSize: 15, color: textHigh, height: 1.5),
        bodyMedium: TextStyle(fontSize: 13, color: textMid, height: 1.5),
        bodySmall: TextStyle(fontSize: 11, color: textLow, height: 1.4),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: bg,
        ),
      );

  // ── Theme ────────────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: amber,
          onPrimary: bg,
          secondary: amberDark,
          onSecondary: bg,
          surface: surface,
          onSurface: textHigh,
          error: error,
          onError: textHigh,
          outline: border,
        ),
        textTheme: _textTheme,

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          foregroundColor: textHigh,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          titleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: textHigh,
          ),
        ),

        // Input fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceAlt,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: amber, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: error),
          ),
          hintStyle: const TextStyle(color: textLow, fontSize: 14),
          labelStyle: const TextStyle(color: textMid, fontSize: 13),
          floatingLabelStyle: const TextStyle(color: amber, fontSize: 12, fontWeight: FontWeight.w600),
        ),

        // Elevated button
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: amber,
            foregroundColor: bg,
            disabledBackgroundColor: border,
            disabledForegroundColor: textLow,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // Text button
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: amber,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),

        // Outlined button
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: amber,
            side: const BorderSide(color: amber),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),

        // Card
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: border),
          ),
          margin: EdgeInsets.zero,
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: border,
          thickness: 1,
          space: 1,
        ),

        // BottomNav
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surface,
          indicatorColor: amberGlow,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: amber, size: 22);
            }
            return const IconThemeData(color: textLow, size: 22);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  color: amber, fontSize: 11, fontWeight: FontWeight.w700);
            }
            return const TextStyle(color: textLow, fontSize: 11);
          }),
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),

        // Chip
        chipTheme: ChipThemeData(
          backgroundColor: surfaceAlt,
          selectedColor: amberGlow,
          labelStyle: const TextStyle(color: textMid, fontSize: 12),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),

        // Slider
        sliderTheme: const SliderThemeData(
          activeTrackColor: amber,
          thumbColor: amber,
          inactiveTrackColor: border,
          overlayColor: amberGlow,
        ),

        // FloatingActionButton
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: amber,
          foregroundColor: bg,
          elevation: 4,
        ),

        // SnackBar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: surfaceAlt,
          contentTextStyle: const TextStyle(color: textHigh, fontSize: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          behavior: SnackBarBehavior.floating,
        ),
      );
}