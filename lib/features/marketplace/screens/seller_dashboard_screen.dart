import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design_tokens.dart';
import '../../../core/responsive_utils.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../controllers/seller_dashboard_controller.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/product_list_tile.dart';
import '../widgets/order_list_tile.dart';
import '../widgets/create_store_form.dart';

/// Seller dashboard screen for store and product management
class SellerDashboardScreen extends StatelessWidget {
  const SellerDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SellerDashboardController>(
      init: SellerDashboardController(),
      builder: (controller) {
        if (controller.isLoading) {
          return _buildLoadingState(context);
        }

        if (!controller.hasStore) {
          return _buildCreateStoreScreen(context, controller);
        }

        return ResponsiveUtils.adaptiveValue(
          context,
          mobile: _buildMobileLayout(context, controller),
          tablet: _buildTabletLayout(context, controller),
          desktop: _buildDesktopLayout(context, controller),
        );
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: DesignTokens.lg(context).all,
          child: Column(
            children: [
              // Header skeleton
              SkeletonLoader(
                height: 60,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
              ),
              
              SizedBox(height: DesignTokens.lg(context).height),
              
              // Stats cards skeleton
              Row(
                children: List.generate(2, (index) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == 0 ? DesignTokens.md(context).width : 0,
                    ),
                    child: SkeletonLoader(
                      height: 100,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
                    ),
                  ),
                )),
              ),
              
              SizedBox(height: DesignTokens.lg(context).height),
              
              // Content skeleton
              Expanded(
                child: SkeletonLoader(
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateStoreScreen(BuildContext context, SellerDashboardController controller) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Create Your Store'),
        backgroundColor: context.colorScheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: DesignTokens.lg(context).all,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Text(
                'Welcome to StarChat Marketplace!',
                style: context.textTheme.headlineMedium?.copyWith(
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              SizedBox(height: DesignTokens.md(context).height),
              
              Text(
                'Create your store to start selling products to the StarChat community.',
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              
              SizedBox(height: DesignTokens.xl(context).height),
              
              // Create store form
              CreateStoreForm(controller: controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, SellerDashboardController controller) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        appBar: AppBar(
          title: Text(controller.store?.storeName ?? 'My Store'),
          backgroundColor: context.colorScheme.surface,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () => _showStoreMenu(context, controller),
              icon: const Icon(Icons.more_vert),
            ),
          ],
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
              Tab(text: 'Products', icon: Icon(Icons.inventory)),
              Tab(text: 'Orders', icon: Icon(Icons.shopping_bag)),
              Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
            ],
            onTap: (index) => controller.changeTab(index),
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(context, controller),
            _buildProductsTab(context, controller),
            _buildOrdersTab(context, controller),
            _buildAnalyticsTab(context, controller),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(context, controller),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, SellerDashboardController controller) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: SafeArea(
        child: Row(
          children: [
            // Sidebar navigation
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
              child: _buildNavigationSidebar(context, controller),
            ),
            // Main content
            Expanded(
              child: Column(
                children: [
                  _buildHeader(context, controller),
                  Expanded(
                    child: _buildTabContent(context, controller),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, SellerDashboardController controller) {
    return _buildTabletLayout(context, controller); // Same as tablet for now
  }

  Widget _buildHeader(BuildContext context, SellerDashboardController controller) {
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
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.store?.storeName ?? 'My Store',
                style: context.textTheme.headlineSmall?.copyWith(
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              SizedBox(height: DesignTokens.xs(context).height),
              
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.sm(context).left,
                      vertical: DesignTokens.xs(context).top,
                    ),
                    decoration: BoxDecoration(
                      color: controller.getStoreStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSm(context)),
                      border: Border.all(
                        color: controller.getStoreStatusColor(),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      controller.getStoreStatus(),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: controller.getStoreStatusColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const Spacer(),
          
          // Action buttons
          Row(
            children: [
              IconButton(
                onPressed: () => controller.refresh(),
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
              
              SizedBox(width: DesignTokens.sm(context).width),
              
              IconButton(
                onPressed: () => _showStoreMenu(context, controller),
                icon: const Icon(Icons.settings),
                tooltip: 'Store Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationSidebar(BuildContext context, SellerDashboardController controller) {
    return Column(
      children: [
        // Store info
        Container(
          padding: DesignTokens.lg(context).all,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: context.colorScheme.primary,
                child: Text(
                  controller.store?.storeName.substring(0, 1).toUpperCase() ?? 'S',
                  style: context.textTheme.headlineSmall?.copyWith(
                    color: context.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              SizedBox(height: DesignTokens.md(context).height),
              
              Text(
                controller.store?.storeName ?? 'My Store',
                style: context.textTheme.titleMedium?.copyWith(
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              SizedBox(height: DesignTokens.xs(context).height),
              
              Text(
                controller.getStoreStatus(),
                style: context.textTheme.bodySmall?.copyWith(
                  color: controller.getStoreStatusColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        
        // Navigation items
        Expanded(
          child: ListView(
            children: [
              _buildNavItem(
                context,
                icon: Icons.dashboard,
                label: 'Overview',
                isSelected: controller.selectedTabIndex == 0,
                onTap: () => controller.changeTab(0),
              ),
              _buildNavItem(
                context,
                icon: Icons.inventory,
                label: 'Products',
                isSelected: controller.selectedTabIndex == 1,
                onTap: () => controller.changeTab(1),
              ),
              _buildNavItem(
                context,
                icon: Icons.shopping_bag,
                label: 'Orders',
                isSelected: controller.selectedTabIndex == 2,
                onTap: () => controller.changeTab(2),
              ),
              _buildNavItem(
                context,
                icon: Icons.analytics,
                label: 'Analytics',
                isSelected: controller.selectedTabIndex == 3,
                onTap: () => controller.changeTab(3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected 
            ? context.colorScheme.primary
            : context.colorScheme.onSurface.withOpacity(0.6),
      ),
      title: Text(
        label,
        style: context.textTheme.bodyMedium?.copyWith(
          color: isSelected 
              ? context.colorScheme.primary
              : context.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: context.colorScheme.primary.withOpacity(0.1),
      onTap: onTap,
    );
  }

  Widget _buildTabContent(BuildContext context, SellerDashboardController controller) {
    switch (controller.selectedTabIndex) {
      case 0:
        return _buildOverviewTab(context, controller);
      case 1:
        return _buildProductsTab(context, controller);
      case 2:
        return _buildOrdersTab(context, controller);
      case 3:
        return _buildAnalyticsTab(context, controller);
      default:
        return _buildOverviewTab(context, controller);
    }
  }

  Widget _buildOverviewTab(BuildContext context, SellerDashboardController controller) {
    final summary = controller.getDashboardSummary();
    
    return SingleChildScrollView(
      padding: DesignTokens.lg(context).all,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats cards
          ResponsiveUtils.adaptiveValue(
            context,
            mobile: _buildStatsGridMobile(context, summary),
            tablet: _buildStatsGridTablet(context, summary),
            desktop: _buildStatsGridDesktop(context, summary),
          ),
          
          SizedBox(height: DesignTokens.xl(context).height),
          
          // Quick actions
          _buildQuickActions(context, controller),
          
          SizedBox(height: DesignTokens.xl(context).height),
          
          // Recent activity
          _buildRecentActivity(context, controller),
        ],
      ),
    );
  }

  Widget _buildStatsGridMobile(BuildContext context, Map<String, dynamic> summary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DashboardStatCard(
                title: 'Products',
                value: '${summary['totalProducts']}',
                subtitle: '${summary['activeProducts']} active',
                icon: Icons.inventory,
                color: context.colorScheme.primary,
              ),
            ),
            
            SizedBox(width: DesignTokens.md(context).width),
            
            Expanded(
              child: DashboardStatCard(
                title: 'Orders',
                value: '${summary['totalOrders']}',
                subtitle: '${summary['pendingOrders']} pending',
                icon: Icons.shopping_bag,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        
        SizedBox(height: DesignTokens.md(context).height),
        
        Row(
          children: [
            Expanded(
              child: DashboardStatCard(
                title: 'Revenue',
                value: '\$${summary['totalRevenue'].toStringAsFixed(0)}',
                subtitle: 'This month',
                icon: Icons.attach_money,
                color: Colors.green,
              ),
            ),
            
            SizedBox(width: DesignTokens.md(context).width),
            
            Expanded(
              child: DashboardStatCard(
                title: 'Rating',
                value: '${summary['averageRating'].toStringAsFixed(1)}',
                subtitle: '${summary['totalSales']} sales',
                icon: Icons.star,
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGridTablet(BuildContext context, Map<String, dynamic> summary) {
    return Row(
      children: [
        Expanded(
          child: DashboardStatCard(
            title: 'Products',
            value: '${summary['totalProducts']}',
            subtitle: '${summary['activeProducts']} active',
            icon: Icons.inventory,
            color: context.colorScheme.primary,
          ),
        ),
        
        SizedBox(width: DesignTokens.md(context).width),
        
        Expanded(
          child: DashboardStatCard(
            title: 'Orders',
            value: '${summary['totalOrders']}',
            subtitle: '${summary['pendingOrders']} pending',
            icon: Icons.shopping_bag,
            color: Colors.orange,
          ),
        ),
        
        SizedBox(width: DesignTokens.md(context).width),
        
        Expanded(
          child: DashboardStatCard(
            title: 'Revenue',
            value: '\$${summary['totalRevenue'].toStringAsFixed(0)}',
            subtitle: 'This month',
            icon: Icons.attach_money,
            color: Colors.green,
          ),
        ),
        
        SizedBox(width: DesignTokens.md(context).width),
        
        Expanded(
          child: DashboardStatCard(
            title: 'Rating',
            value: '${summary['averageRating'].toStringAsFixed(1)}',
            subtitle: '${summary['totalSales']} sales',
            icon: Icons.star,
            color: Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGridDesktop(BuildContext context, Map<String, dynamic> summary) {
    return _buildStatsGridTablet(context, summary); // Same as tablet
  }

  Widget _buildQuickActions(BuildContext context, SellerDashboardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: context.textTheme.titleLarge?.copyWith(
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        SizedBox(height: DesignTokens.md(context).height),
        
        Wrap(
          spacing: DesignTokens.md(context).width,
          runSpacing: DesignTokens.md(context).height,
          children: [
            _buildActionButton(
              context,
              icon: Icons.add,
              label: 'Add Product',
              onTap: () => _navigateToAddProduct(context),
            ),
            _buildActionButton(
              context,
              icon: Icons.inventory,
              label: 'Manage Stock',
              onTap: () => controller.changeTab(1),
            ),
            _buildActionButton(
              context,
              icon: Icons.local_offer,
              label: 'Create Promotion',
              onTap: () => _showComingSoon(context),
            ),
            _buildActionButton(
              context,
              icon: Icons.settings,
              label: 'Store Settings',
              onTap: () => _showStoreSettings(context, controller),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: ResponsiveUtils.adaptiveValue(
        context,
        mobile: (MediaQuery.of(context).size.width - DesignTokens.lg(context).left * 2 - DesignTokens.md(context).width) / 2,
        tablet: 150.0,
        desktop: 150.0,
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: DesignTokens.md(context).all,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, SellerDashboardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: context.textTheme.titleLarge?.copyWith(
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        SizedBox(height: DesignTokens.md(context).height),
        
        // Low stock alerts
        if (controller.lowStockProducts.isNotEmpty) ...[
          Container(
            padding: DesignTokens.md(context).all,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: DesignTokens.sm(context).width),
                    Text(
                      'Low Stock Alert',
                      style: context.textTheme.titleMedium?.copyWith(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: DesignTokens.sm(context).height),
                
                Text(
                  '${controller.lowStockProducts.length} products are running low on stock',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                
                SizedBox(height: DesignTokens.sm(context).height),
                
                TextButton(
                  onPressed: () => controller.changeTab(1),
                  child: const Text('Manage Inventory'),
                ),
              ],
            ),
          ),
          
          SizedBox(height: DesignTokens.lg(context).height),
        ],
        
        // Recent orders (placeholder)
        Text(
          'Recent Orders',
          style: context.textTheme.titleMedium?.copyWith(
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        SizedBox(height: DesignTokens.sm(context).height),
        
        if (controller.orders.isEmpty)
          Container(
            padding: DesignTokens.lg(context).all,
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
            ),
            child: Center(
              child: Text(
                'No orders yet',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          )
        else
          Column(
            children: controller.getRecentOrders().map((order) {
              return OrderListTile(order: order);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildProductsTab(BuildContext context, SellerDashboardController controller) {
    return Column(
      children: [
        // Products header
        Container(
          padding: DesignTokens.lg(context).all,
          child: Row(
            children: [
              Text(
                'Products (${controller.products.length})',
                style: context.textTheme.titleLarge?.copyWith(
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const Spacer(),
              
              ElevatedButton.icon(
                onPressed: () => _navigateToAddProduct(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
              ),
            ],
          ),
        ),
        
        // Products list
        Expanded(
          child: controller.products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory,
                        size: DesignTokens.iconXl(context) * 2,
                        color: context.colorScheme.outline,
                      ),
                      
                      SizedBox(height: DesignTokens.lg(context).height),
                      
                      Text(
                        'No products yet',
                        style: context.textTheme.headlineSmall?.copyWith(
                          color: context.colorScheme.onSurface,
                        ),
                      ),
                      
                      SizedBox(height: DesignTokens.sm(context).height),
                      
                      Text(
                        'Add your first product to start selling',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      
                      SizedBox(height: DesignTokens.lg(context).height),
                      
                      ElevatedButton.icon(
                        onPressed: () => _navigateToAddProduct(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Product'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: DesignTokens.lg(context).all,
                  itemCount: controller.products.length,
                  separatorBuilder: (context, index) => 
                      SizedBox(height: DesignTokens.sm(context).height),
                  itemBuilder: (context, index) {
                    final product = controller.products[index];
                    return ProductListTile(
                      product: product,
                      onEdit: () => _navigateToEditProduct(context, product),
                      onDelete: () => _showDeleteConfirmation(context, controller, product),
                      onUpdateStock: (newStock) => 
                          controller.updateProductStock(product.id!, newStock),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildOrdersTab(BuildContext context, SellerDashboardController controller) {
    return Column(
      children: [
        // Orders header
        Container(
          padding: DesignTokens.lg(context).all,
          child: Row(
            children: [
              Text(
                'Orders (${controller.orders.length})',
                style: context.textTheme.titleLarge?.copyWith(
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Orders list
        Expanded(
          child: controller.orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag,
                        size: DesignTokens.iconXl(context) * 2,
                        color: context.colorScheme.outline,
                      ),
                      
                      SizedBox(height: DesignTokens.lg(context).height),
                      
                      Text(
                        'No orders yet',
                        style: context.textTheme.headlineSmall?.copyWith(
                          color: context.colorScheme.onSurface,
                        ),
                      ),
                      
                      SizedBox(height: DesignTokens.sm(context).height),
                      
                      Text(
                        'Orders will appear here when customers make purchases',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: DesignTokens.lg(context).all,
                  itemCount: controller.orders.length,
                  separatorBuilder: (context, index) => 
                      SizedBox(height: DesignTokens.sm(context).height),
                  itemBuilder: (context, index) {
                    final order = controller.orders[index];
                    return OrderListTile(order: order);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab(BuildContext context, SellerDashboardController controller) {
    return SingleChildScrollView(
      padding: DesignTokens.lg(context).all,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics',
            style: context.textTheme.titleLarge?.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: DesignTokens.lg(context).height),
          
          // Analytics content (placeholder)
          Container(
            width: double.infinity,
            padding: DesignTokens.xl(context).all,
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.analytics,
                  size: DesignTokens.iconXl(context) * 2,
                  color: context.colorScheme.outline,
                ),
                
                SizedBox(height: DesignTokens.lg(context).height),
                
                Text(
                  'Analytics Coming Soon',
                  style: context.textTheme.headlineSmall?.copyWith(
                    color: context.colorScheme.onSurface,
                  ),
                ),
                
                SizedBox(height: DesignTokens.sm(context).height),
                
                Text(
                  'Detailed analytics and insights will be available soon',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context, SellerDashboardController controller) {
    if (controller.selectedTabIndex == 1) {
      return FloatingActionButton(
        onPressed: () => _navigateToAddProduct(context),
        child: const Icon(Icons.add),
        tooltip: 'Add Product',
      );
    }
    return null;
  }

  void _showStoreMenu(BuildContext context, SellerDashboardController controller) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: DesignTokens.lg(context).all,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Store Settings'),
              onTap: () {
                Get.back();
                _showStoreSettings(context, controller);
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh Data'),
              onTap: () {
                Get.back();
                controller.refresh();
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Support'),
              onTap: () {
                Get.back();
                _showComingSoon(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStoreSettings(BuildContext context, SellerDashboardController controller) {
    _showComingSoon(context);
  }

  void _navigateToAddProduct(BuildContext context) {
    _showComingSoon(context);
  }

  void _navigateToEditProduct(BuildContext context, Product product) {
    _showComingSoon(context);
  }

  void _showDeleteConfirmation(
    BuildContext context,
    SellerDashboardController controller,
    Product product,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteProduct(product.id!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.error,
              foregroundColor: context.colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    Get.snackbar(
      'Coming Soon',
      'This feature will be available in a future update',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}