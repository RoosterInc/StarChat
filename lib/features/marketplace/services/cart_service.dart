import 'package:appwrite/appwrite.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import '../models/marketplace_models.dart';

/// Service for shopping cart management
class CartService extends GetxService {
  final Databases databases;
  final String databaseId;
  final Logger logger = Logger();

  CartService({
    required this.databases,
    required this.databaseId,
  });

  static const String cartsCollection = 'shopping_carts';
  static const String cartItemsCollection = 'cart_items';

  /// Get or create user's shopping cart
  Future<ShoppingCart?> getUserCart(String userId) async {
    try {
      // Try to get existing cart
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: cartsCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.limit(1),
        ],
      );

      if (response.documents.isNotEmpty) {
        final cart = ShoppingCart.fromJson(response.documents.first.data);
        final items = await getCartItems(cart.id!);
        return cart.copyWith(items: items);
      }

      // Create new cart if none exists
      return await createCart(userId);
    } on AppwriteException catch (e) {
      logger.e('Failed to get user cart', error: e);
      return null;
    } catch (e, stackTrace) {
      logger.e('Unexpected error getting cart', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Create a new shopping cart
  Future<ShoppingCart?> createCart(String userId) async {
    try {
      final cart = ShoppingCart(
        userId: userId,
        currency: 'USD',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      final response = await databases.createDocument(
        databaseId: databaseId,
        collectionId: cartsCollection,
        documentId: ID.unique(),
        data: cart.toJson(),
      );

      logger.i('Cart created successfully: ${response.$id}');
      return ShoppingCart.fromJson(response.data);
    } on AppwriteException catch (e) {
      logger.e('Failed to create cart', error: e);
      return null;
    } catch (e, stackTrace) {
      logger.e('Unexpected error creating cart', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get cart items
  Future<List<CartItem>> getCartItems(String cartId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: cartItemsCollection,
        queries: [
          Query.equal('cart_id', cartId),
          Query.orderAsc('\$createdAt'),
          Query.limit(100),
        ],
      );

      return response.documents
          .map((doc) => CartItem.fromJson(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      logger.e('Failed to get cart items', error: e);
      return [];
    } catch (e, stackTrace) {
      logger.e('Unexpected error getting cart items', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Add item to cart
  Future<CartItem?> addToCart({
    required String userId,
    required String productId,
    required double unitPrice,
    int quantity = 1,
    String? variantId,
  }) async {
    try {
      // Get or create user cart
      var cart = await getUserCart(userId);
      if (cart == null) {
        cart = await createCart(userId);
        if (cart == null) return null;
      }

      // Check if item already exists in cart
      final existingItems = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: cartItemsCollection,
        queries: [
          Query.equal('cart_id', cart.id!),
          Query.equal('product_id', productId),
          if (variantId != null) Query.equal('variant_id', variantId),
          Query.limit(1),
        ],
      );

      CartItem? cartItem;

      if (existingItems.documents.isNotEmpty) {
        // Update existing item quantity
        final existingItem = CartItem.fromJson(existingItems.documents.first.data);
        final newQuantity = existingItem.quantity + quantity;
        final newTotalPrice = unitPrice * newQuantity;

        final response = await databases.updateDocument(
          databaseId: databaseId,
          collectionId: cartItemsCollection,
          documentId: existingItems.documents.first.$id,
          data: {
            'quantity': newQuantity,
            'total_price': newTotalPrice,
          },
        );

        cartItem = CartItem.fromJson(response.data);
      } else {
        // Create new cart item
        final newItem = CartItem(
          cartId: cart.id!,
          productId: productId,
          variantId: variantId,
          quantity: quantity,
          unitPrice: unitPrice,
          totalPrice: unitPrice * quantity,
        );

        final response = await databases.createDocument(
          databaseId: databaseId,
          collectionId: cartItemsCollection,
          documentId: ID.unique(),
          data: newItem.toJson(),
        );

        cartItem = CartItem.fromJson(response.data);
      }

      // Update cart totals
      await updateCartTotals(cart.id!);

      logger.i('Item added to cart: $productId');
      return cartItem;
    } on AppwriteException catch (e) {
      logger.e('Failed to add item to cart', error: e);
      Get.snackbar(
        'Error',
        'Failed to add item to cart: ${e.message}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } catch (e, stackTrace) {
      logger.e('Unexpected error adding to cart', error: e, stackTrace: stackTrace);
      Get.snackbar(
        'Error',
        'An unexpected error occurred',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  /// Update cart item quantity
  Future<CartItem?> updateCartItemQuantity({
    required String cartItemId,
    required int quantity,
    required double unitPrice,
  }) async {
    try {
      final totalPrice = unitPrice * quantity;

      final response = await databases.updateDocument(
        databaseId: databaseId,
        collectionId: cartItemsCollection,
        documentId: cartItemId,
        data: {
          'quantity': quantity,
          'total_price': totalPrice,
        },
      );

      final cartItem = CartItem.fromJson(response.data);

      // Update cart totals
      await updateCartTotals(cartItem.cartId);

      logger.i('Cart item quantity updated: $cartItemId -> $quantity');
      return cartItem;
    } on AppwriteException catch (e) {
      logger.e('Failed to update cart item quantity', error: e);
      Get.snackbar(
        'Error',
        'Failed to update quantity: ${e.message}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } catch (e, stackTrace) {
      logger.e('Unexpected error updating quantity', error: e, stackTrace: stackTrace);
      Get.snackbar(
        'Error',
        'An unexpected error occurred',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  /// Remove item from cart
  Future<bool> removeFromCart(String cartItemId) async {
    try {
      // Get cart item first to get cart ID
      final itemResponse = await databases.getDocument(
        databaseId: databaseId,
        collectionId: cartItemsCollection,
        documentId: cartItemId,
      );

      final cartId = itemResponse.data['cart_id'];

      // Delete the cart item
      await databases.deleteDocument(
        databaseId: databaseId,
        collectionId: cartItemsCollection,
        documentId: cartItemId,
      );

      // Update cart totals
      await updateCartTotals(cartId);

      logger.i('Item removed from cart: $cartItemId');
      return true;
    } on AppwriteException catch (e) {
      logger.e('Failed to remove item from cart', error: e);
      Get.snackbar(
        'Error',
        'Failed to remove item: ${e.message}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (e, stackTrace) {
      logger.e('Unexpected error removing from cart', error: e, stackTrace: stackTrace);
      Get.snackbar(
        'Error',
        'An unexpected error occurred',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Clear all items from cart
  Future<bool> clearCart(String cartId) async {
    try {
      // Get all cart items
      final itemsResponse = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: cartItemsCollection,
        queries: [
          Query.equal('cart_id', cartId),
          Query.limit(100),
        ],
      );

      // Delete all items
      for (final item in itemsResponse.documents) {
        await databases.deleteDocument(
          databaseId: databaseId,
          collectionId: cartItemsCollection,
          documentId: item.$id,
        );
      }

      // Update cart totals
      await updateCartTotals(cartId);

      logger.i('Cart cleared: $cartId');
      return true;
    } on AppwriteException catch (e) {
      logger.e('Failed to clear cart', error: e);
      Get.snackbar(
        'Error',
        'Failed to clear cart: ${e.message}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (e, stackTrace) {
      logger.e('Unexpected error clearing cart', error: e, stackTrace: stackTrace);
      Get.snackbar(
        'Error',
        'An unexpected error occurred',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Update cart totals
  Future<void> updateCartTotals(String cartId) async {
    try {
      final items = await getCartItems(cartId);
      
      final totalItems = items.fold<int>(0, (sum, item) => sum + item.quantity);
      final totalAmount = items.fold<double>(0, (sum, item) => sum + item.totalPrice);

      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: cartsCollection,
        documentId: cartId,
        data: {
          'total_items': totalItems,
          'total_amount': totalAmount,
        },
      );

      logger.d('Cart totals updated: $cartId -> $totalItems items, \$${totalAmount.toStringAsFixed(2)}');
    } catch (e) {
      logger.w('Failed to update cart totals for: $cartId');
    }
  }

  /// Get cart item count for user
  Future<int> getCartItemCount(String userId) async {
    try {
      final cart = await getUserCart(userId);
      return cart?.totalItems ?? 0;
    } catch (e) {
      logger.w('Failed to get cart item count for user: $userId');
      return 0;
    }
  }

  /// Calculate cart total with taxes and shipping
  Future<Map<String, double>> calculateCartTotal({
    required String cartId,
    double taxRate = 0.0,
    double shippingCost = 0.0,
  }) async {
    try {
      final cart = await databases.getDocument(
        databaseId: databaseId,
        collectionId: cartsCollection,
        documentId: cartId,
      );

      final subtotal = (cart.data['total_amount'] ?? 0.0).toDouble();
      final taxAmount = subtotal * taxRate;
      final total = subtotal + taxAmount + shippingCost;

      return {
        'subtotal': subtotal,
        'tax_amount': taxAmount,
        'shipping_cost': shippingCost,
        'total': total,
      };
    } catch (e) {
      logger.e('Failed to calculate cart total', error: e);
      return {
        'subtotal': 0.0,
        'tax_amount': 0.0,
        'shipping_cost': 0.0,
        'total': 0.0,
      };
    }
  }

  /// Validate cart before checkout
  Future<Map<String, dynamic>> validateCart(String cartId) async {
    try {
      final items = await getCartItems(cartId);
      final errors = <String>[];
      final warnings = <String>[];

      if (items.isEmpty) {
        errors.add('Cart is empty');
        return {'isValid': false, 'errors': errors, 'warnings': warnings};
      }

      // Check each item for availability and stock
      for (final item in items) {
        try {
          final productResponse = await databases.getDocument(
            databaseId: databaseId,
            collectionId: 'products',
            documentId: item.productId,
          );

          final product = Product.fromJson(productResponse.data);

          if (!product.isActive) {
            errors.add('${product.title} is no longer available');
            continue;
          }

          if (!product.isInStock) {
            errors.add('${product.title} is out of stock');
            continue;
          }

          if (product.trackInventory && product.stockQuantity < item.quantity) {
            errors.add('Only ${product.stockQuantity} units of ${product.title} available');
            continue;
          }

          if (product.isLowStock) {
            warnings.add('${product.title} has limited stock remaining');
          }

          // Check if price has changed
          if ((product.price - item.unitPrice).abs() > 0.01) {
            warnings.add('Price of ${product.title} has changed from \$${item.unitPrice.toStringAsFixed(2)} to \$${product.price.toStringAsFixed(2)}');
          }
        } catch (e) {
          errors.add('Unable to verify product availability');
        }
      }

      return {
        'isValid': errors.isEmpty,
        'errors': errors,
        'warnings': warnings,
      };
    } catch (e, stackTrace) {
      logger.e('Failed to validate cart', error: e, stackTrace: stackTrace);
      return {
        'isValid': false,
        'errors': ['Unable to validate cart'],
        'warnings': <String>[],
      };
    }
  }

  /// Subscribe to cart updates using Appwrite real-time
  Stream<ShoppingCart> subscribeToCartUpdates(String cartId) {
    return databases.subscribe([
      'databases.$databaseId.collections.$cartsCollection.documents.$cartId',
    ]).map((event) {
      logger.i('Cart update received: ${event.events}');
      return ShoppingCart.fromJson(event.payload as Map<String, dynamic>);
    }).handleError((error) {
      logger.e('Error in cart subscription', error: error);
    });
  }

  /// Transfer guest cart to user cart (for login scenarios)
  Future<bool> mergeGuestCart({
    required String guestCartId,
    required String userId,
  }) async {
    try {
      // Get guest cart items
      final guestItems = await getCartItems(guestCartId);
      
      if (guestItems.isEmpty) return true;

      // Get or create user cart
      var userCart = await getUserCart(userId);
      if (userCart == null) {
        userCart = await createCart(userId);
        if (userCart == null) return false;
      }

      // Add guest items to user cart
      for (final item in guestItems) {
        await addToCart(
          userId: userId,
          productId: item.productId,
          unitPrice: item.unitPrice,
          quantity: item.quantity,
          variantId: item.variantId,
        );
      }

      // Clear guest cart
      await clearCart(guestCartId);

      logger.i('Guest cart merged successfully');
      return true;
    } catch (e, stackTrace) {
      logger.e('Failed to merge guest cart', error: e, stackTrace: stackTrace);
      return false;
    }
  }
}