import 'package:flutter/material.dart';
import 'constants.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryBlue = Color(0xFF1B85C4);
  static const Color navyDark = Color(0xFF0D2C54);
  static const Color freshGreen = Color(0xFF8DC63F);
  static const Color scaffoldBg = Color(0xFFF8FBFE);
  static const Color surfaceWhite = Colors.white;
  static const Color greyText = Color(0xFF536D8E);
  static const Color borderGrey = Color(0xFFE0E0E0);

  // Theme Notifier for global toggle
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

  static TextTheme _buildTextTheme(TextTheme base, Color textColor) {
    return base.copyWith(
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: greyText,
      ),
    ).apply(
      fontFamily: AppConstants.fontFamily,
    );
  }

  // --- LIGHT THEME ---
  static ThemeData get vastraFixTheme {
    final ThemeData base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: freshGreen,
        surface: surfaceWhite,
        brightness: Brightness.light,
      ),
      textTheme: _buildTextTheme(base.textTheme, navyDark),
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldBg,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: navyDark),
        titleTextStyle: TextStyle(color: navyDark, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: AppConstants.fontFamily),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: navyDark.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMedium)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: freshGreen,
          foregroundColor: Colors.white,
          // 🔹 double.infinity ki jagah fix height dein, width automatic lene dein
          minimumSize: const Size(88, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSmall)),
        ),
      ),
      inputDecorationTheme: _inputDecoration(borderGrey, navyDark , false),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // --- DARK THEME ---
  static ThemeData get darkTheme {
    final ThemeData base = ThemeData.dark(useMaterial3: true);
    const Color darkBg = Color(0xFF06162C); // Deep Navy background
    return base.copyWith(
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: darkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: freshGreen,
        surface: navyDark,
        brightness: Brightness.dark,
      ),
      textTheme: _buildTextTheme(base.textTheme, Colors.white),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        color: navyDark,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMedium)),
      ),
      inputDecorationTheme: _inputDecoration(borderGrey, navyDark, false),
    );
  }

  // 🔹 Purane _inputDecoration ko hata kar ise paste karein
  static InputDecorationTheme _inputDecoration(Color bColor, Color tColor, bool isDark) {
    return InputDecorationTheme(
      filled: true,
      // Agar dark mode hai toh navyDark (dark blue), light mode mein white
      fillColor: isDark ? navyDark : surfaceWhite,
      contentPadding: const EdgeInsets.all(16),
      border: _outlineBorder(bColor),
      enabledBorder: _outlineBorder(bColor),
      focusedBorder: _outlineBorder(primaryBlue, width: 1.5),

      // Text colors fix karne ke liye:
      labelStyle: TextStyle(color: tColor, fontSize: 14),
      hintStyle: TextStyle(color: tColor.withValues(alpha: 0.5), fontSize: 14),
      floatingLabelStyle: const TextStyle(color: primaryBlue),
    );
  }

  static OutlineInputBorder _outlineBorder(Color color, {double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}