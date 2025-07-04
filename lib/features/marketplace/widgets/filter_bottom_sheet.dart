import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design_tokens.dart';
import '../controllers/marketplace_controller.dart';

/// Filter bottom sheet for mobile devices
class FilterBottomSheet extends StatelessWidget {
  const FilterBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(DesignTokens.radiusLg(context)),
            ),
          ),
          child: Column(
            children: [
              _buildHandle(context),
              _buildHeader(context),
              Expanded(
                child: _buildContent(context, scrollController),
              ),
              _buildActionButtons(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Container(
      margin: DesignTokens.sm(context).top,
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: context.colorScheme.outline.withOpacity(0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: DesignTokens.lg(context).symmetric(horizontal: true),
      child: Row(
        children: [
          Text(
            'Filters',
            style: context.textTheme.headlineSmall?.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: DesignTokens.lg(context).all,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPriceRangeFilter(context),
          SizedBox(height: DesignTokens.xl(context).height),
          _buildFeaturedToggle(context),
          SizedBox(height: DesignTokens.xl(context).height),
          _buildCategoryFilter(context),
        ],
      ),
    );
  }

  Widget _buildPriceRangeFilter(BuildContext context) {
    return GetBuilder<MarketplaceController>(
      builder: (controller) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price Range',
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            SizedBox(height: DesignTokens.md(context).height),
            
            RangeSlider(
              values: RangeValues(
                controller.priceRange[0],
                controller.priceRange[1],
              ),
              min: 0,
              max: 1000,
              divisions: 20,
              labels: RangeLabels(
                '\$${controller.priceRange[0].round()}',
                '\$${controller.priceRange[1].round()}',
              ),
              onChanged: (values) {
                controller.updatePriceRange(values.start, values.end);
              },
            ),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${controller.priceRange[0].round()}',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '\$${controller.priceRange[1].round()}',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeaturedToggle(BuildContext context) {
    return GetBuilder<MarketplaceController>(
      builder: (controller) {
        return SwitchListTile(
          title: Text(
            'Featured Products Only',
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Show only featured products',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          value: controller.showFeaturedOnly,
          onChanged: (_) => controller.toggleFeaturedOnly(),
          contentPadding: EdgeInsets.zero,
        );
      },
    );
  }

  Widget _buildCategoryFilter(BuildContext context) {
    return GetBuilder<MarketplaceController>(
      builder: (controller) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categories',
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            SizedBox(height: DesignTokens.md(context).height),
            
            // All categories option
            RadioListTile<String?>(
              title: const Text('All Categories'),
              value: null,
              groupValue: controller.selectedCategory?.id,
              onChanged: (value) => controller.filterByCategory(null),
              contentPadding: EdgeInsets.zero,
            ),
            
            // Individual categories
            ...controller.categories.map((category) {
              return RadioListTile<String?>(
                title: Text(category.name),
                subtitle: Text('${category.productCount} products'),
                value: category.id,
                groupValue: controller.selectedCategory?.id,
                onChanged: (value) => controller.filterByCategory(category),
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: DesignTokens.lg(context).all,
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: context.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: GetBuilder<MarketplaceController>(
        builder: (controller) {
          return Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    controller.clearFilters();
                    Get.back();
                  },
                  child: const Text('Clear All'),
                ),
              ),
              
              SizedBox(width: DesignTokens.md(context).width),
              
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  child: Text('Show ${controller.products.length} Products'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}