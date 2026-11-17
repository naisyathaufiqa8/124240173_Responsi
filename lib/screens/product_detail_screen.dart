import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/wishlist_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  final Product? initialProduct;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.initialProduct,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _apiService = ApiService();
  final PageController _pageController = PageController();

  Product? _product;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _product = widget.initialProduct;
    _fetchDetail();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final product = await _apiService.getProductDetail(widget.productId);
      if (mounted) {
        setState(() {
          _product = product;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // If we already have initialProduct from card tap, we can still show it while showing error or if none, show error
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          if (_product != null)
            Consumer<WishlistProvider>(
              builder: (context, wishlistProvider, _) {
                final inWishlist = wishlistProvider.isInWishlist(_product!.id);
                return IconButton(
                  icon: Icon(
                    inWishlist ? Icons.favorite : Icons.favorite_border,
                    color: inWishlist ? AppColors.evergreen : AppColors.fundySlate,
                  ),
                  tooltip: inWishlist ? 'Remove from wishlist' : 'Add to wishlist',
                  onPressed: () async {
                    final scaffold = ScaffoldMessenger.of(context);
                    final result = await wishlistProvider.toggleWishlist(_product!);
                    if (!context.mounted) return;
                    if (result == true) {
                      scaffold.hideCurrentSnackBar();
                      scaffold.showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.wishlistAdd,
                          duration: const Duration(seconds: 2),
                          content: Row(
                            children: [
                              const Icon(Icons.favorite, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Added "${_product!.title}" to wishlist'),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (result == false) {
                      scaffold.hideCurrentSnackBar();
                      scaffold.showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.wishlistRemove,
                          duration: const Duration(seconds: 2),
                          content: Row(
                            children: [
                              const Icon(Icons.favorite_border, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Removed "${_product!.title}" from wishlist'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _product == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.evergreen),
      );
    }

    if (_errorMessage != null && _product == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 52,
                color: AppColors.wishlistRemove,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load product',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.fundySlate,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchDetail,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(140, 46),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final product = _product!;
    final images = product.images.isNotEmpty
        ? product.images
        : (product.thumbnail.isNotEmpty ? [product.thumbnail] : <String>[]);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Carousel
          Container(
            height: 320,
            width: double.infinity,
            color: AppColors.antique.withValues(alpha: 0.2),
            child: images.isNotEmpty
                ? Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: images.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Image.network(
                            images[index],
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.evergreen,
                                  strokeWidth: 2,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: AppColors.dryLeaf,
                                  size: 48,
                                ),
                              );
                            },
                          );
                        },
                      ),
                      // Carousel dots indicator
                      if (images.length > 1)
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(images.length, (index) {
                              final isActive = _currentImageIndex == index;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: isActive ? 20 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isActive ? AppColors.evergreen : AppColors.dryLeaf,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  )
                : const Center(
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 64,
                      color: AppColors.dryLeaf,
                    ),
                  ),
          ),

          // Details Container
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category & Brand badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.antique.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.evergreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (product.brand.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.antique),
                        ),
                        child: Text(
                          product.brand,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.fundySlate,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 12),

                // Price, Discount Badge, Rating
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.evergreen,
                      ),
                    ),
                    if (product.discountPercentage > 0) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.evergreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${product.discountPercentage.toStringAsFixed(0)}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Rating
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.antique.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.ratingStar,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stock status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: product.stock > 0
                        ? AppColors.evergreen.withValues(alpha: 0.08)
                        : AppColors.wishlistRemove.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        product.stock > 0 ? Icons.check_circle_outline : Icons.highlight_off,
                        size: 16,
                        color: product.stock > 0 ? AppColors.evergreen : AppColors.wishlistRemove,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        product.stock > 0
                            ? 'In Stock (${product.stock} available)'
                            : 'Out of Stock',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: product.stock > 0 ? AppColors.evergreen : AppColors.wishlistRemove,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Description Title
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.description.isNotEmpty
                      ? product.description
                      : 'No detailed description available for this product.',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: AppColors.fundySlate,
                  ),
                ),
                const SizedBox(height: 36),

                // Big Wishlist Action Button
                Consumer<WishlistProvider>(
                  builder: (context, wishlistProvider, _) {
                    final inWishlist = wishlistProvider.isInWishlist(product.id);
                    return ElevatedButton.icon(
                      onPressed: () async {
                        final scaffold = ScaffoldMessenger.of(context);
                        final result = await wishlistProvider.toggleWishlist(product);
                        if (!context.mounted) return;
                        if (result == true) {
                          scaffold.hideCurrentSnackBar();
                          scaffold.showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.wishlistAdd,
                              duration: const Duration(seconds: 2),
                              content: Row(
                                children: [
                                  const Icon(Icons.favorite, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text('Added "${product.title}" to wishlist'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else if (result == false) {
                          scaffold.hideCurrentSnackBar();
                          scaffold.showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.wishlistRemove,
                              duration: const Duration(seconds: 2),
                              content: Row(
                                children: [
                                  const Icon(Icons.favorite_border, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text('Removed "${product.title}" from wishlist'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        inWishlist ? Icons.favorite : Icons.favorite_border,
                        color: inWishlist ? Colors.white : Colors.white,
                      ),
                      label: Text(
                        inWishlist ? 'Remove from Wishlist' : 'Add to Wishlist',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: inWishlist ? AppColors.wishlistRemove : AppColors.evergreen,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
