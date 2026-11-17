import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shopping_hub/services/api_service.dart';

void main() {
  group('ApiService Tests with Mock HTTP Client', () {
    test('getProducts successfully fetches and parses list of products', () async {
      final mockResponse = {
        'products': [
          {
            'id': 1,
            'title': 'iPhone 15 Pro',
            'description': 'Flagship phone',
            'category': 'smartphones',
            'price': 999.99,
            'thumbnail': 'https://example.com/phone.jpg',
            'images': ['https://example.com/phone.jpg'],
          },
          {
            'id': 2,
            'title': 'MacBook Pro',
            'description': 'Powerful laptop',
            'category': 'laptops',
            'price': 1999.00,
            'thumbnail': 'https://example.com/macbook.jpg',
            'images': ['https://example.com/macbook.jpg'],
          },
        ],
        'total': 2,
        'skip': 0,
        'limit': 30,
      };

      final client = MockClient((request) async {
        expect(request.url.path, '/products');
        expect(request.url.queryParameters['limit'], '30');
        return http.Response(json.encode(mockResponse), 200, headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
        });
      });

      final apiService = ApiService(client: client);
      final products = await apiService.getProducts(limit: 30);

      expect(products.length, 2);
      expect(products[0].id, 1);
      expect(products[0].title, 'iPhone 15 Pro');
      expect(products[0].price, 999.99);
      expect(products[1].id, 2);
      expect(products[1].title, 'MacBook Pro');
    });

    test('getProductDetail successfully fetches single product', () async {
      final mockProduct = {
        'id': 10,
        'title': 'Mechanical Keyboard',
        'description': 'RGB mechanical keyboard',
        'category': 'accessories',
        'price': 89.50,
        'discountPercentage': 15.0,
        'rating': 4.7,
        'stock': 25,
        'brand': 'KeyCraft',
        'thumbnail': 'https://example.com/kb.jpg',
        'images': [
          'https://example.com/kb1.jpg',
          'https://example.com/kb2.jpg',
        ],
      };

      final client = MockClient((request) async {
        expect(request.url.path, '/products/10');
        return http.Response(json.encode(mockProduct), 200, headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
        });
      });

      final apiService = ApiService(client: client);
      final product = await apiService.getProductDetail(10);

      expect(product.id, 10);
      expect(product.title, 'Mechanical Keyboard');
      expect(product.discountPercentage, 15.0);
      expect(product.stock, 25);
      expect(product.brand, 'KeyCraft');
      expect(product.images.length, 2);
    });

    test('getCategories fetches category list correctly', () async {
      final mockCategories = ['beauty', 'fragrances', 'furniture', 'groceries'];

      final client = MockClient((request) async {
        expect(request.url.path, '/products/category-list');
        return http.Response(json.encode(mockCategories), 200, headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
        });
      });

      final apiService = ApiService(client: client);
      final categories = await apiService.getCategories();

      expect(categories.length, 4);
      expect(categories, contains('beauty'));
      expect(categories, contains('furniture'));
    });

    test('getProductsByCategory correctly encodes category and returns products', () async {
      final mockResponse = {
        'products': [
          {
            'id': 33,
            'title': 'Sofa Bed',
            'description': 'Comfortable sofa bed',
            'category': 'home-decoration',
            'price': 350.0,
            'thumbnail': 'https://example.com/sofa.jpg',
          }
        ]
      };

      final client = MockClient((request) async {
        expect(request.url.path, '/products/category/home-decoration');
        return http.Response(json.encode(mockResponse), 200, headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
        });
      });

      final apiService = ApiService(client: client);
      final products = await apiService.getProductsByCategory('home-decoration');

      expect(products.length, 1);
      expect(products.first.id, 33);
      expect(products.first.category, 'home-decoration');
    });

    test('Throws exception on HTTP error status code', () async {
      final client = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: client);
      expect(() => apiService.getProducts(), throwsA(isA<Exception>()));
    });
  });
}
