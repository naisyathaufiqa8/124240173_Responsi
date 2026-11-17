import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/wishlist_provider.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, _) {
        final isInWishlist = wishlistProvider.isInWishlist(product.id);

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.antique, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.fundySlate.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image container with heart button
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: AppColors.antique.withValues(alpha: 0.25),
                          child: product.thumbnail.isNotEmpty
                              ? Image.network(
                                  product.thumbnail,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
                                          color: AppColors.evergreen,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        color: AppColors.dryLeaf,
                                        size: 36,
                                      ),
                                    );
                                  },
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.shopping_bag_outlined,
                                    color: AppColors.dryLeaf,
                                    size: 36,
                                  ),
                                ),
                        ),
                      ),
                      // Wishlist heart button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              final scaffold = ScaffoldMessenger.of(context);
                              bool? result;
                              try {
                                result = await wishlistProvider.toggleWishlist(
                                  product,
                                );
                              } catch (error, stackTrace) {
                                debugPrint('Failed to update wishlist: $error');
                                debugPrintStack(stackTrace: stackTrace);
                                if (!context.mounted) return;
                                scaffold.showSnackBar(
                                  const SnackBar(
                                    backgroundColor: AppColors.wishlistRemove,
                                    content: Text(
                                      'Unable to update the wishlist in the local database.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              if (!context.mounted) return;
                              if (result == true) {
                                scaffold.hideCurrentSnackBar();
                                scaffold.showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.wishlistAdd,
                                    duration: const Duration(seconds: 2),
                                    content: Row(
                                      children: [
                                        const Icon(
                                          Icons.favorite,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Added "${product.title}" to wishlist',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
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
                                        const Icon(
                                          Icons.favorite_border,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Removed "${product.title}" from wishlist',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isInWishlist
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isInWishlist
                                    ? AppColors.evergreen
                                    : AppColors.fundySlate,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Optional Discount badge if > 0
                      if (product.discountPercentage > 0)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.evergreen,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '-${product.discountPercentage.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Product info
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category
                      Text(
                        product.category.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.fundySlate,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      // Title
                      Text(
                        product.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Price & Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.evergreen,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (product.rating > 0)
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: AppColors.ratingStar,
                                  size: 16,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  product.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: AppColors.fundySlate,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
