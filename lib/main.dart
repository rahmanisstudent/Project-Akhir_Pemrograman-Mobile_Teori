import 'package:flutter/material.dart';
import 'package:pixelnomics_stable/screens/login_screen.dart';
import 'package:pixelnomics_stable/screens/main_screen.dart';
import 'package:pixelnomics_stable/services/auth_service.dart';
import 'package:pixelnomics_stable/services/notification_service.dart';
import 'package:pixelnomics_stable/utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final NotificationService notificationService = NotificationService();
  await notificationService.init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PixelNomics',
      theme: AppTheme.lightTheme,
      home: _buildHomeScreen(),
    );
  }

  Widget _buildHomeScreen() {
    return FutureBuilder<bool>(
      future: _authService.isLoggedIn(),
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
