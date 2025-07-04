import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design_tokens.dart';
import '../../../core/responsive_utils.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/optimized_list_view.dart';
import '../controllers/marketplace_controller.dart';
import '../widgets/product_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/marketplace_search_bar.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/sort_bottom_sheet.dart';

/// Main marketplace screen for product discovery
/// Following AGENTS.md responsive design patterns
class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveUtils.adaptiveValue(
      context,
      mobile: _buildMobileLayout(context),
      tablet: _buildTabletLayout(context),
      desktop: _buildDesktopLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _buildProductGrid(context, crossAxisCount: 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: SafeArea(
        child: Row(
          children: [
            // Sidebar with filters
            Container(
              width: ResponsiveUtils.fluidSize(context, min: 280, max: 320),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceVariant,
                border: Border(
                  right: BorderSide(
                    color: context.colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: _buildFilterSidebar(context),
            ),
            // Main content
            Expanded(
              child: Column(
                children: [
                  _buildHeader(context, showFilters: false),
                  Expanded(
                    child: _buildProductGrid(context, crossAxisCount: 3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: SafeArea(
        child: Row(
          children: [
            // Sidebar with filters
            Container(
              width: ResponsiveUtils.fluidSize(context, min: 320, max: 380),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceVariant,
                border: Border(
                  right: BorderSide(
                    color: context.colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: _buildFilterSidebar(context),
            ),
            // Main content
            Expanded(
              child: Column(
                children: [
                  _buildHeader(context, showFilters: false),
                  Expanded(
                    child: _buildProductGrid(context, crossAxisCount: 4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {bool showFilters = true}) {
    return Container(
      padding: DesignTokens.lg(context).all,
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          const MarketplaceSearchBar(),
          
          SizedBox(height: DesignTokens.md(context).height),
          
          // Categories row
          _buildCategoriesRow(context),
          
          if (showFilters) ...[
            SizedBox(height: DesignTokens.md(context).height),
            _buildFilterRow(context),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoriesRow(BuildContext context) {
    return GetBuilder<MarketplaceController>(
      builder: (controller) {
        if (controller.categories.isEmpty) {
          return _buildCategoriesLoading(context);
        }

        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: controller.categories.length + 1,
            separatorBuilder: (context, index) => SizedBox(width: DesignTokens.sm(context).width),
            itemBuilder: (context, index) {
              if (index == 0) {
                return CategoryChip(
                  label: 'All',
                  isSelected: controller.selectedCategory == null,
                  onTap: () => controller.filterByCategory(null),
                );
              }

              final category = controller.categories[index - 1];
              return CategoryChip(
                label: category.name,
                isSelected: controller.selectedCategory?.id == category.id,
                onTap: () => controller.filterByCategory(category),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoriesLoading(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        separatorBuilder: (context, index) => SizedBox(width: DesignTokens.sm(context).width),
        itemBuilder: (context, index) {
          return SkeletonLoader(
            width: 80,
            height: 32,
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm(context)),
          );
        },
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context) {
    return GetBuilder<MarketplaceController>(
      builder: (controller) {
        return Row(
          children: [
            // Filter button
            OutlinedButton.icon(
              onPressed: () => _showFilterBottomSheet(context),
              icon: Icon(
                Icons.filter_list,
                size: DesignTokens.iconSm(context),
              ),
              label: const Text('Filters'),
              style: OutlinedButton.styleFrom(
                padding: DesignTokens.sm(context).all,
              ),
            ),
            
            SizedBox(width: DesignTokens.sm(context).width),
            
            // Sort button
            OutlinedButton.icon(
              onPressed: () => _showSortBottomSheet(context),
              icon: Icon(
                Icons.sort,
                size: DesignTokens.iconSm(context),
              ),
              label: Text(controller.getSortDisplayName(controller.sortBy)),
              style: OutlinedButton.styleFrom(
                padding: DesignTokens.sm(context).all,
              ),
            ),
            
            const Spacer(),
            
            // Results count
            Obx(() => Text(
              '${controller.products.length} products',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurface.withOpacity(0.7),
              ),
            )),
          ],
        );
      },
    );
  }

  Widget _buildFilterSidebar(BuildContext context) {
    return const FilterSidebar();
  }

  Widget _buildProductGrid(BuildContext context, {required int crossAxisCount}) {
    return GetBuilder<MarketplaceController>(
      builder: (controller) {
        if (controller.isLoading && controller.products.isEmpty) {
          return _buildLoadingGrid(context, crossAxisCount: crossAxisCount);
        }

        if (controller.products.isEmpty) {
          return _buildEmptyState(context);
        }

        return OptimizedListView(
          padding: DesignTokens.lg(context).all,
          itemCount: controller.products.length,
          onLoadMore: () => controller.loadMoreProducts(),
          itemBuilder: (context, index) {
            return ProductCard(
              product: controller.products[index],
              onTap: () => _navigateToProductDetail(controller.products[index].id!),
            );
          },
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.75,
            crossAxisSpacing: DesignTokens.md(context).width,
            mainAxisSpacing: DesignTokens.md(context).height,
          ),
        );
      },
    );
  }

  Widget _buildLoadingGrid(BuildContext context, {required int crossAxisCount}) {
    return Padding(
      padding: DesignTokens.lg(context).all,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.75,
          crossAxisSpacing: DesignTokens.md(context).width,
          mainAxisSpacing: DesignTokens.md(context).height,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          return SkeletonLoader(
            height: double.infinity,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: DesignTokens.xl(context).all,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: DesignTokens.iconXl(context) * 2,
              color: context.colorScheme.outline,
            ),
            
            SizedBox(height: DesignTokens.lg(context).height),
            
            Text(
              'No products found',
              style: context.textTheme.headlineSmall?.copyWith(
                color: context.colorScheme.onSurface,
              ),
            ),
            
            SizedBox(height: DesignTokens.sm(context).height),
            
            Text(
              'Try adjusting your filters or search terms',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: DesignTokens.lg(context).height),
            
            GetBuilder<MarketplaceController>(
              builder: (controller) {
                return ElevatedButton(
                  onPressed: () => controller.clearFilters(),
                  child: const Text('Clear Filters'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const SortBottomSheet(),
    );
  }

  void _navigateToProductDetail(String productId) {
    Get.toNamed('/marketplace/product/$productId');
  }
}

/// Filter sidebar for tablet and desktop layouts
class FilterSidebar extends StatelessWidget {
  const FilterSidebar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: DesignTokens.lg(context).all,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: context.textTheme.titleLarge?.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: DesignTokens.lg(context).height),
          
          // Price range filter
          _buildPriceRangeFilter(context),
          
          SizedBox(height: DesignTokens.lg(context).height),
          
          // Featured toggle
          _buildFeaturedToggle(context),
          
          const Spacer(),
          
          // Clear filters button
          GetBuilder<MarketplaceController>(
            builder: (controller) {
              return SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => controller.clearFilters(),
                  child: const Text('Clear All Filters'),
                ),
              );
            },
          ),
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
                  style: context.textTheme.bodySmall,
                ),
                Text(
                  '\$${controller.priceRange[1].round()}',
                  style: context.textTheme.bodySmall,
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
}