import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(
    0xFFEE6AA7,
  ); // Pink shade suitable for ovarian theme
  static const Color secondary = Color(0xFFF6C6EA); // Lighter pink
  static const Color accent = Color(
    0xFF7F93D1,
  ); // Complementary blue/purple shade
  static const Color background = Colors.white;
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);
}

class AppStyles {
  static const TextStyle headingLarge = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.0,
    color: AppColors.textSecondary,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 24.0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
  );

  static ButtonStyle outlineButton = OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: const BorderSide(color: AppColors.primary),
    padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 24.0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
  );

  static InputDecoration textFieldDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.secondary),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.secondary),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(
      vertical: 16.0,
      horizontal: 16.0,
    ),
  );
}
