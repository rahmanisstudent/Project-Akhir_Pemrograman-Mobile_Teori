import 'package:flutter/material.dart';
import 'package:pixelnomics_stable/services/auth_service.dart'; // Sesuaikan nama proyek

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  void _register() async {
    bool success = await _authService.register(
      _usernameController.text,
      _passwordController.text,
    );

    if (success) {
      // Kembali ke layar login setelah berhasil register
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registrasi Berhasil! Silakan Login.')),
      );
      Navigator.pop(context); // Kembali ke layar sebelumnya (Login)
    } else {
      // Tampilkan pesan error (kemungkinan username sudah dipakai)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registrasi Gagal! Username mungkin sudah dipakai.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register Akun')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username Baru'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password Baru'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register, // Panggil fungsi _register
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
