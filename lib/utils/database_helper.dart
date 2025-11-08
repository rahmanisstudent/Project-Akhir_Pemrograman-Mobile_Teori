import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/game_model.dart';

class DatabaseHelper {
  // Nama database dan versi
  static const _databaseName = "PixelNomics_v2.db";
  static const _databaseVersion = 7; //ini soalnya perombakan skema DB

  // Nama tabel kita
  static const tableUsers = 'users';
  static const tableGames = 'games';
  static const tableWishlist = 'wishlist';
  static const tableComments = 'comments';

  //nama kolom di user
  static const tableUsersColUsername = 'username';
  static const tableUsersColPassword = 'password';
  static const tableUsersColRole = 'role';
  static const tableUsersColFullName = 'full_name';
  static const tableUsersColPicturePath = 'picture_path';

  //nama kolom di comments
  static const tableCommentsColUserId = 'user_id';
  static const tableCommentsColComment = 'comment_text';
  static const tableCommentsColGameDealID = 'game_dealID';
  static const tableCommentsColTimestamp = 'timestamp';

  //nama kolom di wishlist
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
          password TEXT NOT NULL,
          role TEXT DEFAULT 'user',
          full_name TEXT,
          picture_path TEXT
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

    // 4. Tabel Comment (Gunakan 'IF NOT EXISTS')
    await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableComments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          $tableCommentsColUserId INTEGER NOT NULL,
          $tableCommentsColGameDealID TEXT NOT NULL,
          $tableCommentsColComment TEXT NOT NULL,
          $tableCommentsColTimestamp TEXT,
        FOREIGN KEY ($tableCommentsColUserId) REFERENCES $tableUsers (id),
        FOREIGN KEY ($tableCommentsColGameDealID) REFERENCES $tableGames (dealID)
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

    if (oldVersion < 4) {
      try {
        await db.execute(
          'ALTER TABLE $tableUsers ADD COLUMN role TEXT DEFAULT "user"',
        );
      } catch (e) {
        print("Gagal alter table (mungkin kolom sudah ada): $e");
      }
    }
    // --- TAMBAHKAN LOGIKA BARU INI ---
    if (oldVersion < 5) {
      try {
        await db.execute(
          'ALTER TABLE $tableUsers ADD COLUMN $tableUsersColFullName TEXT',
        );
        await db.execute(
          'ALTER TABLE $tableUsers ADD COLUMN $tableUsersColPicturePath TEXT',
        );
      } catch (e) {
        print("Gagal alter table v5: $e");
      }
    }

    if (oldVersion < 6) {
      try {
        // Hapus tabel feedback lama yang sudah tidak berguna
        await db.execute('DROP TABLE IF EXISTS feedback');
        // Buat tabel comments baru (kita panggil _onCreate)
      } catch (e) {
        print("Gagal drop table v6: $e");
      }
    }

    if (oldVersion < 7) {
      try {
        // Tambahkan kolom 'timestamp' ke tabel 'comments'
        await db.execute(
          'ALTER TABLE $tableComments ADD COLUMN $tableCommentsColTimestamp TEXT',
        );
      } catch (e) {
        print("Gagal alter table v7: $e");
      }
    }

    // Panggil _onCreate lagi untuk membuat ulang tabel yang hilang
    await _onCreate(db, newVersion);
  }

  // tarik data games
  Future<List<Game>> getAllGames() async {
    final db = await instance.database;

    final List<Map<String, dynamic>> maps = await db.query(
      tableGames,
      orderBy: 'title ASC',
    );

    return List.generate(maps.length, (i) {
      return Game.fromMap(maps[i]);
    });
  }

  Future<List<Map<String, dynamic>>> getCommentsForGame(String dealID) async {
    final db = await instance.database;
    return await db.rawQuery(
      '''
    SELECT 
      c.$tableCommentsColComment,
      c.$tableCommentsColTimestamp,
      u.$tableUsersColFullName,
      u.$tableUsersColPicturePath
    FROM $tableComments c
    JOIN $tableUsers u ON c.$tableCommentsColUserId = u.id
    WHERE c.$tableCommentsColGameDealID = ?
    ORDER BY c.id DESC
  ''',
      [dealID],
    );
  }

  // Fungsi untuk menambah komentar baru
  Future<int> addComment(
    int userId,
    String dealID,
    String comment,
    String timestamp,
  ) async {
    final db = await instance.database;
    return await db.insert(tableComments, {
      tableCommentsColUserId: userId,
      tableCommentsColGameDealID: dealID,
      tableCommentsColComment: comment,
      tableCommentsColTimestamp: timestamp,
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

  Future<Map<String, dynamic>?> getUserData(int userId) async {
    final db = await instance.database;
    var res = await db.query(tableUsers, where: 'id = ?', whereArgs: [userId]);
    return res.isNotEmpty ? res.first : null;
  }

  // Meng-update data user
  Future<int> updateUserData(
    int userId,
    String fullName,
    String picturePath,
  ) async {
    final db = await instance.database;
    return await db.update(
      tableUsers,
      {tableUsersColFullName: fullName, tableUsersColPicturePath: picturePath},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> cacheGames(List<Game> games) async {
    final db = await instance.database;

    // Kita gunakan 'batch' agar prosesnya cepat (ribuan data sekaligus)
    var batch = db.batch();

    // 1. Hapus semua data lama dari tabel games
    batch.delete(tableGames);

    // 2. Masukkan semua game baru dari API
    for (var game in games) {
      // 'toMap' adalah fungsi yang kita buat di game_model.dart
      batch.insert(tableGames, game.toMap());
    }

    // 3. Jalankan semua perintah sekaligus
    await batch.commit(noResult: true);
    print("Database game telah di-sync dengan data API.");
  }
}
