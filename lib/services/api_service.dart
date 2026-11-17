import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  static const String baseUrl = 'https://dummyjson.com';
  static const Duration timeoutDuration = Duration(seconds: 12);

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Product>> getProducts({int limit = 30}) async {
    final uri = Uri.parse('$baseUrl/products?limit=$limit');
    try {
      final response = await _client.get(uri).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> productsJson = data['products'] as List<dynamic>? ?? [];
        return productsJson.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw HttpException('Failed to load products (HTTP ${response.statusCode})');
      }
    } on SocketException {
      throw const SocketException('No Internet connection. Please check your network.');
    } on TimeoutException {
      throw TimeoutException('Connection timed out. Please try again.');
    }
  }

 
  Future<Product> getProductDetail(int id) async {
    final uri = Uri.parse('$baseUrl/products/$id');
    try {
      final response = await _client.get(uri).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Product.fromJson(data);
      } else {
        throw HttpException('Failed to load product detail (HTTP ${response.statusCode})');
      }
    } on SocketException {
      throw const SocketException('No Internet connection. Please check your network.');
    } on TimeoutException {
      throw TimeoutException('Connection timed out. Please try again.');
    }
  }


  Future<List<String>> getCategories() async {
    final uri = Uri.parse('$baseUrl/products/category-list');
    try {
      final response = await _client.get(uri).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is List) {
          return data.map((item) {
            if (item is String) {
              return item;
            } else if (item is Map && item.containsKey('slug')) {
              return item['slug'].toString();
            } else if (item is Map && item.containsKey('name')) {
              return item['name'].toString();
            }
            return item.toString();
          }).toList();
        }
        return [];
      } else {
        throw HttpException('Failed to load categories (HTTP ${response.statusCode})');
      }
    } on SocketException {
      throw const SocketException('No Internet connection. Please check your network.');
    } on TimeoutException {
      throw TimeoutException('Connection timed out. Please try again.');
    }
  }

  
  Future<List<Product>> getProductsByCategory(String category) async {
    final encodedCategory = Uri.encodeComponent(category);
    final uri = Uri.parse('$baseUrl/products/category/$encodedCategory');
    try {
      final response = await _client.get(uri).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> productsJson = data['products'] as List<dynamic>? ?? [];
        return productsJson.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw HttpException('Failed to load products for category $category (HTTP ${response.statusCode})');
      }
    } on SocketException {
      throw const SocketException('No Internet connection. Please check your network.');
    } on TimeoutException {
      throw TimeoutException('Connection timed out. Please try again.');
    }
  }
}
