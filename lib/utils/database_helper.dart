import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/game_model.dart';

class DatabaseHelper {
  static const _databaseName = "PixelNomics_v2.db";
  static const _databaseVersion = 8; // Update versi untuk currency

  // Nama tabel
  static const tableUsers = 'users';
  static const tableGames = 'games';
  static const tableWishlist = 'wishlist';
  static const tableComments = 'comments';

  // Kolom tabel users
  static const tableUsersColUsername = 'username';
  static const tableUsersColPassword = 'password';
  static const tableUsersColRole = 'role';
  static const tableUsersColFullName = 'full_name';
  static const tableUsersColPicturePath = 'picture_path';
  static const tableUsersColPreferredCurrency = 'preferred_currency';

  // Kolom tabel comments
  static const tableCommentsColUserId = 'user_id';
  static const tableCommentsColComment = 'comment_text';
  static const tableCommentsColGameDealID = 'game_dealID';
  static const tableCommentsColTimestamp = 'timestamp';

  // Kolom tabel wishlist
  static const tableWishlistColUserId = 'user_id';
  static const tableWishlistColGameDealID = 'game_dealID';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableUsers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          $tableUsersColUsername TEXT NOT NULL UNIQUE,
          $tableUsersColPassword TEXT NOT NULL,
          $tableUsersColRole TEXT DEFAULT 'user',
          $tableUsersColFullName TEXT,
          $tableUsersColPicturePath TEXT,
          $tableUsersColPreferredCurrency TEXT DEFAULT 'IDR'
        )
        ''');

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

    await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableWishlist (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          $tableWishlistColUserId INTEGER NOT NULL,
          $tableWishlistColGameDealID TEXT NOT NULL,
          FOREIGN KEY ($tableWishlistColUserId) REFERENCES $tableUsers (id),
          FOREIGN KEY ($tableWishlistColGameDealID) REFERENCES $tableGames (dealID)
        )
        ''');

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
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS $tableGames');
      await db.execute('DROP TABLE IF EXISTS $tableWishlist');
    }
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS $tableWishlist');
    }

    if (oldVersion < 4) {
      try {
        await db.execute(
          'ALTER TABLE $tableUsers ADD COLUMN $tableUsersColRole TEXT DEFAULT "user"',
        );
      } catch (e) {
        print("Gagal alter table (mungkin kolom sudah ada): $e");
      }
    }
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
        await db.execute('DROP TABLE IF EXISTS feedback');
      } catch (e) {
        print("Gagal drop table v6: $e");
      }
    }

    if (oldVersion < 7) {
      try {
        await db.execute(
          'ALTER TABLE $tableComments ADD COLUMN $tableCommentsColTimestamp TEXT',
        );
      } catch (e) {
        print("Gagal alter table v7: $e");
      }
    }

    if (oldVersion < 8) {
      try {
        await db.execute(
          'ALTER TABLE $tableUsers ADD COLUMN $tableUsersColPreferredCurrency TEXT DEFAULT "IDR"',
        );
      } catch (e) {
        print("Gagal alter table v8: $e");
      }
    }

    await _onCreate(db, newVersion);
  }

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

  Future<int> addToWishlist(int userId, String dealID) async {
    final db = await instance.database;
    return await db.insert(tableWishlist, {
      tableWishlistColUserId: userId,
      tableWishlistColGameDealID: dealID,
    });
  }

  Future<int> removeFromWishlist(int userId, String dealID) async {
    final db = await instance.database;
    return await db.delete(
      tableWishlist,
      where: '$tableWishlistColUserId = ? AND $tableWishlistColGameDealID = ?',
      whereArgs: [userId, dealID],
    );
  }

  Future<bool> isGameInWishlist(int userId, String dealID) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableWishlist,
      where: '$tableWishlistColUserId = ? AND $tableWishlistColGameDealID = ?',
      whereArgs: [userId, dealID],
    );
    return maps.isNotEmpty;
  }

  Future<List<Game>> getMyWishlist(int userId) async {
    final db = await instance.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
    SELECT g.* FROM $tableGames g
    JOIN $tableWishlist w ON g.dealID = w.$tableWishlistColGameDealID
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

  Future<int> updateUserData(
    int userId,
    String fullName,
    String picturePath,
    String preferredCurrency,
  ) async {
    final db = await instance.database;
    return await db.update(
      tableUsers,
      {
        tableUsersColFullName: fullName,
        tableUsersColPicturePath: picturePath,
        tableUsersColPreferredCurrency: preferredCurrency,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> cacheGames(List<Game> games) async {
    final db = await instance.database;

    var batch = db.batch();

    batch.delete(tableGames);

    for (var game in games) {
      batch.insert(tableGames, game.toMap());
    }

    await batch.commit(noResult: true);
    print("Database game telah di-sync dengan data API.");
  }
}
