import 'package:flutter/material.dart';
import 'package:pixelnomics_stable/screens/login_screen.dart'; // Sesuaikan 'pixelnomics' dengan nama proyekmu
import 'package:pixelnomics_stable/screens/main_screen.dart'; // Sesuaikan 'pixelnomics' dengan nama proyekmu
import 'package:pixelnomics_stable/services/auth_service.dart'; // Sesuaikan 'pixelnomics' dengan nama proyekmu

void main() {
  // Pastikan semua binding Flutter siap sebelum menjalankan logika
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Buat instance dari AuthService kita
  final AuthService _authService = AuthService();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MurahIn',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light, // Tema gelap ala gamer
      ),
      home: _buildHomeScreen(), // Panggil fungsi untuk cek login
    );
  }

  Widget _buildHomeScreen() {
    // Kita gunakan FutureBuilder untuk menunggu hasil pengecekan session
    return FutureBuilder<bool>(
      // Panggil fungsi isLoggedIn() dari AuthService
      future: _authService.isLoggedIn(),
      builder: (context, snapshot) {
        // Saat sedang loading...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Jika sudah ada data dan hasilnya 'true' (sudah login)
        if (snapshot.hasData && snapshot.data == true) {
          // Arahkan ke Layar Utama
          return MainScreen();
        }

        // Jika tidak, arahkan ke Layar Login
        return LoginScreen();
      },
    );
  }
}
