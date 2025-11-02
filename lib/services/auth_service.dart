import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Untuk Session
import '../utils/database_helper.dart';

class AuthService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // --- Fungsi Enkripsi (Hashing) ---
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes); //hashing menggunakan algoritma SHA-256
    return digest.toString();
  }

  // --- 1. Fungsi Register ---
  Future<bool> register(String username, String password) async {
    try {
      final db = await _dbHelper.database;

      // di lempar ke _hasPassword tuk di enkripsi
      String hashedPassword = _hashPassword(password);

      Map<String, dynamic> row = {
        DatabaseHelper.tableUsersColUsername: username,
        DatabaseHelper.tableUsersColPassword: hashedPassword,
      };

      await db.insert(DatabaseHelper.tableUsers, row);

      return true;
      // Error handling
    } catch (e) {
      print(
        "Error_register: $e",
      ); //kemungkinan usn-nya sama, disetting sengaja UNIQUE
      return false;
    }
  }

  // --- 2. Fungsi Login ---
  Future<bool> login(String username, String password) async {
    final db = await _dbHelper.database;

    // dienkripsi juga karena di db disimpan dalam enkripsi
    String hashedPassword = _hashPassword(password);

    List<Map> result = await db.query(
      DatabaseHelper.tableUsers,
      where:
          '${DatabaseHelper.tableUsersColUsername} = ? AND ${DatabaseHelper.tableUsersColPassword} = ?',
      whereArgs: [username, hashedPassword],
    );

    // Cek hasil dari matching di atas
    if (result.isNotEmpty) {
      // Login aktif, disimpan ke sessions
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('username', username);
      await prefs.setInt('user_id', result.first['id']);

      return true;
    } else {
      return false;
    }
  }

  // --- 3. Fungsi Cek Session ---
  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
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
