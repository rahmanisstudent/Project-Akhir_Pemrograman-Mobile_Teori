import 'dart:convert'; // Untuk utf8
import 'package:crypto/crypto.dart'; // Untuk sha256 (Enkripsi)
import 'package:shared_preferences/shared_preferences.dart'; // Untuk Session
import '../utils/database_helper.dart'; // Penghubung ke database kita

class AuthService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // --- Fungsi Enkripsi (Hashing) ---
  String _hashPassword(String password) {
    // Mengubah password (String) menjadi bytes
    var bytes = utf8.encode(password);
    // Melakukan hashing menggunakan algoritma SHA-256
    var digest = sha256.convert(bytes);
    // Mengembalikan hasil hash sebagai String
    return digest.toString();
  }

  // --- 1. Fungsi Register ---
  Future<bool> register(String username, String password) async {
    try {
      final db = await _dbHelper.database;

      // Enkripsi password sebelum disimpan
      String hashedPassword = _hashPassword(password);

      // Siapkan data untuk dimasukkan ke tabel 'users'
      Map<String, dynamic> row = {
        DatabaseHelper.tableUsersColUsername: username,
        DatabaseHelper.tableUsersColPassword:
            hashedPassword, // Simpan password yg sudah di-hash
      };

      // Masukkan data ke database
      await db.insert(DatabaseHelper.tableUsers, row);

      // Jika berhasil, kembalikan true
      return true;
    } catch (e) {
      // Ini kemungkinan gagal karena 'username' sudah ada (UNIQUE constraint)
      print("Error_register: $e");
      return false;
    }
  }

  // --- 2. Fungsi Login ---
  Future<bool> login(String username, String password) async {
    final db = await _dbHelper.database;

    // Enkripsi password yang diinput pengguna untuk dicocokkan
    String hashedPassword = _hashPassword(password);

    // Cari di database
    List<Map> result = await db.query(
      DatabaseHelper.tableUsers,
      where:
          '${DatabaseHelper.tableUsersColUsername} = ? AND ${DatabaseHelper.tableUsersColPassword} = ?',
      whereArgs: [username, hashedPassword],
    );

    // Cek apakah user ditemukan (hasilnya 1 baris)
    if (result.isNotEmpty) {
      // --- Ini adalah Bagian "SESSION" ---
      // Jika login berhasil, simpan data ke SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('username', username);
      // Ambil user_id dari hasil query database
      await prefs.setInt('user_id', result.first['id']);

      return true;
    } else {
      // Login gagal (username atau password salah)
      return false;
    }
  }

  // --- 3. Fungsi Cek Session ---
  // (Untuk mengecek saat aplikasi pertama dibuka)
  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Cek nilai 'isLoggedIn'. Jika tidak ada, kembalikan false
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // --- 4. Fungsi Logout ---
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Hapus semua data session
    await prefs.clear();
  }

  // --- Helper (Opsional tapi bagus) ---
  Future<String?> getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }
}

// Tambahkan ini di file database_helper.dart agar lebih rapi
// Buka file lib/utils/database_helper.dart
// Ubah definisi tabel 'users' di atas _initDatabase()
/*
  // ...
  static const tableUsers = 'users';
  // Tambahkan 2 baris ini
  static const tableUsersColUsername = 'username';
  static const tableUsersColPassword = 'password';

  static const tableGames = 'games';
  // ...
*/
