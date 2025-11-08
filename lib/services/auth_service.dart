import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/database_helper.dart';

class AuthService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> register(String username, String password) async {
    try {
      final db = await _dbHelper.database;
      String hashedPassword = _hashPassword(password);
      Map<String, dynamic> row = {
        DatabaseHelper.tableUsersColUsername: username,
        DatabaseHelper.tableUsersColPassword: hashedPassword,
      };
      await db.insert(DatabaseHelper.tableUsers, row);
      return true;
    } catch (e) {
      print("Error_register: $e");
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    final db = await _dbHelper.database;
    String hashedPassword = _hashPassword(password);

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
      await prefs.setString(
        'role',
        result.first[DatabaseHelper.tableUsersColRole],
      );
      return true;
    } else {
      return false;
    }
  }

  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<String?> getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  Future<String?> getRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('role') ?? 'user';
  }
}
