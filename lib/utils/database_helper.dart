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
  static const tableUsersColUsername = 'username';
  static const tableUsersColPassword = 'password';
  static const tableFeedbackColUserId = 'user_id';
  static const tableFeedbackColFeedback = 'kesan_pesan';
  static const tableGames = 'games';
  static const tableWishlist = 'wishlist';
  static const tableWishlistColUserId = 'user_id';
  static const tableWishlistColGameId = 'game_id';
  static const tableFeedback = 'feedback';

  // Membuat class ini menjadi Singleton
  // Ini memastikan kita hanya punya SATU koneksi database di seluruh aplikasi
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Hanya ada satu koneksi database di aplikasi
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    // Jika database belum ada, panggil initDB untuk membuatnya
    _database = await _initDatabase();
    return _database!;
  }

  // Fungsi ini membuka database (atau membuatnya jika belum ada)
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    ); // Panggil _onCreate saat DB dibuat pertama kali
  }

  // Perintah SQL untuk MEMBUAT tabel.
  // Ini hanya berjalan SATU KALI saat aplikasi di-install pertama kali
  Future _onCreate(Database db, int version) async {
    // 1. Membuat tabel Users
    await db.execute('''
          CREATE TABLE $tableUsers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL 
          )
          ''');

    // 2. Membuat tabel Games
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

    // 3. Membuat tabel Wishlist (penghubung users dan games)
    await db.execute('''
          CREATE TABLE $tableWishlist (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            game_id INTEGER NOT NULL,
            FOREIGN KEY (user_id) REFERENCES $tableUsers (id),
            FOREIGN KEY (game_id) REFERENCES $tableGames (id)
          )
          ''');

    // 4. Membuat tabel Feedback
    await db.execute('''
          CREATE TABLE $tableFeedback (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            kesan_pesan TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES $tableUsers (id)
          )
          ''');

    // PENTING: Langsung isi tabel games dengan data dummy kita!
    await _prepopulateGames(db);
  }

  // Fungsi untuk mengisi data dummy (Metode Hybrid kita)
  Future _prepopulateGames(Database db) async {
    // Data 1 (Luar Negeri - USD)
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
    '''); // -4 (Misal: EST, Waktu Developer)

    // Data 2 (Lokal - IDR)
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
    '''); // +8 (Misal: Waktu Server Asia)

    // Data 3 (Luar Negeri - JPY)
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
    '''); // +9 (Waktu Standar Jepang)
  }

  // Fungsi untuk MENGAMBIL SEMUA GAMES dari tabel games
  Future<List<Game>> getAllGames() async {
    final db = await instance.database;

    // Query ke tabel 'games', urutkan berdasarkan nama
    final List<Map<String, dynamic>> maps = await db.query(
      tableGames,
      orderBy: 'name ASC',
    );

    // Ubah List<Map> menjadi List<Game> menggunakan model kita
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
    return maps.isNotEmpty; // Jika list tidak kosong, berarti game sudah ada
  }

  // 4. Fungsi untuk MENDAPATKAN SEMUA game di wishlist pengguna
  // (Kita gunakan SQL JOIN di sini untuk menggabungkan tabel 'wishlist' dan 'games')
  Future<List<Game>> getMyWishlist(int userId) async {
    final db = await instance.database;

    // Ini adalah query SQL yang canggih:
    // "PILIH semua kolom dari tabel 'games' (g)
    //  DI MANA id-nya ada di tabel 'wishlist' (w)
    //  DAN user_id di 'wishlist' adalah [userId]"
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
    SELECT g.* FROM $tableGames g
    JOIN $tableWishlist w ON g.id = w.$tableWishlistColGameId
    WHERE w.$tableWishlistColUserId = ?
  ''',
      [userId],
    );

    // Ubah List<Map> menjadi List<Game>
    return List.generate(maps.length, (i) {
      return Game.fromMap(maps[i]);
    });
  }

  // (Nanti kita akan tambahkan fungsi INSERT, QUERY, DELETE di sini)
  // (Contoh: Future<int> registerUser(Map<String, dynamic> row) async { ... })
}
