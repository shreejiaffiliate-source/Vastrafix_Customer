import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = "VastraFix";
  static const String appTagline = "Ironing & Laundry at Your Doorstep";

  // 🔹 Font
  static const String fontFamily = "Poppins";

  // 🔹 Spacing
  static const double paddingXS = 6.0;
  static const double paddingSmall = 10.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXL = 32.0;

  // 🔹 Radius (Luxury rounded)
  static const double radiusSmall = 10.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
}

// AppColors

class AppColors {
  // Primary Brand
  static const Color navyDark = Color(0xFF0D2C54);    // Outer circular ring
  static const Color primaryBlue = Color(0xFF1B85C4); // The Iron & Water Drop
  static const Color freshGreen = Color(0xFF8DC63F);  // The Leaf accent
  static const Color skyLight = Color(0xFFE3F2FD);    // Light blue for backgrounds

  // Backgrounds
  static const Color background = Color(0xFFF8FBFE);  // Very light blue tint
  static const Color card = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF0D2C54);  // Use Navy for text
  static const Color textSecondary = Color(0xFF536D8E);
  static const Color textMuted = Color(0xFFB0B0B0);

  // Utility
  static const Color divider = Color(0xFFE0E0E0);
  static const Color success = Color(0xFF8DC63F);
  static const Color error = Color(0xFFD32F2F);

}

class AppTextStyles {

  static const TextStyle heading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamily: AppConstants.fontFamily,
  );

  static const TextStyle subHeading = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    fontFamily: AppConstants.fontFamily,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
    fontFamily: AppConstants.fontFamily,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
    fontFamily: AppConstants.fontFamily,
  );

  static const TextStyle price = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryBlue,
    fontFamily: AppConstants.fontFamily,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    fontFamily: AppConstants.fontFamily,
  );
}