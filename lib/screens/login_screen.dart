import 'package:flutter/material.dart';
import 'package:pixelnomics_stable/screens/main_screen.dart'; // Sesuaikan nama proyek
import 'package:pixelnomics_stable/screens/register_screen.dart'; // Sesuaikan nama proyek
import 'package:pixelnomics_stable/services/auth_service.dart'; // Sesuaikan nama proyek

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
    bool success = await _authService.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (success) {
      // Pindah ke MainScreen dan HAPUS layar login dari tumpukan
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } else {
      // Tampilkan pesan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login Gagal! Username atau Password salah.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login PixelNomics')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true, // Sembunyikan password
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login, // Panggil fungsi _login
              child: Text('Login'),
            ),
            TextButton(
              onPressed: () {
                // Pindah ke RegisterScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );
              },
              child: Text('Belum punya akun? Register di sini'),
            ),
          ],
        ),
      ),
    );
  }
}
