import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shopping_hub/models/product.dart';
import 'package:shopping_hub/providers/wishlist_provider.dart';
import 'package:shopping_hub/services/database_helper.dart';
import 'package:shopping_hub/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDirectory;
  late String databasePath;
  late Database db;
  late DatabaseHelper databaseHelper;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDirectory = await Directory.systemTemp.createTemp('shopping_hub_test_');
    databasePath = p.join(tempDirectory.path, 'shopping_hub.db');
    db = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (database, version) async {
          await database.execute('''
            CREATE TABLE users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT NOT NULL UNIQUE,
              password_hash TEXT NOT NULL,
              salt TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
          await database.execute('''
            CREATE TABLE wishlist (
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
        },
      ),
    );
    databaseHelper = DatabaseHelper.forTest(db);
  });

  tearDown(() async {
    await db.close();
    await tempDirectory.delete(recursive: true);
  });

  test(
    'account and wishlist survive logout and reopening the SQLite database',
    () async {
      final user = await databaseHelper.registerUser('alice', 'secret123');

      expect(user, isNotNull);
      expect(user!.id, isNotNull);
      expect(
        await databaseHelper.authenticateUser('ALICE', 'secret123'),
        isNotNull,
      );
      expect(await databaseHelper.authenticateUser('alice', 'wrong'), isNull);

      final product = Product(
        id: 501,
        title: 'Desk Lamp',
        description: 'A desk lamp.',
        category: 'furniture',
        price: 35,
        thumbnail: 'https://example.com/lamp.jpg',
        brand: 'Studio',
        rating: 4.5,
      );
      await databaseHelper.addToWishlist(user.id!, product);
      await SessionService.saveSession(
        userId: user.id!,
        username: user.username,
      );

      await SessionService.clearSession();
      expect(await SessionService.isLoggedIn(), isFalse);

      await db.close();
      db = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onConfigure: (database) async {
            await database.execute('PRAGMA foreign_keys = ON');
          },
        ),
      );
      databaseHelper = DatabaseHelper.forTest(db);

      final loggedInUser = await databaseHelper.authenticateUser(
        'alice',
        'secret123',
      );
      expect(loggedInUser?.id, user.id);
      await SessionService.saveSession(
        userId: loggedInUser!.id!,
        username: loggedInUser.username,
      );

      final provider = WishlistProvider(dbHelper: databaseHelper);
      await provider.loadWishlist(loggedInUser.id!);
      expect(provider.items.map((item) => item.id), [product.id]);
    },
  );
}
