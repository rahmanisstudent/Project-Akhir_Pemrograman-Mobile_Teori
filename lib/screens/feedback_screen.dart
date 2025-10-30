import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Untuk dapat User ID
import '../utils/database_helper.dart'; // Untuk simpan ke DB

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _feedbackController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AuthService _authService = AuthService();

  void _sendFeedback() async {
    if (_feedbackController.text.isEmpty) return; // Jangan kirim jika kosong

    // 1. Dapatkan User ID yang sedang login dari session
    int? userId = await _authService.getUserId();
    if (userId == null) {
      // Seharusnya tidak mungkin terjadi jika sudah login
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: User tidak ditemukan!')));
      return;
    }

    // 2. Simpan ke database
    await _dbHelper.addFeedback(_feedbackController.text, userId);

    // 3. Beri notifikasi dan kembali
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Terima kasih atas kesan & pesan Anda!')),
    );
    Navigator.pop(context); // Kembali ke halaman profil
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kirim Kesan & Pesan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Kirimkan kesan dan pesan Anda untuk mata kuliah Pemrograman Aplikasi Mobile.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _feedbackController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Tulis di sini...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _sendFeedback, child: Text('Kirim')),
          ],
        ),
      ),
    );
  }
}
