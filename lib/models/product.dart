class Product {
  final int id;
  final String title;
  final String description;
  final String category;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String brand;
  final String thumbnail;
  final List<String> images;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    this.discountPercentage = 0.0,
    this.rating = 0.0,
    this.stock = 0,
    this.brand = '',
    required this.thumbnail,
    this.images = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Parse images list safely
    List<String> imageList = [];
    if (json['images'] is List) {
      imageList = (json['images'] as List)
          .map((item) => item?.toString() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }

    // Determine thumbnail safely
    String thumb = json['thumbnail']?.toString() ?? '';
    if (thumb.isEmpty && imageList.isNotEmpty) {
      thumb = imageList.first;
    }

    return Product(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? 'Unnamed Product',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      discountPercentage: (json['discountPercentage'] is num)
          ? (json['discountPercentage'] as num).toDouble()
          : double.tryParse(json['discountPercentage']?.toString() ?? '0.0') ?? 0.0,
      rating: (json['rating'] is num)
          ? (json['rating'] as num).toDouble()
          : double.tryParse(json['rating']?.toString() ?? '0.0') ?? 0.0,
      stock: json['stock'] is int
          ? json['stock'] as int
          : int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
      brand: json['brand']?.toString() ?? '',
      thumbnail: thumb,
      images: imageList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'discountPercentage': discountPercentage,
      'rating': rating,
      'stock': stock,
      'brand': brand,
      'thumbnail': thumbnail,
      'images': images,
    };
  }

  // Map for SQLite storage
  Map<String, dynamic> toDbMap({required int userId}) {
    return {
      'user_id': userId,
      'product_id': id,
      'title': title,
      'category': category,
      'price': price,
      'thumbnail': thumbnail,
      'brand': brand,
      'rating': rating,
    };
  }

  factory Product.fromDbMap(Map<String, dynamic> map) {
    final thumb = map['thumbnail']?.toString() ?? '';
    return Product(
      id: map['product_id'] is int ? map['product_id'] as int : int.tryParse(map['product_id']?.toString() ?? '0') ?? 0,
      title: map['title']?.toString() ?? 'Unnamed Product',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? 'General',
      price: (map['price'] is num)
          ? (map['price'] as num).toDouble()
          : double.tryParse(map['price']?.toString() ?? '0.0') ?? 0.0,
      discountPercentage: 0.0,
      rating: (map['rating'] is num)
          ? (map['rating'] as num).toDouble()
          : double.tryParse(map['rating']?.toString() ?? '0.0') ?? 0.0,
      stock: 0,
      brand: map['brand']?.toString() ?? '',
      thumbnail: thumb,
      images: thumb.isNotEmpty ? [thumb] : [],
    );
  }
}
