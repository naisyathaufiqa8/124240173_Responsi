import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/product.dart';
import '../models/user.dart';
import 'db_platform/db_platform.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static Future<Database>? _databaseOpening;

  DatabaseHelper._init();

  // Constructor for testing with an in-memory or injected database
  DatabaseHelper.forTest(Database db) {
    _database = db;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    final opening = _databaseOpening ??= _initDB('shopping_hub.db');
    try {
      _database = await opening;
      return _database!;
    } catch (error, stackTrace) {
      debugPrint('Failed to initialize the local SQLite database: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw const DatabaseInitializationException();
    } finally {
      _databaseOpening = null;
    }
  }

  Future<Database> _initDB(String filePath) async {
    initDatabaseFactory();
    final path = await getDatabasePath(filePath);

    return openDatabase(
      path,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await _createWishlistTable(db, 'wishlist');
    await db.execute('CREATE INDEX wishlist_user_id_idx ON wishlist(user_id)');
  }

  Future<void> _createWishlistTable(Database db, String tableName) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        thumbnail TEXT NOT NULL,
        brand TEXT,
        rating REAL,
        UNIQUE(user_id, product_id),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createWishlistTable(db, 'wishlist_v2');
      await db.execute('''
        INSERT INTO wishlist_v2 (
          id, user_id, product_id, title, category, price, thumbnail, brand, rating
        )
        SELECT id, user_id, product_id, title, category, price, thumbnail, brand, rating
        FROM wishlist
      ''');
      await db.execute('DROP TABLE wishlist');
      await db.execute('ALTER TABLE wishlist_v2 RENAME TO wishlist');
    }
    await db.execute(
      'CREATE INDEX IF NOT EXISTS wishlist_user_id_idx ON wishlist(user_id)',
    );
  }

  // --- PASSWORD SECURITY ---

  static String generateSalt([int length = 16]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // --- USER AUTHENTICATION ---

  Future<User?> registerUser(String username, String password) async {
    final db = await database;
    final cleanUsername = username.trim();

    final existing = await db.query(
      'users',
      where: 'LOWER(username) = ?',
      whereArgs: [cleanUsername.toLowerCase()],
    );

    if (existing.isNotEmpty) {
      return null;
    }

    final salt = generateSalt();
    final hash = hashPassword(password, salt);
    final user = User(
      username: cleanUsername,
      passwordHash: hash,
      salt: salt,
      createdAt: DateTime.now().toIso8601String(),
    );

    final id = await db.insert('users', user.toMap());
    return User(
      id: id,
      username: user.username,
      passwordHash: user.passwordHash,
      salt: user.salt,
      createdAt: user.createdAt,
    );
  }

  Future<User?> authenticateUser(String username, String password) async {
    final db = await database;
    final cleanUsername = username.trim();

    final result = await db.query(
      'users',
      where: 'LOWER(username) = ?',
      whereArgs: [cleanUsername.toLowerCase()],
    );

    if (result.isEmpty) {
      return null;
    }

    final user = User.fromMap(result.first);
    final computedHash = hashPassword(password, user.salt);

    if (computedHash == user.passwordHash) {
      return user;
    }
    return null;
  }

  // --- WISHLIST MANAGEMENT ---

  Future<bool> addToWishlist(int userId, Product product) async {
    final db = await database;
    await db.insert(
      'wishlist',
      product.toDbMap(userId: userId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return true;
  }

  Future<bool> removeFromWishlist(int userId, int productId) async {
    final db = await database;
    final count = await db.delete(
      'wishlist',
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [userId, productId],
    );
    return count > 0;
  }

  Future<List<Product>> getWishlist(int userId) async {
    final db = await database;
    final result = await db.query(
      'wishlist',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return result.map((item) => Product.fromDbMap(item)).toList();
  }

  Future<bool> isProductInWishlist(int userId, int productId) async {
    final db = await database;
    final result = await db.query(
      'wishlist',
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [userId, productId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

class DatabaseInitializationException implements Exception {
  const DatabaseInitializationException();

  @override
  String toString() =>
      'The local SQLite database could not be opened. Refresh the app and try again.';
}
