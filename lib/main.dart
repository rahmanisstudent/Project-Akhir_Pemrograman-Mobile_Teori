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
      title: 'PixelNomics',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light, //theme
      ),
      home: _buildHomeScreen(),
    );
  }

  Widget _buildHomeScreen() {
    return FutureBuilder<bool>(
      future: _authService.isLoggedIn(), //authservice
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // login berhasil ada datanya
        if (snapshot.hasData && snapshot.data == true) {
          // Arahkan ke Layar Utama
          return MainScreen();
        }

        return LoginScreen();
      },
    );
  }
}
