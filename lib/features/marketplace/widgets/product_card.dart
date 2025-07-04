import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/design_tokens.dart';
import '../../../core/responsive_utils.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../models/marketplace_models.dart';
import '../controllers/cart_controller.dart';

/// Product card widget following AGENTS.md design patterns
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final bool showAddToCart;

  const ProductCard({
    Key? key,
    required this.product,
    this.onTap,
    this.showAddToCart = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: context.colorScheme.shadow.withOpacity(0.1),
      surfaceTintColor: context.colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _buildProductImage(context),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: DesignTokens.md(context).all,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductTitle(context),
                    SizedBox(height: DesignTokens.xs(context).height),
                    _buildProductPrice(context),
                    SizedBox(height: DesignTokens.xs(context).height),
                    _buildProductRating(context),
                    const Spacer(),
                    if (showAddToCart) _buildAddToCartButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusMd(context)),
        ),
        color: context.colorScheme.surfaceVariant,
      ),
      child: Stack(
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(DesignTokens.radiusMd(context)),
            ),
            child: product.images.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: product.images.first.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => SkeletonLoader(
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(DesignTokens.radiusMd(context)),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: context.colorScheme.surfaceVariant,
                      child: Icon(
                        Icons.image_not_supported,
                        size: DesignTokens.iconLg(context),
                        color: context.colorScheme.outline,
                      ),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: context.colorScheme.surfaceVariant,
                    child: Icon(
                      Icons.image,
                      size: DesignTokens.iconLg(context),
                      color: context.colorScheme.outline,
                    ),
                  ),
          ),
          
          // Badges overlay
          Positioned(
            top: DesignTokens.sm(context).top,
            left: DesignTokens.sm(context).left,
            child: _buildBadges(context),
          ),
          
          // Wishlist button
          Positioned(
            top: DesignTokens.sm(context).top,
            right: DesignTokens.sm(context).right,
            child: _buildWishlistButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBadges(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.isFeatured)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.xs(context).left,
              vertical: DesignTokens.xxs(context).top,
            ),
            decoration: BoxDecoration(
              color: context.colorScheme.primary,
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm(context)),
            ),
            child: Text(
              'Featured',
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        
        if (product.discountPercentage != null) ...[
          SizedBox(height: DesignTokens.xxs(context).height),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.xs(context).left,
              vertical: DesignTokens.xxs(context).top,
            ),
            decoration: BoxDecoration(
              color: context.colorScheme.error,
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm(context)),
            ),
            child: Text(
              '${product.discountPercentage!.round()}% OFF',
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colorScheme.onError,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        
        if (!product.isInStock) ...[
          SizedBox(height: DesignTokens.xxs(context).height),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.xs(context).left,
              vertical: DesignTokens.xxs(context).top,
            ),
            decoration: BoxDecoration(
              color: context.colorScheme.outline,
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm(context)),
            ),
            child: Text(
              'Out of Stock',
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colorScheme.surface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWishlistButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface.withOpacity(0.9),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: () => _toggleWishlist(context),
        icon: Icon(
          Icons.favorite_border, // TODO: Use filled icon if in wishlist
          size: DesignTokens.iconSm(context),
        ),
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          foregroundColor: context.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildProductTitle(BuildContext context) {
    return Text(
      product.title,
      style: context.textTheme.titleSmall?.copyWith(
        color: context.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildProductPrice(BuildContext context) {
    return Row(
      children: [
        Text(
          '\$${product.price.toStringAsFixed(2)}',
          style: context.textTheme.titleMedium?.copyWith(
            color: context.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        if (product.comparePrice != null) ...[
          SizedBox(width: DesignTokens.xs(context).width),
          Text(
            '\$${product.comparePrice!.toStringAsFixed(2)}',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.outline,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProductRating(BuildContext context) {
    if (product.averageRating == 0 || product.reviewCount == 0) {
      return Text(
        'No reviews yet',
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.outline,
        ),
      );
    }

    return Row(
      children: [
        Icon(
          Icons.star,
          size: DesignTokens.iconXs(context),
          color: Colors.amber,
        ),
        SizedBox(width: DesignTokens.xxs(context).width),
        Text(
          product.averageRating.toStringAsFixed(1),
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: DesignTokens.xxs(context).width),
        Text(
          '(${product.reviewCount})',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildAddToCartButton(BuildContext context) {
    return GetBuilder<CartController>(
      builder: (cartController) {
        final isInCart = cartController.isProductInCart(product.id!);
        final quantity = cartController.getProductQuantityInCart(product.id!);
        
        if (isInCart) {
          return Row(
            children: [
              IconButton(
                onPressed: () => cartController.decrementQuantity(product.id!),
                icon: const Icon(Icons.remove),
                style: IconButton.styleFrom(
                  backgroundColor: context.colorScheme.primary,
                  foregroundColor: context.colorScheme.onPrimary,
                  minimumSize: Size(32, 32),
                ),
                visualDensity: VisualDensity.compact,
              ),
              
              Expanded(
                child: Text(
                  '$quantity in cart',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              IconButton(
                onPressed: () => cartController.incrementQuantity(product.id!),
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: context.colorScheme.primary,
                  foregroundColor: context.colorScheme.onPrimary,
                  minimumSize: Size(32, 32),
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          );
        }
        
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: product.isInStock 
                ? () => cartController.addToCart(product)
                : null,
            style: ElevatedButton.styleFrom(
              padding: DesignTokens.sm(context).symmetric(vertical: true),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm(context)),
              ),
            ),
            child: Text(
              product.isInStock ? 'Add to Cart' : 'Out of Stock',
              style: context.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleWishlist(BuildContext context) {
    // TODO: Implement wishlist toggle functionality
    Get.snackbar(
      'Feature Coming Soon',
      'Wishlist functionality will be available soon',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}