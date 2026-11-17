import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_hub/models/product.dart';

void main() {
  group('Product Model Tests', () {
    test('Correctly parses full JSON from DummyJSON', () {
      final json = {
        'id': 1,
        'title': 'Essence Mascara Lash Princess',
        'description': 'The Essence Mascara Lash Princess is a popular mascara.',
        'category': 'beauty',
        'price': 9.99,
        'discountPercentage': 7.17,
        'rating': 4.94,
        'stock': 5,
        'brand': 'Essence',
        'thumbnail': 'https://cdn.dummyjson.com/products/images/beauty/1/thumbnail.png',
        'images': [
          'https://cdn.dummyjson.com/products/images/beauty/1/1.png',
        ],
      };

      final product = Product.fromJson(json);

      expect(product.id, 1);
      expect(product.title, 'Essence Mascara Lash Princess');
      expect(product.category, 'beauty');
      expect(product.price, 9.99);
      expect(product.discountPercentage, 7.17);
      expect(product.rating, 4.94);
      expect(product.stock, 5);
      expect(product.brand, 'Essence');
      expect(product.thumbnail, 'https://cdn.dummyjson.com/products/images/beauty/1/thumbnail.png');
      expect(product.images.length, 1);
    });

    test('Safely handles missing or null fields', () {
      final json = {
        'id': 42,
        'title': null,
        'description': null,
        'category': null,
        'price': '19.5', // String instead of num
        'discountPercentage': null,
        'rating': null,
        'stock': null,
        'brand': null,
        'thumbnail': null,
        'images': null,
      };

      final product = Product.fromJson(json);

      expect(product.id, 42);
      expect(product.title, 'Unnamed Product');
      expect(product.category, 'General');
      expect(product.price, 19.5);
      expect(product.discountPercentage, 0.0);
      expect(product.rating, 0.0);
      expect(product.stock, 0);
      expect(product.brand, '');
      expect(product.thumbnail, '');
      expect(product.images, isEmpty);
    });

    test('Falls back thumbnail to first image if thumbnail is missing', () {
      final json = {
        'id': 5,
        'title': 'Sample Product',
        'thumbnail': '',
        'images': ['https://example.com/first.png', 'https://example.com/second.png'],
      };

      final product = Product.fromJson(json);
      expect(product.thumbnail, 'https://example.com/first.png');
    });

    test('Converts to and from SQLite DB Map', () {
      final product = Product(
        id: 99,
        title: 'Database Item',
        description: 'Test Description',
        category: 'electronics',
        price: 299.99,
        thumbnail: 'https://example.com/item.png',
        brand: 'TechBrand',
        rating: 4.8,
      );

      final dbMap = product.toDbMap(userId: 1);

      expect(dbMap['user_id'], 1);
      expect(dbMap['product_id'], 99);
      expect(dbMap['title'], 'Database Item');
      expect(dbMap['price'], 299.99);

      final reconstructed = Product.fromDbMap(dbMap);
      expect(reconstructed.id, 99);
      expect(reconstructed.title, 'Database Item');
      expect(reconstructed.category, 'electronics');
      expect(reconstructed.price, 299.99);
      expect(reconstructed.brand, 'TechBrand');
      expect(reconstructed.rating, 4.8);
    });
  });
}
