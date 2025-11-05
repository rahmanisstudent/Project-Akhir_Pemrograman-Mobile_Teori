import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/game_model.dart';

class DatabaseHelper {
  // Nama database dan versi
  static const _databaseName = "PixelNomics_v2.db";
  static const _databaseVersion = 3; //ini soalnya perombakan skema DB

  // Nama tabel kita
  static const tableUsers = 'users';
  static const tableGames = 'games';
  static const tableWishlist = 'wishlist';
  static const tableFeedback = 'feedback';
  static const tableUsersColUsername = 'username';
  static const tableUsersColPassword = 'password';
  static const tableFeedbackColUserId = 'user_id';
  static const tableFeedbackColFeedback = 'kesan_pesan';
  static const tableWishlistColUserId = 'user_id';
  static const tableWishlistColGameDealID = 'game_dealID';

  //singleton
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Koneksi database di aplikasi
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    // Jika database belum ada, panggil initDB untuk buat
    _database = await _initDatabase();
    return _database!;
  }

  // buka/ buat database
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate, // pas buat
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    // 1. Tabel Users (Gunakan 'IF NOT EXISTS')
    await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableUsers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL
        )
        ''');

    // 2. Tabel Games (Gunakan 'IF NOT EXISTS')
    await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableGames (
          id INTEGER PRIMARY KEY AUTOINCREMENT, 
          dealID TEXT NOT NULL UNIQUE,
          title TEXT NOT NULL,
          storeID TEXT,
          salePrice REAL NOT NULL,
          normalPrice REAL NOT NULL,
          thumb TEXT
        )
        ''');

    // 3. PERBAIKI STRUKTUR 'wishlist' (INI YANG BARU)
    await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableWishlist (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          game_dealID TEXT NOT NULL,  -- <-- UBAH DARI game_id MENJADI game_dealID
          FOREIGN KEY (user_id) REFERENCES $tableUsers (id),
          FOREIGN KEY (game_dealID) REFERENCES $tableGames (dealID) -- <-- SAMBUNGKAN KE dealID
        )
        ''');

    // 4. Tabel Feedback (Gunakan 'IF NOT EXISTS')
    await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableFeedback (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          kesan_pesan TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES $tableUsers (id)
        )
        ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Jika upgrade dari v1 (database dummy lama)
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS $tableGames');
      await db.execute('DROP TABLE IF EXISTS $tableWishlist');
    }
    // Jika upgrade dari v2 (struktur wishlist lama)
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS $tableWishlist');
    }

    // Panggil _onCreate lagi untuk membuat ulang tabel yang hilang
    await _onCreate(db, newVersion);
  }

  // tarik data games
  Future<List<Game>> getAllGames() async {
    final db = await instance.database;

    final List<Map<String, dynamic>> maps = await db.query(
      tableGames,
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return Game.fromMap(maps[i]);
    });
  }

  Future<int> addFeedback(String feedbackText, int userId) async {
    final db = await instance.database;
    return await db.insert(tableFeedback, {
      'user_id': userId,
      'kesan_pesan': feedbackText,
    });
  }

  // 1. Fungsi untuk MENAMBAH game ke wishlist
  Future<int> addToWishlist(int userId, String dealID) async {
    final db = await instance.database;
    return await db.insert(tableWishlist, {
      tableWishlistColUserId: userId,
      tableWishlistColGameDealID: dealID,
    });
  }

  // 2. Fungsi untuk MENGHAPUS game dari wishlist
  Future<int> removeFromWishlist(int userId, String dealID) async {
    final db = await instance.database;
    return await db.delete(
      tableWishlist,
      where: '$tableWishlistColUserId = ? AND $tableWishlistColGameDealID = ?',
      whereArgs: [userId, dealID],
    );
  }

  // 3. Fungsi untuk MENGECEK apakah game sudah ada di wishlist
  Future<bool> isGameInWishlist(int userId, String dealID) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableWishlist,
      where: '$tableWishlistColUserId = ? AND $tableWishlistColGameDealID = ?',
      whereArgs: [userId, dealID],
    );
    return maps.isNotEmpty;
  }

  // 4. Fungsi untuk MENDAPATKAN SEMUA game di wishlist pengguna
  Future<List<Game>> getMyWishlist(int userId) async {
    final db = await instance.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
    SELECT g.* FROM $tableGames g
    JOIN $tableWishlist w ON g.id = w.$tableWishlistColGameDealID
    WHERE w.$tableWishlistColUserId = ?
  ''',
      [userId],
    );

    return List.generate(maps.length, (i) {
      return Game.fromMap(maps[i]);
    });
  }
}
