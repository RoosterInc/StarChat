import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/design_tokens.dart';
import '../models/marketplace_models.dart';

/// Product list tile for seller dashboard
class ProductListTile extends StatelessWidget {
  final Product product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(int)? onUpdateStock;

  const ProductListTile({
    Key? key,
    required this.product,
    this.onEdit,
    this.onDelete,
    this.onUpdateStock,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shadowColor: context.colorScheme.shadow.withOpacity(0.05),
      surfaceTintColor: context.colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
      ),
      child: Padding(
        padding: DesignTokens.md(context).all,
        child: Row(
          children: [
            // Product image
            _buildProductImage(context),
            
            SizedBox(width: DesignTokens.md(context).width),
            
            // Product info
            Expanded(
              child: _buildProductInfo(context),
            ),
            
            SizedBox(width: DesignTokens.md(context).width),
            
            // Actions
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm(context)),
        color: context.colorScheme.surfaceVariant,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm(context)),
        child: product.images.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: product.images.first.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: context.colorScheme.surfaceVariant,
                  child: Icon(
                    Icons.image,
                    color: context.colorScheme.outline,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: context.colorScheme.surfaceVariant,
                  child: Icon(
                    Icons.image_not_supported,
                    color: context.colorScheme.outline,
                  ),
                ),
              )
            : Container(
                color: context.colorScheme.surfaceVariant,
                child: Icon(
                  Icons.image,
                  color: context.colorScheme.outline,
                ),
              ),
      ),
    );
  }

  Widget _buildProductInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product title
        Text(
          product.title,
          style: context.textTheme.titleSmall?.copyWith(
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        SizedBox(height: DesignTokens.xs(context).height),
        
        // Price and status
        Row(
          children: [
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            SizedBox(width: DesignTokens.sm(context).width),
            
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.xs(context).left,
                vertical: DesignTokens.xxs(context).top,
              ),
              decoration: BoxDecoration(
                color: _getStatusColor(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusXs(context)),
                border: Border.all(
                  color: _getStatusColor(context).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _getStatusText(),
                style: context.textTheme.labelSmall?.copyWith(
                  color: _getStatusColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: DesignTokens.xs(context).height),
        
        // Stock info
        _buildStockInfo(context),
        
        SizedBox(height: DesignTokens.xs(context).height),
        
        // Performance metrics
        _buildMetrics(context),
      ],
    );
  }

  Widget _buildStockInfo(BuildContext context) {
    if (!product.trackInventory) {
      return Text(
        'Unlimited stock',
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.onSurface.withOpacity(0.6),
        ),
      );
    }

    return Row(
      children: [
        Icon(
          Icons.inventory,
          size: DesignTokens.iconXs(context),
          color: product.isLowStock ? Colors.orange : context.colorScheme.outline,
        ),
        
        SizedBox(width: DesignTokens.xxs(context).width),
        
        Text(
          '${product.stockQuantity} in stock',
          style: context.textTheme.bodySmall?.copyWith(
            color: product.isLowStock 
                ? Colors.orange
                : context.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: product.isLowStock ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        
        if (product.isLowStock) ...[
          SizedBox(width: DesignTokens.xs(context).width),
          Icon(
            Icons.warning,
            size: DesignTokens.iconXs(context),
            color: Colors.orange,
          ),
        ],
      ],
    );
  }

  Widget _buildMetrics(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.visibility,
          size: DesignTokens.iconXs(context),
          color: context.colorScheme.outline,
        ),
        SizedBox(width: DesignTokens.xxs(context).width),
        Text(
          '${product.viewCount}',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        
        SizedBox(width: DesignTokens.sm(context).width),
        
        Icon(
          Icons.shopping_cart,
          size: DesignTokens.iconXs(context),
          color: context.colorScheme.outline,
        ),
        SizedBox(width: DesignTokens.xxs(context).width),
        Text(
          '${product.salesCount}',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        
        if (product.averageRating > 0) ...[
          SizedBox(width: DesignTokens.sm(context).width),
          Icon(
            Icons.star,
            size: DesignTokens.iconXs(context),
            color: Colors.amber,
          ),
          SizedBox(width: DesignTokens.xxs(context).width),
          Text(
            product.averageRating.toStringAsFixed(1),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleAction(context, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (product.trackInventory)
          const PopupMenuItem(
            value: 'stock',
            child: ListTile(
              leading: Icon(Icons.inventory),
              title: Text('Update Stock'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        PopupMenuItem(
          value: product.isActive ? 'deactivate' : 'activate',
          child: ListTile(
            leading: Icon(product.isActive ? Icons.visibility_off : Icons.visibility),
            title: Text(product.isActive ? 'Deactivate' : 'Activate'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      child: Container(
        padding: DesignTokens.sm(context).all,
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm(context)),
        ),
        child: Icon(
          Icons.more_vert,
          size: DesignTokens.iconSm(context),
          color: context.colorScheme.onSurface,
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context) {
    if (!product.isActive) return Colors.grey;
    if (!product.isInStock) return Colors.red;
    if (product.isLowStock) return Colors.orange;
    return Colors.green;
  }

  String _getStatusText() {
    if (!product.isActive) return 'Inactive';
    if (!product.isInStock) return 'Out of Stock';
    if (product.isLowStock) return 'Low Stock';
    return 'Active';
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        onEdit?.call();
        break;
      case 'stock':
        _showStockDialog(context);
        break;
      case 'activate':
      case 'deactivate':
        _toggleProductStatus(context);
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }

  void _showStockDialog(BuildContext context) {
    final controller = TextEditingController(text: product.stockQuantity.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Stock'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Stock Quantity',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newStock = int.tryParse(controller.text);
              if (newStock != null && newStock >= 0) {
                Get.back();
                onUpdateStock?.call(newStock);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _toggleProductStatus(BuildContext context) {
    // TODO: Implement product status toggle
    Get.snackbar(
      'Feature Coming Soon',
      'Product status toggle will be available soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}