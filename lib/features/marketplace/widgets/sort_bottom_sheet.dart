import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design_tokens.dart';
import '../controllers/marketplace_controller.dart';
import '../services/product_service.dart';

/// Sort bottom sheet for selecting product sort order
class SortBottomSheet extends StatelessWidget {
  const SortBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: DesignTokens.lg(context).all,
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg(context)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          _buildSortOptions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: DesignTokens.lg(context).all,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Sort By',
            style: context.textTheme.titleLarge?.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              foregroundColor: context.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOptions(BuildContext context) {
    return GetBuilder<MarketplaceController>(
      builder: (controller) {
        return Column(
          children: ProductSortBy.values.map((sortBy) {
            final isSelected = controller.sortBy == sortBy;
            
            return ListTile(
              title: Text(
                controller.getSortDisplayName(sortBy),
                style: context.textTheme.bodyLarge?.copyWith(
                  color: isSelected 
                      ? context.colorScheme.primary
                      : context.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              leading: Radio<ProductSortBy>(
                value: sortBy,
                groupValue: controller.sortBy,
                onChanged: (value) {
                  if (value != null) {
                    controller.updateSortBy(value);
                    Get.back();
                  }
                },
              ),
              trailing: isSelected 
                  ? Icon(
                      Icons.check,
                      color: context.colorScheme.primary,
                      size: DesignTokens.iconSm(context),
                    )
                  : null,
              onTap: () {
                controller.updateSortBy(sortBy);
                Get.back();
              },
            );
          }).toList(),
        );
      },
    );
  }
}