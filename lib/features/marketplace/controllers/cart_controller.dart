import 'package:get/get.dart';
import 'package:logger/logger.dart';

import '../models/marketplace_models.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';

// Mock AuthController for compilation - replace with actual controller
class AuthController extends GetxController {
  final currentUser = Rxn<User>();
}

class User {
  final String userId;
  User({required this.userId});
}

/// Shopping cart controller following GetX reactive patterns
class CartController extends GetxController {
  final CartService _cartService = Get.find<CartService>();
  final ProductService _productService = Get.find<ProductService>();
  final Logger logger = Logger();

  // Reactive observables following AGENTS.md patterns
  final _isLoading = false.obs;
  final _cart = Rxn<ShoppingCart>();
  final _cartItems = <CartItem>[].obs;
  final _itemCount = 0.obs;
  final _subtotal = 0.0.obs;
  final _taxAmount = 0.0.obs;
  final _shippingCost = 0.0.obs;
  final _total = 0.0.obs;
  final _isValidating = false.obs;
  final _validationErrors = <String>[].obs;
  final _validationWarnings = <String>[].obs;

  // Getters
  bool get isLoading => _isLoading.value;
  ShoppingCart? get cart => _cart.value;
  List<CartItem> get cartItems => _cartItems;
  int get itemCount => _itemCount.value;
  double get subtotal => _subtotal.value;
  double get taxAmount => _taxAmount.value;
  double get shippingCost => _shippingCost.value;
  double get total => _total.value;
  bool get isValidating => _isValidating.value;
  List<String> get validationErrors => _validationErrors;
  List<String> get validationWarnings => _validationWarnings;
  bool get isEmpty => _cartItems.isEmpty;
  bool get isValid => _validationErrors.isEmpty;

  // Tax rate (could be dynamic based on location)
  final double taxRate = 0.08; // 8%

  @override
  void onInit() {
    super.onInit();
    _loadUserCart();
  }

