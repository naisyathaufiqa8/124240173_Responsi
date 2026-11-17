import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/wishlist_provider.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToWishlist;

  const HomeScreen({
    super.key,
    required this.onNavigateToWishlist,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  String _username = 'Shopper';
  List<String> _categories = [];
  String _selectedCategory = 'All';

  List<Product> _products = [];
  bool _isLoadingCategories = true;
  bool _isLoadingProducts = true;
  String? _productError;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchCategories();
    _fetchProducts();
  }

  Future<void> _loadUser() async {
    final name = await SessionService.getUsername();
    if (mounted && name != null && name.isNotEmpty) {
      setState(() {
        _username = name;
      });
    }
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });

    try {
      final list = await _apiService.getCategories();
      if (mounted) {
        setState(() {
          _categories = ['All', ...list];
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categoryError = e.toString();
          _isLoadingCategories = false;
          // Fallback minimal category if API had temporary glitch
          if (_categories.isEmpty) {
            _categories = ['All'];
          }
        });
      }
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _productError = null;
    });

    try {
      List<Product> result;
      if (_selectedCategory == 'All') {
        result = await _apiService.getProducts(limit: 30);
      } else {
        result = await _apiService.getProductsByCategory(_selectedCategory);
      }

      if (mounted) {
        setState(() {
          _products = result;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _productError = e.toString().replaceFirst('Exception: ', '');
          _isLoadingProducts = false;
        });
      }
    }
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
    });
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $_username',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Text(
              'Explore curated collections',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.fundySlate,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<WishlistProvider>(
            builder: (context, wishlistProvider, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    tooltip: 'Wishlist',
                    onPressed: widget.onNavigateToWishlist,
                  ),
                  if (wishlistProvider.itemCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.evergreen,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          wishlistProvider.itemCount > 9 ? '9+' : '${wishlistProvider.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.evergreen,
        backgroundColor: Colors.white,
        onRefresh: () async {
          await Future.wait([
            _fetchCategories(),
            _fetchProducts(),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Category horizontal chips
            SliverToBoxAdapter(
              child: _buildCategoryList(),
            ),

            // Section title with category label
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      _selectedCategory == 'All' ? 'All Products' : _selectedCategory.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!_isLoadingProducts && _products.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.antique.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_products.length} items',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.fundySlate,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Products Grid / Loading / Error / Empty
            _buildProductsGrid(),
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    if (_isLoadingCategories && _categories.isEmpty) {
      return Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.evergreen),
        ),
      );
    }

    if (_categoryError != null && _categories.length <= 1) {
      return Container(
        height: 48,
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            const Text(
              'Categories unavailable',
              style: TextStyle(fontSize: 12, color: AppColors.fundySlate),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _fetchCategories,
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Retry', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          // Format category text nicely (e.g. "beauty" -> "Beauty")
          final displayText = category == 'All'
              ? 'All'
              : (category.length > 1
                  ? category[0].toUpperCase() + category.substring(1).replaceAll('-', ' ')
                  : category);

          return FilterChip(
            selected: isSelected,
            showCheckmark: false,
            label: Text(displayText),
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
            backgroundColor: AppColors.background,
            selectedColor: AppColors.evergreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppColors.evergreen : AppColors.antique,
                width: 1.2,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            onSelected: (_) => _onCategorySelected(category),
          );
        },
      ),
    );
  }

  Widget _buildProductsGrid() {
    if (_isLoadingProducts) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.evergreen),
        ),
      );
    }

    if (_productError != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 50,
                  color: AppColors.wishlistRemove,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load products',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _productError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.fundySlate,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _fetchProducts,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 44),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 54,
                  color: AppColors.dryLeaf,
                ),
                const SizedBox(height: 14),
                const Text(
                  'No products found',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Try selecting another category or check back later.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.fundySlate),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.65,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = _products[index];
            return ProductCard(
              product: product,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(
                      productId: product.id,
                      initialProduct: product,
                    ),
                  ),
                );
              },
            );
          },
          childCount: _products.length,
        ),
      ),
    );
  }
}
