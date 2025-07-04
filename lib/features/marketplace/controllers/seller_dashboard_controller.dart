import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import '../models/marketplace_models.dart';
import '../services/marketplace_service.dart';
import '../services/product_service.dart';

// Mock AuthController for compilation - replace with actual controller
class AuthController extends GetxController {
  final currentUser = Rxn<User>();
}

class User {
  final String userId;
  User({required this.userId});
}

/// Seller dashboard controller for managing store and products
class SellerDashboardController extends GetxController {
  final MarketplaceService _marketplaceService = Get.find<MarketplaceService>();
  final ProductService _productService = Get.find<ProductService>();
  final Logger logger = Logger();

  // Reactive observables following AGENTS.md patterns
  final _isLoading = false.obs;
  final _store = Rxn<MarketplaceStore>();
  final _products = <Product>[].obs;
  final _orders = <Order>[].obs;
  final _analytics = <String, dynamic>{}.obs;
  final _selectedTabIndex = 0.obs;
  final _isCreatingStore = false.obs;
  final _lowStockProducts = <Product>[].obs;

  // Getters
  bool get isLoading => _isLoading.value;
  MarketplaceStore? get store => _store.value;
  List<Product> get products => _products;
  List<Order> get orders => _orders;
  Map<String, dynamic> get analytics => _analytics;
  int get selectedTabIndex => _selectedTabIndex.value;
  bool get isCreatingStore => _isCreatingStore.value;
  List<Product> get lowStockProducts => _lowStockProducts;
  bool get hasStore => _store.value != null;

  @override
  void onInit() {
    super.onInit();
    _initializeDashboard();
  }