  /// Load user's cart
  Future<void> _loadUserCart() async {
    final authController = Get.find<AuthController>();
    if (authController.currentUser.value == null) return;

    _isLoading.value = true;
    try {
      final cart = await _cartService.getUserCart(
        authController.currentUser.value!.userId,
      );
      
      if (cart != null) {
        _cart.value = cart;
        _cartItems.assignAll(cart.items);
        await _updateCartTotals();
      }
      
      logger.i('Cart loaded with ${_cartItems.length} items');
    } catch (e) {
      logger.e('Failed to load cart', error: e);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Add product to cart
  Future<bool> addToCart(Product product, {int quantity = 1}) async {
    final authController = Get.find<AuthController>();
    if (authController.currentUser.value == null) {
      Get.snackbar(
        'Sign In Required',
        'Please sign in to add items to cart',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    // Check if product is available
    if (!product.isInStock) {
      Get.snackbar(
        'Out of Stock',
        '${product.title} is currently out of stock',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    // Check if requested quantity is available
    if (product.trackInventory && product.stockQuantity < quantity) {
      Get.snackbar(
        'Insufficient Stock',
        'Only ${product.stockQuantity} units available',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      final cartItem = await _cartService.addToCart(
        userId: authController.currentUser.value!.userId,
        productId: product.id!,
        unitPrice: product.price,
        quantity: quantity,
      );

      if (cartItem != null) {
        // Reload cart to get updated data
        await _loadUserCart();
        
        Get.snackbar(
          'Added to Cart',
          '${product.title} added to your cart',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      logger.e('Failed to add to cart', error: e);
      Get.snackbar(
        'Error',
        'Failed to add item to cart',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Update cart item quantity
  Future<bool> updateQuantity(CartItem item, int newQuantity) async {
    if (newQuantity <= 0) {
      return await removeFromCart(item);
    }

    try {
      // Check stock availability
      final product = await _productService.getProduct(item.productId);
      if (product != null && product.trackInventory && product.stockQuantity < newQuantity) {
        Get.snackbar(
          'Insufficient Stock',
          'Only ${product.stockQuantity} units available',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      final updatedItem = await _cartService.updateCartItemQuantity(
        cartItemId: item.id!,
        quantity: newQuantity,
        unitPrice: item.unitPrice,
      );

      if (updatedItem != null) {
        // Update local cart item
        final index = _cartItems.indexWhere((i) => i.id == item.id);
        if (index >= 0) {
          _cartItems[index] = updatedItem;
          await _updateCartTotals();
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      logger.e('Failed to update quantity', error: e);
      Get.snackbar(
        'Error',
        'Failed to update quantity',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Remove item from cart
  Future<bool> removeFromCart(CartItem item) async {
    try {
      final success = await _cartService.removeFromCart(item.id!);
      
      if (success) {
        _cartItems.removeWhere((i) => i.id == item.id);
        await _updateCartTotals();
        
        Get.snackbar(
          'Removed',
          'Item removed from cart',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      logger.e('Failed to remove from cart', error: e);
      Get.snackbar(
        'Error',
        'Failed to remove item',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Clear entire cart
  Future<bool> clearCart() async {
    if (_cart.value == null) return false;

    try {
      final success = await _cartService.clearCart(_cart.value!.id!);
      
      if (success) {
        _cartItems.clear();
        await _updateCartTotals();
        
        Get.snackbar(
          'Cart Cleared',
          'All items removed from cart',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      logger.e('Failed to clear cart', error: e);
      Get.snackbar(
        'Error',
        'Failed to clear cart',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Update cart totals
  Future<void> _updateCartTotals() async {
    if (_cart.value == null) return;

    try {
      final totals = await _cartService.calculateCartTotal(
        cartId: _cart.value!.id!,
        taxRate: taxRate,
        shippingCost: _calculateShipping(),
      );

      _subtotal.value = totals['subtotal'] ?? 0.0;
      _taxAmount.value = totals['tax_amount'] ?? 0.0;
      _shippingCost.value = totals['shipping_cost'] ?? 0.0;
      _total.value = totals['total'] ?? 0.0;
      _itemCount.value = _cartItems.fold(0, (sum, item) => sum + item.quantity);
      
      logger.d('Cart totals updated: ${_itemCount.value} items, \$${_total.value.toStringAsFixed(2)}');
    } catch (e) {
      logger.e('Failed to update cart totals', error: e);
    }
  }

  /// Calculate shipping cost (basic implementation)
  double _calculateShipping() {
    if (_subtotal.value >= 50.0) {
      return 0.0; // Free shipping over $50
    } else if (_subtotal.value > 0) {
      return 5.99; // Standard shipping
    }
    return 0.0;
  }

  /// Validate cart before checkout
  Future<bool> validateCart() async {
    if (_cart.value == null) return false;

    _isValidating.value = true;
    _validationErrors.clear();
    _validationWarnings.clear();

    try {
      final validation = await _cartService.validateCart(_cart.value!.id!);
      
      _validationErrors.assignAll(validation['errors'] ?? []);
      _validationWarnings.assignAll(validation['warnings'] ?? []);
      
      logger.i('Cart validation: ${validation['isValid']} (${_validationErrors.length} errors, ${_validationWarnings.length} warnings)');
      
      return validation['isValid'] ?? false;
    } catch (e) {
      logger.e('Failed to validate cart', error: e);
      _validationErrors.add('Unable to validate cart');
      return false;
    } finally {
      _isValidating.value = false;
    }
  }

  /// Get cart item by product ID
  CartItem? getCartItem(String productId) {
    return _cartItems.firstWhereOrNull((item) => item.productId == productId);
  }

  /// Check if product is in cart
  bool isProductInCart(String productId) {
    return getCartItem(productId) != null;
  }

  /// Get quantity of product in cart
  int getProductQuantityInCart(String productId) {
    final item = getCartItem(productId);
    return item?.quantity ?? 0;
  }

  /// Increment product quantity in cart
  Future<bool> incrementQuantity(String productId) async {
    final item = getCartItem(productId);
    if (item != null) {
      return await updateQuantity(item, item.quantity + 1);
    }
    return false;
  }

  /// Decrement product quantity in cart
  Future<bool> decrementQuantity(String productId) async {
    final item = getCartItem(productId);
    if (item != null) {
      return await updateQuantity(item, item.quantity - 1);
    }
    return false;
  }

  /// Get cart summary for display
  Map<String, dynamic> getCartSummary() {
    return {
      'itemCount': _itemCount.value,
      'subtotal': _subtotal.value,
      'taxAmount': _taxAmount.value,
      'shippingCost': _shippingCost.value,
      'total': _total.value,
      'isEmpty': isEmpty,
      'isValid': isValid,
    };
  }

  /// Refresh cart data
  Future<void> refresh() async {
    await _loadUserCart();
  }

  /// Save for later functionality (could be implemented as a separate wishlist)
  Future<bool> saveForLater(CartItem item) async {
    try {
      final authController = Get.find<AuthController>();
      if (authController.currentUser.value == null) return false;

      // Add to wishlist
      final success = await _productService.addToWishlist(
        authController.currentUser.value!.userId,
        item.productId,
      );

      if (success) {
        // Remove from cart
        await removeFromCart(item);
        
        Get.snackbar(
          'Saved for Later',
          'Item moved to your wishlist',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      logger.e('Failed to save for later', error: e);
      return false;
    }
  }

  /// Apply discount code (placeholder for future implementation)
  Future<bool> applyDiscountCode(String code) async {
    // TODO: Implement discount code logic
    Get.snackbar(
      'Feature Coming Soon',
      'Discount codes will be available soon',
      snackPosition: SnackPosition.BOTTOM,
    );
    return false;
  }

  /// Subscribe to cart updates
  void subscribeToCartUpdates() {
    if (_cart.value?.id != null) {
      _cartService.subscribeToCartUpdates(_cart.value!.id!).listen(
        (updatedCart) {
          _cart.value = updatedCart;
          _updateCartTotals();
        },
        onError: (error) {
          logger.e('Cart subscription error', error: error);
        },
      );
    }
  }
}