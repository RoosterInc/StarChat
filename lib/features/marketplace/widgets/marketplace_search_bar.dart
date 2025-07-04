import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design_tokens.dart';
import '../controllers/marketplace_controller.dart';

/// Marketplace search bar widget
class MarketplaceSearchBar extends StatelessWidget {
  const MarketplaceSearchBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MarketplaceController>(
      builder: (controller) {
        return TextField(
          onSubmitted: (value) => controller.searchProducts(value),
          onChanged: (value) {
            // Debounced search could be implemented here
            if (value.isEmpty) {
              controller.searchProducts('');
            }
          },
          decoration: InputDecoration(
            hintText: 'Search products...',
            hintStyle: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.6),
            ),
            prefixIcon: Icon(
              Icons.search,
              size: DesignTokens.iconMd(context),
              color: context.colorScheme.onSurface.withOpacity(0.6),
            ),
            suffixIcon: controller.searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () => controller.searchProducts(''),
                    icon: Icon(
                      Icons.clear,
                      size: DesignTokens.iconSm(context),
                    ),
                  )
                : null,
            filled: true,
            fillColor: context.colorScheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
              borderSide: BorderSide(
                color: context.colorScheme.primary,
                width: 2,
              ),
            ),
            contentPadding: DesignTokens.md(context).symmetric(
              horizontal: true,
              vertical: true,
            ),
          ),
        );
      },
    );
  }
}