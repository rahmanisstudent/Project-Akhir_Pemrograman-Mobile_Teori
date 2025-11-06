import 'package:flutter/material.dart';

// Ini adalah skema warna "Cyberpunk / Gamer" yang kita pilih
// Aksen utama: Teal/Aqua
// Latar belakang: Sangat gelap
const Color kPrimaryColor = Color(0xFF00BFFF); // DeepSkyBlue / Aksen cerah
const Color kAccentColor = Color(0xFF00E5FF); // Aqua / Neon
const Color kBackgroundColor = Color(
  0xFF121212,
); // Latar belakang gelap (bukan hitam pekat)
const Color kCardColor = Color(
  0xFF1E1E1E,
); // Warna kartu (sedikit lebih terang)
const Color kSuccessColor = Colors.greenAccent; // Untuk harga diskon
const Color kErrorColor = Colors.pinkAccent; // Untuk error / wishlist

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      // === Warna Utama ===
      brightness: Brightness.dark,
      primaryColor: kPrimaryColor,
      scaffoldBackgroundColor: kBackgroundColor,
      cardColor: kCardColor,

      // Definisikan ColorScheme untuk konsistensi
      colorScheme: ColorScheme.dark(
        primary: kPrimaryColor,
        secondary: kAccentColor,
        background: kBackgroundColor,
        surface: kCardColor, // Warna Card, Dialog, BottomSheet
        onPrimary: Colors.black, // Teks di atas Primary
        onSecondary: Colors.black, // Teks di atas Secondary
        onBackground: Colors.white, // Teks di atas Background
        onSurface: Colors.white, // Teks di atas Card/Surface
        error: kErrorColor,
        onError: Colors.black,
        brightness: Brightness.dark,
        surfaceVariant: kCardColor, // Atur surfaceVariant ke kCardColor
        onSurfaceVariant: Colors.white, // Atur onSurfaceVariant ke white
      ),

      // === Tema AppBar ===
      appBarTheme: AppBarTheme(
        color: kCardColor, // AppBar pakai warna kartu (bukan hitam)
        elevation: 2,
        titleTextStyle: TextStyle(
          color: kPrimaryColor, // Judul AppBar pakai warna aksen
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(
          color: kPrimaryColor, // Tombol back, dll.
        ),
      ),

      // === Tema Tombol ===
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor, // Latar tombol
          foregroundColor: Colors.black, // Teks tombol
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),

      // === Tema Bottom Navigation Bar ===
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: kCardColor,
        selectedItemColor: kAccentColor, // Ikon yang aktif
        unselectedItemColor: Colors.grey[600], // Ikon yang tidak aktif
        showUnselectedLabels: false,
      ),

      // === Tema Input Field (Search, Komen) ===
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black.withOpacity(0.3), // Latar field lebih gelap
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none, // Hilangkan border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
            color: kAccentColor,
            width: 2,
          ), // Border neon saat aktif
        ),
        labelStyle: TextStyle(color: Colors.grey[400]),
        hintStyle: TextStyle(color: Colors.grey[600]),
      ),

      // === Tema Card (di GamesTab) ===
      cardTheme: CardThemeData(
        elevation: 2,
        color: kCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),

      // === Tema Chip (Filter) ===
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[800],
        selectedColor: kAccentColor,
        labelStyle: TextStyle(color: Colors.white),
        secondaryLabelStyle: TextStyle(
          color: Colors.black,
        ), // Teks saat chip dipilih
        padding: const EdgeInsets.all(8.0),
      ),

      // === Tema Text (Font) ===
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          color: kPrimaryColor,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(color: kPrimaryColor),
        titleMedium: TextStyle(color: Colors.white.withOpacity(0.8)),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white.withOpacity(0.7)),
      ),

      // Atur warna aksen harga diskon
      textSelectionTheme: TextSelectionThemeData(cursorColor: kAccentColor),
    );
  }
}
