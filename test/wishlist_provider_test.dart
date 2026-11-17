import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shopping_hub/models/product.dart';
import 'package:shopping_hub/providers/wishlist_provider.dart';
import 'package:shopping_hub/services/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late DatabaseHelper dbHelper;
  late WishlistProvider provider;

  final sampleProduct1 = Product(
    id: 101,
    title: 'Minimalist Lamp',
    description: 'A stylish table lamp.',
    category: 'furniture',
    price: 49.99,
    thumbnail: 'https://example.com/lamp.jpg',
    brand: 'Studio Sage',
    rating: 4.8,
  );

  final sampleProduct2 = Product(
    id: 102,
    title: 'Ceramic Vase',
    description: 'Handmade ceramic vase.',
    category: 'home-decoration',
    price: 24.50,
    thumbnail: 'https://example.com/vase.jpg',
    brand: 'ClayCo',
    rating: 4.6,
  );

  setUp(() async {
    // Open fresh in-memory database for each test
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
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
    await db.execute('PRAGMA foreign_keys = ON');
    await db.insert('users', {
      'id': 1,
      'username': 'user1',
      'password_hash': 'hash1',
      'salt': 'salt1',
      'created_at': DateTime.now().toIso8601String(),
    });
    await db.insert('users', {
      'id': 2,
      'username': 'user2',
      'password_hash': 'hash2',
      'salt': 'salt2',
      'created_at': DateTime.now().toIso8601String(),
    });

    dbHelper = DatabaseHelper.forTest(db);
    provider = WishlistProvider(dbHelper: dbHelper);
  });

  tearDown(() async {
    await db.close();
  });

  group('WishlistProvider & SQLite Integration Tests', () {
    test('Initial state is empty', () {
      expect(provider.itemCount, 0);
      expect(provider.items, isEmpty);
      expect(provider.isInWishlist(101), isFalse);
    });

    test(
      'Add item to wishlist persists in DB and updates memory state',
      () async {
        await provider.loadWishlist(1); // User 1

        final result = await provider.toggleWishlist(sampleProduct1);
        expect(result, isTrue); // Added
        expect(provider.isInWishlist(101), isTrue);
        expect(provider.itemCount, 1);
        expect(provider.items.first.title, 'Minimalist Lamp');

        // Verify directly in SQLite DB
        final dbItems = await dbHelper.getWishlist(1);
        expect(dbItems.length, 1);
        expect(dbItems.first.id, 101);
      },
    );

    test(
      'Toggle existing item removes it from DB and updates memory state',
      () async {
        await provider.loadWishlist(1);

        // Add item
        await provider.toggleWishlist(sampleProduct1);
        expect(provider.isInWishlist(101), isTrue);

        // Toggle again to remove
        final removeResult = await provider.toggleWishlist(sampleProduct1);
        expect(removeResult, isFalse); // Removed
        expect(provider.isInWishlist(101), isFalse);
        expect(provider.itemCount, 0);

        // Verify DB is empty for user 1
        final dbItems = await dbHelper.getWishlist(1);
        expect(dbItems, isEmpty);
      },
    );

    test('removeItem explicitly removes item', () async {
      await provider.loadWishlist(1);
      await provider.toggleWishlist(sampleProduct1);
      await provider.toggleWishlist(sampleProduct2);
      expect(provider.itemCount, 2);

      final removed = await provider.removeItem(101);
      expect(removed, isTrue);
      expect(provider.isInWishlist(101), isFalse);
      expect(provider.isInWishlist(102), isTrue);
      expect(provider.itemCount, 1);
    });

    test('Wishlist is strictly isolated between different users', () async {
      // User 1 adds product 1
      await provider.loadWishlist(1);
      await provider.toggleWishlist(sampleProduct1);
      expect(provider.isInWishlist(101), isTrue);

      // Switch to User 2
      final providerUser2 = WishlistProvider(dbHelper: dbHelper);
      await providerUser2.loadWishlist(2);
      expect(providerUser2.isInWishlist(101), isFalse);
      expect(providerUser2.itemCount, 0);

      // User 2 adds product 2
      await providerUser2.toggleWishlist(sampleProduct2);
      expect(providerUser2.isInWishlist(102), isTrue);

      // Check DB directly
      final user1Db = await dbHelper.getWishlist(1);
      final user2Db = await dbHelper.getWishlist(2);

      expect(user1Db.length, 1);
      expect(user1Db.first.id, 101);
      expect(user2Db.length, 1);
      expect(user2Db.first.id, 102);
    });

    test('clear() resets memory state on logout', () async {
      await provider.loadWishlist(1);
      await provider.toggleWishlist(sampleProduct1);
      expect(provider.itemCount, 1);

      provider.clear();
      expect(provider.itemCount, 0);
      expect(provider.currentUserId, isNull);
    });
  });
}
