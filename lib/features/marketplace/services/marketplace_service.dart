import 'dart:convert';
import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import '../models/marketplace_models.dart';

/// Service for marketplace store management operations
class MarketplaceService extends GetxService {
  final Databases databases;
  final Storage storage;
  final String databaseId;
  final Logger logger = Logger();

  MarketplaceService({
    required this.databases,
    required this.storage,
    required this.databaseId,
  });

  static const String storesCollection = 'marketplace_stores';
  static const String categoriesCollection = 'product_categories';
  static const String bucketId = 'marketplace_assets';

  /// Create a new marketplace store
  Future<MarketplaceStore?> createStore(MarketplaceStore store) async {
    try {
      final response = await databases.createDocument(
        databaseId: databaseId,
        collectionId: storesCollection,
        documentId: ID.unique(),
        data: store.toJson(),
      );
      
      logger.i('Store created successfully: ${response.$id}');
      return MarketplaceStore.fromJson(response.data);
    } on AppwriteException catch (e) {
      logger.e('Failed to create store', error: e);
      Get.snackbar(
        'Error',
        'Failed to create store: ${e.message}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } catch (e, stackTrace) {
      logger.e('Unexpected error creating store', error: e, stackTrace: stackTrace);
      Get.snackbar(
        'Error',
        'An unexpected error occurred',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  /// Get store by seller ID
  Future<MarketplaceStore?> getStoreByUserId(String sellerId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: storesCollection,
        queries: [
          Query.equal('seller_id', sellerId),
          Query.limit(1),
        ],
      );

      if (response.documents.isNotEmpty) {
        return MarketplaceStore.fromJson(response.documents.first.data);
      }
      return null;
    } on AppwriteException catch (e) {
      logger.e('Failed to get store by user ID', error: e);
      return null;
    } catch (e, stackTrace) {
      logger.e('Unexpected error getting store', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get store by ID
  Future<MarketplaceStore?> getStore(String storeId) async {
    try {
      final response = await databases.getDocument(
        databaseId: databaseId,
        collectionId: storesCollection,
        documentId: storeId,
      );
      
      return MarketplaceStore.fromJson(response.data);
    } on AppwriteException catch (e) {
      logger.e('Failed to get store', error: e);
      return null;
    } catch (e, stackTrace) {
      logger.e('Unexpected error getting store', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Update store information
  Future<MarketplaceStore?> updateStore(String storeId, Map<String, dynamic> updates) async {
    try {
      final response = await databases.updateDocument(
        databaseId: databaseId,
        collectionId: storesCollection,
        documentId: storeId,
        data: updates,
      );
      
      logger.i('Store updated successfully: $storeId');
      return MarketplaceStore.fromJson(response.data);
    } on AppwriteException catch (e) {
      logger.e('Failed to update store', error: e);
      Get.snackbar(
        'Error',
        'Failed to update store: ${e.message}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } catch (e, stackTrace) {
      logger.e('Unexpected error updating store', error: e, stackTrace: stackTrace);
      Get.snackbar(
        'Error',
        'An unexpected error occurred',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  /// Get all active stores with pagination
  Future<List<MarketplaceStore>> getActiveStores({
    int limit = 20,
    String? cursor,
  }) async {
    try {
      final queries = [
        Query.equal('is_active', true),
        Query.orderDesc('\$createdAt'),
        Query.limit(limit),
      ];

      if (cursor != null) {
        queries.add(Query.cursorAfter(cursor));
      }

      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: storesCollection,
        queries: queries,
      );

      return response.documents
          .map((doc) => MarketplaceStore.fromJson(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      logger.e('Failed to get active stores', error: e);
      return [];
    } catch (e, stackTrace) {
      logger.e('Unexpected error getting stores', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Search stores by name or description
  Future<List<MarketplaceStore>> searchStores(String searchTerm, {int limit = 20}) async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: storesCollection,
        queries: [
          Query.search('store_name', searchTerm),
          Query.equal('is_active', true),
          Query.limit(limit),
        ],
      );

      return response.documents
          .map((doc) => MarketplaceStore.fromJson(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      logger.e('Failed to search stores', error: e);
      return [];
    } catch (e, stackTrace) {
      logger.e('Unexpected error searching stores', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Upload store logo or banner
  Future<String?> uploadStoreImage(File imageFile, String fileName) async {
    try {
      final response = await storage.createFile(
        bucketId: bucketId,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: imageFile.path, filename: fileName),
      );

      // Generate optimized image URL using Appwrite Preview API
      final imageUrl = storage.getFilePreview(
        bucketId: bucketId,
        fileId: response.$id,
        width: 400,
        height: 400,
        gravity: 'center',
        quality: 80,
        output: 'webp', // Use WebP for better compression
      ).toString();

      logger.i('Store image uploaded successfully: ${response.$id}');
      return imageUrl;
    } on AppwriteException catch (e) {
      logger.e('Failed to upload store image', error: e);
      Get.snackbar(
        'Error',
        'Failed to upload image: ${e.message}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } catch (e, stackTrace) {
      logger.e('Unexpected error uploading image', error: e, stackTrace: stackTrace);
      Get.snackbar(
        'Error',
        'An unexpected error occurred while uploading',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  /// Get product categories with hierarchy
  Future<List<ProductCategory>> getCategories({String? parentId}) async {
    try {
      final queries = [
        Query.equal('is_active', true),
        Query.orderAsc('display_order'),
        Query.limit(100),
      ];

      if (parentId != null) {
        queries.add(Query.equal('parent_id', parentId));
      } else {
        queries.add(Query.isNull('parent_id'));
      }

      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: categoriesCollection,
        queries: queries,
      );

      return response.documents
          .map((doc) => ProductCategory.fromJson(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      logger.e('Failed to get categories', error: e);
      return [];
    } catch (e, stackTrace) {
      logger.e('Unexpected error getting categories', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get all categories (flat list)
  Future<List<ProductCategory>> getAllCategories() async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: categoriesCollection,
        queries: [
          Query.equal('is_active', true),
          Query.orderAsc('display_order'),
          Query.limit(200),
        ],
      );

      return response.documents
          .map((doc) => ProductCategory.fromJson(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      logger.e('Failed to get all categories', error: e);
      return [];
    } catch (e, stackTrace) {
      logger.e('Unexpected error getting all categories', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Subscribe to store updates using Appwrite real-time
  Stream<MarketplaceStore> subscribeToStoreUpdates(String storeId) {
    return databases.subscribe([
      'databases.$databaseId.collections.$storesCollection.documents.$storeId',
    ]).map((event) {
      logger.i('Store update received: ${event.events}');
      return MarketplaceStore.fromJson(event.payload as Map<String, dynamic>);
    }).handleError((error) {
      logger.e('Error in store subscription', error: error);
    });
  }

  /// Get store analytics data
  Future<Map<String, dynamic>> getStoreAnalytics(String storeId) async {
    try {
      // This would typically aggregate data from orders, products, etc.
      // For now, returning the basic store information
      final store = await getStore(storeId);
      if (store == null) return {};

      return {
        'total_products': store.totalProducts,
        'total_sales': store.totalSales,
        'average_rating': store.averageRating,
        'revenue': 0.0, // Would calculate from orders
        'views': 0, // Would calculate from product views
        'conversion_rate': 0.0, // Would calculate from analytics
      };
    } catch (e, stackTrace) {
      logger.e('Error getting store analytics', error: e, stackTrace: stackTrace);
      return {};
    }
  }

  /// Delete store (mark as inactive)
  Future<bool> deleteStore(String storeId) async {
    try {
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: storesCollection,
        documentId: storeId,
        data: {'is_active': false},
      );
      
      logger.i('Store marked as inactive: $storeId');
      return true;
    } on AppwriteException catch (e) {
      logger.e('Failed to delete store', error: e);
      Get.snackbar(
        'Error',
        'Failed to delete store: ${e.message}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (e, stackTrace) {
      logger.e('Unexpected error deleting store', error: e, stackTrace: stackTrace);
      Get.snackbar(
        'Error',
        'An unexpected error occurred',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }
}