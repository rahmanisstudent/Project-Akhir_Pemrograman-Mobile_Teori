// Di file: lib/services/auth_service.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Untuk Session
import '../utils/database_helper.dart';

class AuthService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // --- Fungsi Enkripsi (Hashing) ---
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // --- 1. Fungsi Register ---
  // (Fungsi ini tidak berubah, kita asumsikan 'role' default 'user'
  //  sudah diatur oleh database saat 'CREATE TABLE')
  Future<bool> register(String username, String password) async {
    try {
      final db = await _dbHelper.database;
      String hashedPassword = _hashPassword(password);
      Map<String, dynamic> row = {
        DatabaseHelper.tableUsersColUsername: username,
        DatabaseHelper.tableUsersColPassword: hashedPassword,
        // Kita tidak perlu mengirim 'role', karena DB v4 kita
        // punya 'DEFAULT "user"'
      };
      await db.insert(DatabaseHelper.tableUsers, row);
      return true;
    } catch (e) {
      print("Error_register: $e");
      return false;
    }
  }

  // --- 2. Fungsi Login (ADA PERUBAHAN) ---
  Future<bool> login(String username, String password) async {
    final db = await _dbHelper.database;
    String hashedPassword = _hashPassword(password);

    // Query kita tidak perlu diubah, karena 'db.query'
    // otomatis mengambil SEMUA kolom (*), termasuk 'role'.
    List<Map> result = await db.query(
      DatabaseHelper.tableUsers,
      where:
          '${DatabaseHelper.tableUsersColUsername} = ? AND ${DatabaseHelper.tableUsersColPassword} = ?',
      whereArgs: [username, hashedPassword],
    );

    if (result.isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString(
        'username',
        result.first[DatabaseHelper.tableUsersColUsername],
      );
      await prefs.setInt('user_id', result.first['id']);

      // --- PERUBAHAN 1: SIMPAN ROLE KE SESSION ---
      // Kita ambil data 'role' dari database dan simpan ke session
      await prefs.setString(
        'role',
        result.first[DatabaseHelper.tableUsersColRole],
      );
      // ------------------------------------------

      return true;
    } else {
      return false;
    }
  }

  // --- 3. Fungsi Cek Session (Tidak berubah) ---
  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // --- 4. Fungsi Logout (Tidak berubah) ---
  // 'prefs.clear()' otomatis menghapus 'role'
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // --- 5. Helper (Satu fungsi BARU) ---
  Future<String?> getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  // --- PERUBAHAN 2: FUNGSI BARU UNTUK GET ROLE ---
  Future<String?> getRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Ambil 'role' dari session, jika tidak ada, default-nya 'user'
    return prefs.getString('role') ?? 'user';
  }

  // --------------------------------------------
}
