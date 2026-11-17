import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/database_helper.dart';

class WishlistProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
  int? _currentUserId;
  List<Product> _wishlistItems = [];
  bool _isLoading = false;

  WishlistProvider({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  int? get currentUserId => _currentUserId;
  List<Product> get items => List.unmodifiable(_wishlistItems);
  bool get isLoading => _isLoading;
  int get itemCount => _wishlistItems.length;


  bool isInWishlist(int productId) {
    return _wishlistItems.any((item) => item.id == productId);
  }

  
  Future<void> loadWishlist(int userId) async {
    _currentUserId = userId;
    _isLoading = true;
    notifyListeners();

    try {
      _wishlistItems = await _dbHelper.getWishlist(userId);
    } catch (e) {
      debugPrint('Error loading wishlist: $e');
      _wishlistItems = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  
  Future<bool?> toggleWishlist(Product product) async {
    if (_currentUserId == null) return null;

    final inWishlist = isInWishlist(product.id);
    if (inWishlist) {
      final success = await _dbHelper.removeFromWishlist(_currentUserId!, product.id);
      if (success) {
        _wishlistItems.removeWhere((item) => item.id == product.id);
        notifyListeners();
        return false; // Removed
      }
      return null;
    } else {
      final success = await _dbHelper.addToWishlist(_currentUserId!, product);
      if (success) {
        _wishlistItems.insert(0, product);
        notifyListeners();
        return true; // Added
      }
      return null;
    }
  }


  Future<bool> removeItem(int productId) async {
    if (_currentUserId == null) return false;

    final success = await _dbHelper.removeFromWishlist(_currentUserId!, productId);
    if (success) {
      _wishlistItems.removeWhere((item) => item.id == productId);
      notifyListeners();
      return true;
    }
    return false;
  }

  
  void clear() {
    _currentUserId = null;
    _wishlistItems = [];
    _isLoading = false;
    notifyListeners();
  }
}
