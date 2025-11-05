// Di file: lib/screens/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:pixelnomics_stable/services/auth_service.dart';
import 'package:pixelnomics_stable/utils/database_helper.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final _authService = AuthService();

  final _fullNameController = TextEditingController();
  final _picturePathController = TextEditingController();

  int? _currentUserId;
  bool _isLoading = true; // Untuk loading awal

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Ambil data user saat ini dari DB
  Future<void> _loadUserData() async {
    _currentUserId = await _authService.getUserId();
    if (_currentUserId != null) {
      final userData = await _dbHelper.getUserData(_currentUserId!);
      if (userData != null) {
        setState(() {
          // Isi TextField dengan data dari DB (jika ada)
          _fullNameController.text =
              userData[DatabaseHelper.tableUsersColFullName] ?? '';
          _picturePathController.text =
              userData[DatabaseHelper.tableUsersColPicturePath] ?? '';
        });
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  // Simpan perubahan ke DB
  Future<void> _saveProfile() async {
    if (_currentUserId == null) return;

    await _dbHelper.updateUserData(
      _currentUserId!,
      _fullNameController.text,
      _picturePathController.text,
    );

    // Tampilkan notifikasi
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Profil berhasil diperbarui!')));
    Navigator.pop(context); // Kembali ke Tab Profil
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Profil')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _fullNameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _picturePathController,
                    decoration: InputDecoration(
                      labelText: 'URL Gambar Profil (Contoh: http://...)',
                      helperText:
                          'Nanti kita akan ganti ini dengan image picker',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    child: Text('Simpan Perubahan'),
                  ),
                ],
              ),
            ),
    );
  }
}
