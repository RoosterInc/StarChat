import 'dart:convert';
import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import '../models/marketplace_models.dart';

/// Service for product management operations
class ProductService extends GetxService {
  final Databases databases;
  final Storage storage;
  final String databaseId;
  final Logger logger = Logger();

  ProductService({
    required this.databases,
    required this.storage,
    required this.databaseId,
  });

  static const String productsCollection = 'products';
  static const String productImagesCollection = 'product_images';
  static const String reviewsCollection = 'product_reviews';
  static const String wishlistsCollection = 'wishlists';
  static const String bucketId = 'marketplace_assets';

  /// Create a new product
  Future<Product?> createProduct(Product product) async {
    try {
      final response = await databases.createDocument(
        databaseId: databaseId,
        collectionId: productsCollection,
        documentId: ID.unique(),
        data: product.toJson(),
      );
      
      logger.i('Product created successfully: ${response.$id}');
      return Product.fromJson(response.data);
    } on AppwriteException catch (e) {
      logger.e('Failed to create product', error: e);
      Get.snackbar(
        'Error',
        'Failed to create product: ${e.message}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } catch (e, stackTrace) {
      logger.e('Unexpected error creating product', error: e, stackTrace: stackTrace);
      Get.snackbar(
        'Error',
        'An unexpected error occurred',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  /// Get product by ID with images
  Future<Product?> getProduct(String productId) async {
    try {
      final response = await databases.getDocument(
        databaseId: databaseId,
        collectionId: productsCollection,
        documentId: productId,
      );
      
      final product = Product.fromJson(response.data);
      
      // Get product images
      final images = await getProductImages(productId);
      
      return product.copyWith(images: images);
    } on AppwriteException catch (e) {
      logger.e('Failed to get product', error: e);
      return null;
    } catch (e, stackTrace) {
      logger.e('Unexpected error getting product', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Update product information
  Future<Product?> updateProduct(String productId, Map<String, dynamic> updates) async {
    try {
      final response = await databases.updateDocument(
        databaseId: databaseId,
        collectionId: productsCollection,
        documentId: productId,
        data: updates,
      );
      
      logger.i('Product updated successfully: $productId');
      return Product.fromJson(response.data);
    } on AppwriteException catch (e) {
      logger.e('Failed to update product', error: e);
      Get.snackbar(
        'Error',
        'Failed to update product: ${e.message}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } catch (e, stackTrace) {
      logger.e('Unexpected error updating product', error: e, stackTrace: stackTrace);
      Get.snackbar(
        'Error',
        'An unexpected error occurred',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  /// Get products by seller ID
  Future<List<Product>> getProductsBySeller(String sellerId, {
    int limit = 20,
    String? cursor,
  }) async {
    try {
      final queries = [
        Query.equal('seller_id', sellerId),
        Query.orderDesc('\$createdAt'),
        Query.limit(limit),
      ];

      if (cursor != null) {
        queries.add(Query.cursorAfter(cursor));
      }

      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: productsCollection,
        queries: queries,
      );

      return response.documents
          .map((doc) => Product.fromJson(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      logger.e('Failed to get products by seller', error: e);
      return [];
    } catch (e, stackTrace) {
      logger.e('Unexpected error getting seller products', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get active products with filters and sorting
  Future<List<Product>> getProducts({
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    String? searchTerm,
    ProductSortBy sortBy = ProductSortBy.newest,
    bool featuredOnly = false,
    int limit = 20,
    String? cursor,
  }) async {
    try {
      final queries = [
        Query.equal('is_active', true),
        Query.limit(limit),
      ];

      // Add category filter
      if (categoryId != null) {
        queries.add(Query.equal('category_id', categoryId));
      }

      // Add price range filters
      if (minPrice != null) {
        queries.add(Query.greaterThanEqual('price', minPrice));
      }
      if (maxPrice != null) {
        queries.add(Query.lessThanEqual('price', maxPrice));
      }

      // Add featured filter
      if (featuredOnly) {
        queries.add(Query.equal('is_featured', true));
      }

      // Add search
      if (searchTerm != null && searchTerm.isNotEmpty) {
        queries.add(Query.search('title', searchTerm));
      }

      // Add sorting
      switch (sortBy) {
        case ProductSortBy.newest:
          queries.add(Query.orderDesc('\$createdAt'));
          break;
        case ProductSortBy.oldest:
          queries.add(Query.orderAsc('\$createdAt'));
          break;
        case ProductSortBy.priceAsc:
          queries.add(Query.orderAsc('price'));
          break;
        case ProductSortBy.priceDesc:
          queries.add(Query.orderDesc('price'));
          break;
        case ProductSortBy.popular:
          queries.add(Query.orderDesc('sales_count'));
          break;
        case ProductSortBy.rating:
          queries.add(Query.orderDesc('average_rating'));
          break;
      }

      if (cursor != null) {
        queries.add(Query.cursorAfter(cursor));
      }

      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: productsCollection,
        queries: queries,
      );

      return response.documents
          .map((doc) => Product.fromJson(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      logger.e('Failed to get products', error: e);
      return [];
    } catch (e, stackTrace) {
      logger.e('Unexpected error getting products', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get featured products
  Future<List<Product>> getFeaturedProducts({int limit = 10}) async {
    return getProducts(
      featuredOnly: true,
      sortBy: ProductSortBy.popular,
      limit: limit,
    );
  }

  /// Get trending products (high sales)
  Future<List<Product>> getTrendingProducts({int limit = 10}) async {
    return getProducts(
      sortBy: ProductSortBy.popular,
      limit: limit,
    );
  }

  /// Get product images
  Future<List<ProductImage>> getProductImages(String productId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: productImagesCollection,
        queries: [
          Query.equal('product_id', productId),
          Query.orderAsc('display_order'),
          Query.limit(20),
        ],
      );

      return response.documents
          .map((doc) => ProductImage.fromJson(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      logger.e('Failed to get product images', error: e);
      return [];
    } catch (e, stackTrace) {
      logger.e('Unexpected error getting product images', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Upload product image
  Future<ProductImage?> uploadProductImage(
    String productId,
    File imageFile,
    String fileName, {
    bool isPrimary = false,
    int displayOrder = 0,
  }) async {
    try {
      // Upload image to storage
      final response = await storage.createFile(
        bucketId: bucketId,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: imageFile.path, filename: fileName),
      );

      // Generate optimized image URL
      final imageUrl = storage.getFilePreview(
        bucketId: bucketId,
        fileId: response.$id,
        width: 800,
        height: 800,
        gravity: 'center',
        quality: 85,
        output: 'webp',
      ).toString();

      // Create product image record
      final productImage = ProductImage(
        productId: productId,
        imageUrl: imageUrl,
        altText: fileName,
        displayOrder: displayOrder,
        isPrimary: isPrimary,
      );

      final imageResponse = await databases.createDocument(
        databaseId: databaseId,
        collectionId: productImagesCollection,
        documentId: ID.unique(),
        data: productImage.toJson(),
      );

      logger.i('Product image uploaded successfully: ${imageResponse.$id}');
      return ProductImage.fromJson(imageResponse.data);
    } on AppwriteException catch (e) {
      logger.e('Failed to upload product image', error: e);
      Get.snackbar(
        'Error',
        'Failed to upload image: ${e.message}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } catch (e, stackTrace) {
      logger.e('Unexpected error uploading product image', error: e, stackTrace: stackTrace);
      Get.snackbar(
        'Error',
        'An unexpected error occurred while uploading',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  /// Update product stock
  Future<bool> updateStock(String productId, int newQuantity) async {
    try {
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: productsCollection,
        documentId: productId,
        data: {'stock_quantity': newQuantity},
      );
      
      logger.i('Product stock updated: $productId -> $newQuantity');
      return true;
    } on AppwriteException catch (e) {
      logger.e('Failed to update product stock', error: e);
      return false;
    } catch (e, stackTrace) {
      logger.e('Unexpected error updating stock', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Increment product view count
  Future<void> incrementViewCount(String productId) async {
    try {
      final product = await getProduct(productId);
      if (product != null) {
        await databases.updateDocument(
          databaseId: databaseId,
          collectionId: productsCollection,
          documentId: productId,
          data: {'view_count': product.viewCount + 1},
        );
      }
    } catch (e) {
      // Silent fail for view count increment
      logger.w('Failed to increment view count for product: $productId');
    }
  }

  /// Get product reviews
  Future<List<ProductReview>> getProductReviews(String productId, {
    int limit = 20,
    String? cursor,
  }) async {
    try {
      final queries = [
        Query.equal('product_id', productId),
        Query.equal('is_approved', true),
        Query.orderDesc('\$createdAt'),
        Query.limit(limit),
      ];

      if (cursor != null) {
        queries.add(Query.cursorAfter(cursor));
      }

      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: reviewsCollection,
        queries: queries,
      );

      return response.documents
          .map((doc) => ProductReview.fromJson(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      logger.e('Failed to get product reviews', error: e);
      return [];
    } catch (e, stackTrace) {
      logger.e('Unexpected error getting reviews', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Add product to wishlist
  Future<bool> addToWishlist(String userId, String productId) async {
    try {
      await databases.createDocument(
        databaseId: databaseId,
        collectionId: wishlistsCollection,
        documentId: ID.unique(),
        data: {
          'user_id': userId,
          'product_id': productId,
        },
      );
      
      logger.i('Product added to wishlist: $productId');
      return true;
    } on AppwriteException catch (e) {
      if (e.code == 409) {
        // Already in wishlist
        return true;
      }
      logger.e('Failed to add to wishlist', error: e);
      return false;
    } catch (e, stackTrace) {
      logger.e('Unexpected error adding to wishlist', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Remove product from wishlist
  Future<bool> removeFromWishlist(String userId, String productId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: wishlistsCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.equal('product_id', productId),
          Query.limit(1),
        ],
      );

      if (response.documents.isNotEmpty) {
        await databases.deleteDocument(
          databaseId: databaseId,
          collectionId: wishlistsCollection,
          documentId: response.documents.first.$id,
        );
        logger.i('Product removed from wishlist: $productId');
      }
      
      return true;
    } on AppwriteException catch (e) {
      logger.e('Failed to remove from wishlist', error: e);
      return false;
    } catch (e, stackTrace) {
      logger.e('Unexpected error removing from wishlist', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Check if product is in user's wishlist
  Future<bool> isInWishlist(String userId, String productId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: wishlistsCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.equal('product_id', productId),
          Query.limit(1),
        ],
      );

      return response.documents.isNotEmpty;
    } catch (e) {
      logger.w('Failed to check wishlist status for product: $productId');
      return false;
    }
  }

  /// Get user's wishlist
  Future<List<Product>> getUserWishlist(String userId, {
    int limit = 20,
    String? cursor,
  }) async {
    try {
      final queries = [
        Query.equal('user_id', userId),
        Query.orderDesc('\$createdAt'),
        Query.limit(limit),
      ];

      if (cursor != null) {
        queries.add(Query.cursorAfter(cursor));
      }

      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: wishlistsCollection,
        queries: queries,
      );

      // Get product details for each wishlist item
      final products = <Product>[];
      for (final doc in response.documents) {
        final productId = doc.data['product_id'];
        final product = await getProduct(productId);
        if (product != null) {
          products.add(product);
        }
      }

      return products;
    } on AppwriteException catch (e) {
      logger.e('Failed to get user wishlist', error: e);
      return [];
    } catch (e, stackTrace) {
      logger.e('Unexpected error getting wishlist', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Subscribe to product updates using Appwrite real-time
  Stream<Product> subscribeToProductUpdates(String productId) {
    return databases.subscribe([
      'databases.$databaseId.collections.$productsCollection.documents.$productId',
    ]).map((event) {
      logger.i('Product update received: ${event.events}');
      return Product.fromJson(event.payload as Map<String, dynamic>);
    }).handleError((error) {
      logger.e('Error in product subscription', error: error);
    });
  }

  /// Delete product (mark as inactive)
  Future<bool> deleteProduct(String productId) async {
    try {
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: productsCollection,
        documentId: productId,
        data: {'is_active': false},
      );
      
      logger.i('Product marked as inactive: $productId');
      return true;
    } on AppwriteException catch (e) {
      logger.e('Failed to delete product', error: e);
      Get.snackbar(
        'Error',
        'Failed to delete product: ${e.message}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (e, stackTrace) {
      logger.e('Unexpected error deleting product', error: e, stackTrace: stackTrace);
      Get.snackbar(
        'Error',
        'An unexpected error occurred',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }
}

/// Product sorting options
enum ProductSortBy {
  newest,
  oldest,
  priceAsc,
  priceDesc,
  popular,
  rating,
}