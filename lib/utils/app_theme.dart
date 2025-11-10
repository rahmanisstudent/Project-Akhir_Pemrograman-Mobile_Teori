import 'package:flutter/material.dart';

// minta AI buatin color palette wkwk
const Color kPrimaryColor = Color(0xFF2196F3); // Modern Blue
const Color kSecondaryColor = Color(0xFFFF9800); // Energetic Orange
const Color kAccentColor = Color(0xFF4CAF50); // Success Green
const Color kBackgroundColor = Color(0xFFF5F7FA); // Light Gray Background
const Color kCardColor = Color(0xFFFFFFFF); // Pure White Cards
const Color kSuccessColor = Color(0xFF4CAF50); // Green for discounts
const Color kErrorColor = Color(0xFFE91E63); // Pink for wishlist/errors
const Color kTextPrimaryColor = Color(0xFF2C3E50); // Dark text
const Color kTextSecondaryColor = Color(0xFF7F8C8D); // Gray text

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: kPrimaryColor,
      scaffoldBackgroundColor: kBackgroundColor,
      cardColor: kCardColor,

      colorScheme: ColorScheme.light(
        primary: kPrimaryColor,
        secondary: kSecondaryColor,
        background: kBackgroundColor,
        surface: kCardColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: kTextPrimaryColor,
        onSurface: kTextPrimaryColor,
        error: kErrorColor,
        onError: Colors.white,
        surfaceVariant: Colors.grey[100]!,
        onSurfaceVariant: kTextSecondaryColor,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: kCardColor,
        foregroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: kTextPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: kPrimaryColor),
        shadowColor: Colors.black12,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: kCardColor,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: kTextSecondaryColor,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showUnselectedLabels: true,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: kPrimaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: kErrorColor, width: 1.5),
        ),
        labelStyle: TextStyle(color: kTextSecondaryColor, fontSize: 14),
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 3,
        color: kCardColor,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[100]!,
        selectedColor: kPrimaryColor.withOpacity(0.2),
        labelStyle: TextStyle(
          color: kTextPrimaryColor,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color: kPrimaryColor,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Text Theme
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: kTextPrimaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        headlineMedium: TextStyle(
          color: kTextPrimaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        headlineSmall: TextStyle(
          color: kTextPrimaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        titleLarge: TextStyle(
          color: kTextPrimaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleMedium: TextStyle(
          color: kTextPrimaryColor,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(color: kTextPrimaryColor, fontSize: 16),
        bodyMedium: TextStyle(color: kTextSecondaryColor, fontSize: 14),
        bodySmall: TextStyle(color: kTextSecondaryColor, fontSize: 12),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: kCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: Colors.grey[300],
        thickness: 1,
        space: 20,
      ),
    );
  }
}
