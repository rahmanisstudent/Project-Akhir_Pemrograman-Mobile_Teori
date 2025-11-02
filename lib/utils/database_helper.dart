import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/game_model.dart';

class DatabaseHelper {
  // Nama database dan versi
  static const _databaseName = "PixelNomics_v2.db";
  static const _databaseVersion = 1;

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
  static const tableWishlistColGameId = 'game_id';

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
      onCreate: _onCreate, //cuman dipanggil pas pertama kali buat
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableUsers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL 
          )
          ''');

    await db.execute('''
          CREATE TABLE $tableGames (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            store TEXT NOT NULL,
            price REAL NOT NULL,
            currency_code TEXT NOT NULL,
            image_url TEXT,
            time_zone_offset INTEGER NOT NULL
          )
          ''');

    await db.execute('''
          CREATE TABLE $tableWishlist (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            game_id INTEGER NOT NULL,
            FOREIGN KEY (user_id) REFERENCES $tableUsers (id),
            FOREIGN KEY (game_id) REFERENCES $tableGames (id)
          )
          ''');

    await db.execute('''
          CREATE TABLE $tableFeedback (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            kesan_pesan TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES $tableUsers (id)
          )
          ''');

    await _prepopulateGames(db);
  }

  // dummy data hehe
  Future _prepopulateGames(Database db) async {
    await db.rawInsert('''
      INSERT INTO $tableGames(name, store, price, currency_code, image_url, time_zone_offset)
      VALUES(
        'Elden Ring: Shadow of the Erdtree',
        'Steam',
        39.99,
        'USD',
        'https://image.api.playstation.com/vulcan/ap/rnd/202402/2021/4f2a714659f8139e1a38f32c3f1de8f828a2b53b81102047.png',
        -4 
      )
    ''');

    await db.rawInsert('''
      INSERT INTO $tableGames(name, store, price, currency_code, image_url, time_zone_offset)
      VALUES(
        'Genshin Impact - 60 Crystals',
        'In-Game Store',
        16000.0,
        'IDR',
        'https://upload.wikimedia.org/wikipedia/en/thumb/5/5d/Genshin_Impact_logo.svg/1200px-Genshin_Impact_logo.svg.png',
        8
      )
    ''');

    await db.rawInsert('''
      INSERT INTO $tableGames(name, store, price, currency_code, image_url, time_zone_offset)
      VALUES(
        'Final Fantasy VII Rebirth',
        'PSN Store (Japan)',
        9800.0,
        'JPY',
        'https://image.api.playstation.com/vulcan/ap/rnd/202309/1321/e4f73b84f27f060b2d65017b2b0a9f8f26639a039d6d8498.png',
        9
      )
    ''');
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
  Future<int> addToWishlist(int userId, int gameId) async {
    final db = await instance.database;
    return await db.insert(tableWishlist, {
      tableWishlistColUserId: userId,
      tableWishlistColGameId: gameId,
    });
  }

  // 2. Fungsi untuk MENGHAPUS game dari wishlist
  Future<int> removeFromWishlist(int userId, int gameId) async {
    final db = await instance.database;
    return await db.delete(
      tableWishlist,
      where: '$tableWishlistColUserId = ? AND $tableWishlistColGameId = ?',
      whereArgs: [userId, gameId],
    );
  }

  // 3. Fungsi untuk MENGECEK apakah game sudah ada di wishlist
  Future<bool> isGameInWishlist(int userId, int gameId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableWishlist,
      where: '$tableWishlistColUserId = ? AND $tableWishlistColGameId = ?',
      whereArgs: [userId, gameId],
    );
    return maps.isNotEmpty;
  }

  // 4. Fungsi untuk MENDAPATKAN SEMUA game di wishlist pengguna
  Future<List<Game>> getMyWishlist(int userId) async {
    final db = await instance.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
    SELECT g.* FROM $tableGames g
    JOIN $tableWishlist w ON g.id = w.$tableWishlistColGameId
    WHERE w.$tableWishlistColUserId = ?
  ''',
      [userId],
    );

    return List.generate(maps.length, (i) {
      return Game.fromMap(maps[i]);
    });
  }
}
