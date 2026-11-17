import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/wishlist_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/wishlist_swipe_item.dart';
import 'product_detail_screen.dart';

class WishlistScreen extends StatelessWidget {
  final VoidCallback onStartShopping;

  const WishlistScreen({super.key, required this.onStartShopping});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Wishlist'),
        actions: [
          Consumer<WishlistProvider>(
            builder: (context, wishlistProvider, _) {
              if (wishlistProvider.itemCount == 0)
                return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.antique.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${wishlistProvider.itemCount} items',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.evergreen,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<WishlistProvider>(
        builder: (context, wishlistProvider, _) {
          if (wishlistProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.evergreen),
            );
          }

          final items = wishlistProvider.items;

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.antique.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        size: 44,
                        color: AppColors.dryLeaf,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Your wishlist is empty',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Explore products and save your favorite items here to review later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.fundySlate,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: onStartShopping,
                      icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                      label: const Text('Start Shopping'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(180, 48),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final product = items[index];

              return WishlistSwipeItem(
                onDismiss: () => _removeWishlistItem(
                  context,
                  wishlistProvider,
                  product.id,
                  fromSwipe: true,
                ),
                child: InkWell(
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
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.antique, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.fundySlate.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Thumbnail
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(15),
                          ),
                          child: Container(
                            width: 100,
                            height: 100,
                            color: AppColors.antique.withValues(alpha: 0.25),
                            child: product.thumbnail.isNotEmpty
                                ? Image.network(
                                    product.thumbnail,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          color: AppColors.dryLeaf,
                                          size: 28,
                                        ),
                                      );
                                    },
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.shopping_bag_outlined,
                                      color: AppColors.dryLeaf,
                                      size: 28,
                                    ),
                                  ),
                          ),
                        ),
                        // Details
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.category.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.fundySlate,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.evergreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Delete from wishlist button
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.wishlistRemove,
                              size: 22,
                            ),
                            tooltip: 'Remove',
                            onPressed: () => _removeWishlistItem(
                              context,
                              wishlistProvider,
                              product.id,
                              title: product.title,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool> _removeWishlistItem(
    BuildContext context,
    WishlistProvider wishlistProvider,
    int productId, {
    String? title,
    bool fromSwipe = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final removed = await wishlistProvider.removeItem(productId);
      if (!context.mounted || !removed) return removed;

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.wishlistRemove,
          duration: const Duration(seconds: 2),
          content: Text(
            fromSwipe
                ? 'Removed from wishlist'
                : 'Removed "$title" from wishlist',
          ),
        ),
      );
      return true;
    } catch (error, stackTrace) {
      debugPrint('Failed to remove product from wishlist: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.wishlistRemove,
            content: Text(
              'Unable to remove the product from wishlist. Please try again.',
            ),
          ),
        );
      }
      return false;
    }
  }
}
