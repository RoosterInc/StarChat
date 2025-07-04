import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design_tokens.dart';
import '../models/marketplace_models.dart';

/// Order list tile for displaying order information
class OrderListTile extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderListTile({
    Key? key,
    required this.order,
    this.onTap,
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
        child: Padding(
          padding: DesignTokens.md(context).all,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.orderNumber}',
                          style: context.textTheme.titleSmall?.copyWith(
                            color: context.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        
                        SizedBox(height: DesignTokens.xs(context).height),
                        
                        Text(
                          _formatDate(order.createdAt),
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${order.totalAmount.toStringAsFixed(2)}',
                        style: context.textTheme.titleMedium?.copyWith(
                          color: context.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      SizedBox(height: DesignTokens.xs(context).height),
                      
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: DesignTokens.sm(context).left,
                          vertical: DesignTokens.xs(context).top,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusSm(context)),
                          border: Border.all(
                            color: _getStatusColor().withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getStatusDisplayName(),
                          style: context.textTheme.labelSmall?.copyWith(
                            color: _getStatusColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              SizedBox(height: DesignTokens.md(context).height),
              
              // Order items
              _buildOrderItems(context),
              
              SizedBox(height: DesignTokens.md(context).height),
              
              // Order details
              _buildOrderDetails(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItems(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items (${order.items.length})',
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        SizedBox(height: DesignTokens.sm(context).height),
        
        ...order.items.take(3).map((item) => Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.xs(context).height),
          child: Row(
            children: [
              // Product image placeholder
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXs(context)),
                ),
                child: item.productImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusXs(context)),
                        child: Image.network(
                          item.productImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.image,
                            size: DesignTokens.iconSm(context),
                            color: context.colorScheme.outline,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.image,
                        size: DesignTokens.iconSm(context),
                        color: context.colorScheme.outline,
                      ),
              ),
              
              SizedBox(width: DesignTokens.sm(context).width),
              
              Expanded(
                child: Text(
                  '${item.quantity}x ${item.productTitle}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurface.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              Text(
                '\$${item.totalPrice.toStringAsFixed(2)}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurface.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        )).toList(),
        
        if (order.items.length > 3) ...[
          SizedBox(height: DesignTokens.xs(context).height),
          Text(
            '+${order.items.length - 3} more items',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOrderDetails(BuildContext context) {
    return Column(
      children: [
        if (order.paymentStatus != PaymentStatus.paid)
          _buildDetailRow(
            context,
            'Payment Status',
            _getPaymentStatusDisplayName(),
            color: _getPaymentStatusColor(),
          ),
        
        if (order.trackingNumber != null)
          _buildDetailRow(
            context,
            'Tracking',
            order.trackingNumber!,
          ),
        
        if (order.estimatedDelivery != null)
          _buildDetailRow(
            context,
            'Est. Delivery',
            _formatDate(order.estimatedDelivery),
          ),
        
        if (order.notes != null && order.notes!.isNotEmpty)
          _buildDetailRow(
            context,
            'Notes',
            order.notes!,
          ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.xs(context).height),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          
          Expanded(
            child: Text(
              value,
              style: context.textTheme.bodySmall?.copyWith(
                color: color ?? context.colorScheme.onSurface.withOpacity(0.8),
                fontWeight: color != null ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (order.status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.processing:
        return Colors.purple;
      case OrderStatus.shipped:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.refunded:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName() {
    switch (order.status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  Color _getPaymentStatusColor() {
    switch (order.paymentStatus) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.processing:
        return Colors.blue;
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
      case PaymentStatus.refunded:
        return Colors.purple;
    }
  }

  String _getPaymentStatusDisplayName() {
    switch (order.paymentStatus) {
      case PaymentStatus.pending:
        return 'Payment Pending';
      case PaymentStatus.processing:
        return 'Processing Payment';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Payment Failed';
      case PaymentStatus.cancelled:
        return 'Payment Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}