  /// Initialize seller dashboard
  Future<void> _initializeDashboard() async {
    final authController = Get.find<AuthController>();
    if (authController.currentUser.value == null) return;

    _isLoading.value = true;
    try {
      await loadStore(authController.currentUser.value!.userId);
      if (hasStore) {
        await Future.wait([
          loadProducts(),
          loadOrders(),
          loadAnalytics(),
        ]);
      }
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load seller's store
  Future<void> loadStore(String sellerId) async {
    try {
      final store = await _marketplaceService.getStoreByUserId(sellerId);
      _store.value = store;
      logger.i('Store loaded: ${store?.storeName ?? 'No store found'}');
    } catch (e) {
      logger.e('Failed to load store', error: e);
    }
  }

  /// Create new store
  Future<bool> createStore({
    required String storeName,
    required String businessEmail,
    String? storeDescription,
    String? businessPhone,
    String? businessAddress,
  }) async {
    final authController = Get.find<AuthController>();
    if (authController.currentUser.value == null) return false;

    _isCreatingStore.value = true;
    try {
      final newStore = MarketplaceStore(
        sellerId: authController.currentUser.value!.userId,
        storeName: storeName,
        storeDescription: storeDescription,
        businessEmail: businessEmail,
        businessPhone: businessPhone,
        businessAddress: businessAddress,
      );

      final createdStore = await _marketplaceService.createStore(newStore);
      if (createdStore != null) {
        _store.value = createdStore;
        
        Get.snackbar(
          'Store Created',
          'Your marketplace store has been created successfully!',
          snackPosition: SnackPosition.BOTTOM,
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      logger.e('Failed to create store', error: e);
      Get.snackbar(
        'Error',
        'Failed to create store. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      _isCreatingStore.value = false;
    }
  }

  /// Update store information
  Future<bool> updateStore(Map<String, dynamic> updates) async {
    if (_store.value == null) return false;

    try {
      final updatedStore = await _marketplaceService.updateStore(
        _store.value!.id!,
        updates,
      );
      
      if (updatedStore != null) {
        _store.value = updatedStore;
        
        Get.snackbar(
          'Store Updated',
          'Your store information has been updated',
          snackPosition: SnackPosition.BOTTOM,
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      logger.e('Failed to update store', error: e);
      return false;
    }
  }

  /// Load seller's products
  Future<void> loadProducts() async {
    if (_store.value == null) return;

    try {
      final products = await _productService.getProductsBySeller(
        _store.value!.sellerId,
        limit: 100,
      );
      
      _products.assignAll(products);
      
      // Filter low stock products
      _lowStockProducts.assignAll(
        products.where((p) => p.isLowStock).toList(),
      );
      
      logger.i('Loaded ${products.length} products (${_lowStockProducts.length} low stock)');
    } catch (e) {
      logger.e('Failed to load products', error: e);
    }
  }

  /// Load seller's orders
  Future<void> loadOrders() async {
    if (_store.value == null) return;

    try {
      // TODO: Implement order service to get seller's orders
      // For now, using empty list
      _orders.clear();
      logger.i('Loaded ${_orders.length} orders');
    } catch (e) {
      logger.e('Failed to load orders', error: e);
    }
  }

  /// Load store analytics
  Future<void> loadAnalytics() async {
    if (_store.value == null) return;

    try {
      final analytics = await _marketplaceService.getStoreAnalytics(
        _store.value!.id!,
      );
      
      _analytics.assignAll(analytics);
      logger.i('Analytics loaded');
    } catch (e) {
      logger.e('Failed to load analytics', error: e);
    }
  }

  /// Add new product
  Future<bool> addProduct(Product product) async {
    if (_store.value == null) return false;

    try {
      final newProduct = product.copyWith(
        sellerId: _store.value!.sellerId,
        storeId: _store.value!.id!,
      );

      final createdProduct = await _productService.createProduct(newProduct);
      if (createdProduct != null) {
        _products.insert(0, createdProduct);
        
        // Update store product count
        await _updateStoreProductCount();
        
        Get.snackbar(
          'Product Added',
          '${product.title} has been added to your store',
          snackPosition: SnackPosition.BOTTOM,
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      logger.e('Failed to add product', error: e);
      return false;
    }
  }

  /// Update product
  Future<bool> updateProduct(String productId, Map<String, dynamic> updates) async {
    try {
      final updatedProduct = await _productService.updateProduct(productId, updates);
      if (updatedProduct != null) {
        final index = _products.indexWhere((p) => p.id == productId);
        if (index >= 0) {
          _products[index] = updatedProduct;
        }
        
        Get.snackbar(
          'Product Updated',
          'Product has been updated successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      logger.e('Failed to update product', error: e);
      return false;
    }
  }

  /// Delete product
  Future<bool> deleteProduct(String productId) async {
    try {
      final success = await _productService.deleteProduct(productId);
      if (success) {
        _products.removeWhere((p) => p.id == productId);
        _lowStockProducts.removeWhere((p) => p.id == productId);
        
        // Update store product count
        await _updateStoreProductCount();
        
        Get.snackbar(
          'Product Deleted',
          'Product has been removed from your store',
          snackPosition: SnackPosition.BOTTOM,
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      logger.e('Failed to delete product', error: e);
      return false;
    }
  }

  /// Update product stock
  Future<bool> updateProductStock(String productId, int newQuantity) async {
    try {
      final success = await _productService.updateStock(productId, newQuantity);
      if (success) {
        final index = _products.indexWhere((p) => p.id == productId);
        if (index >= 0) {
          _products[index] = _products[index].copyWith(stockQuantity: newQuantity);
          
          // Update low stock list
          final product = _products[index];
          if (product.isLowStock && !_lowStockProducts.contains(product)) {
            _lowStockProducts.add(product);
          } else if (!product.isLowStock) {
            _lowStockProducts.removeWhere((p) => p.id == productId);
          }
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      logger.e('Failed to update stock', error: e);
      return false;
    }
  }

  /// Change selected tab
  void changeTab(int index) {
    _selectedTabIndex.value = index;
  }

  /// Get dashboard summary
  Map<String, dynamic> getDashboardSummary() {
    return {
      'totalProducts': _products.length,
      'activeProducts': _products.where((p) => p.isActive).length,
      'lowStockProducts': _lowStockProducts.length,
      'totalOrders': _orders.length,
      'pendingOrders': _orders.where((o) => o.status == OrderStatus.pending).length,
      'totalRevenue': _analytics['revenue'] ?? 0.0,
      'averageRating': _store.value?.averageRating ?? 0.0,
      'totalSales': _store.value?.totalSales ?? 0,
    };
  }

  /// Get recent orders
  List<Order> getRecentOrders({int limit = 5}) {
    final sortedOrders = List<Order>.from(_orders)
      ..sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
    
    return sortedOrders.take(limit).toList();
  }

  /// Get top selling products
  List<Product> getTopSellingProducts({int limit = 5}) {
    final sortedProducts = List<Product>.from(_products)
      ..sort((a, b) => b.salesCount.compareTo(a.salesCount));
    
    return sortedProducts.take(limit).toList();
  }

  /// Update store product count
  Future<void> _updateStoreProductCount() async {
    if (_store.value == null) return;

    try {
      await _marketplaceService.updateStore(
        _store.value!.id!,
        {'total_products': _products.length},
      );
    } catch (e) {
      logger.w('Failed to update store product count');
    }
  }

  /// Refresh dashboard data
  Future<void> refresh() async {
    await _initializeDashboard();
  }

  /// Subscribe to store updates
  void subscribeToStoreUpdates() {
    if (_store.value?.id != null) {
      _marketplaceService.subscribeToStoreUpdates(_store.value!.id!).listen(
        (updatedStore) {
          _store.value = updatedStore;
        },
        onError: (error) {
          logger.e('Store subscription error', error: error);
        },
      );
    }
  }

  /// Get store status
  String getStoreStatus() {
    if (_store.value == null) return 'No Store';
    if (!_store.value!.isActive) return 'Inactive';
    if (!_store.value!.isVerified) return 'Pending Verification';
    return 'Active';
  }

  /// Get store status color
  Color getStoreStatusColor() {
    final status = getStoreStatus();
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Pending Verification':
        return Colors.orange;
      case 'Inactive':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Check if product can be deleted
  bool canDeleteProduct(Product product) {
    // Can't delete if product has active orders
    return !_orders.any((order) => 
      order.items.any((item) => item.productId == product.id));
  }

  /// Get product performance metrics
  Map<String, dynamic> getProductMetrics(Product product) {
    return {
      'views': product.viewCount,
      'sales': product.salesCount,
      'rating': product.averageRating,
      'reviews': product.reviewCount,
      'conversionRate': product.viewCount > 0 
          ? (product.salesCount / product.viewCount * 100).toStringAsFixed(1)
          : '0.0',
    };
  }
}