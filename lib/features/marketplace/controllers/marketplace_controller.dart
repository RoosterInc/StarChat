import 'package:get/get.dart';
import 'package:logger/logger.dart';

import '../models/marketplace_models.dart';
import '../services/marketplace_service.dart';
import '../services/product_service.dart';

/// Main marketplace controller for browsing and discovery
class MarketplaceController extends GetxController {
  final MarketplaceService _marketplaceService = Get.find<MarketplaceService>();
  final ProductService _productService = Get.find<ProductService>();
  final Logger logger = Logger();

  // Reactive observables following AGENTS.md patterns
  final _isLoading = false.obs;
  final _products = <Product>[].obs;
  final _featuredProducts = <Product>[].obs;
  final _trendingProducts = <Product>[].obs;
  final _categories = <ProductCategory>[].obs;
  final _stores = <MarketplaceStore>[].obs;
  final _searchQuery = ''.obs;
  final _selectedCategory = Rxn<ProductCategory>();
  final _sortBy = ProductSortBy.newest.obs;
  final _priceRange = RxList<double>([0.0, 1000.0]);
  final _showFeaturedOnly = false.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  List<Product> get products => _products;
  List<Product> get featuredProducts => _featuredProducts;
  List<Product> get trendingProducts => _trendingProducts;
  List<ProductCategory> get categories => _categories;
  List<MarketplaceStore> get stores => _stores;
  String get searchQuery => _searchQuery.value;
  ProductCategory? get selectedCategory => _selectedCategory.value;
  ProductSortBy get sortBy => _sortBy.value;
  List<double> get priceRange => _priceRange;
  bool get showFeaturedOnly => _showFeaturedOnly.value;

  @override
  void onInit() {
    super.onInit();
    _initializeMarketplace();
  }

  /// Initialize marketplace data
  Future<void> _initializeMarketplace() async {
    _isLoading.value = true;
    try {
      await Future.wait([
        loadCategories(),
        loadFeaturedProducts(),
        loadTrendingProducts(),
        loadProducts(),
      ]);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load product categories
  Future<void> loadCategories() async {
    try {
      final categories = await _marketplaceService.getAllCategories();
      _categories.assignAll(categories);
      logger.i('Loaded ${categories.length} categories');
    } catch (e) {
      logger.e('Failed to load categories', error: e);
    }
  }

  /// Load featured products
  Future<void> loadFeaturedProducts() async {
    try {
      final products = await _productService.getFeaturedProducts(limit: 10);
      _featuredProducts.assignAll(products);
      logger.i('Loaded ${products.length} featured products');
    } catch (e) {
      logger.e('Failed to load featured products', error: e);
    }
  }

  /// Load trending products
  Future<void> loadTrendingProducts() async {
    try {
      final products = await _productService.getTrendingProducts(limit: 10);
      _trendingProducts.assignAll(products);
      logger.i('Loaded ${products.length} trending products');
    } catch (e) {
      logger.e('Failed to load trending products', error: e);
    }
  }

  /// Load products with current filters
  Future<void> loadProducts({bool append = false}) async {
    if (!append) {
      _isLoading.value = true;
    }

    try {
      final products = await _productService.getProducts(
        categoryId: _selectedCategory.value?.id,
        minPrice: _priceRange[0],
        maxPrice: _priceRange[1],
        searchTerm: _searchQuery.value.isNotEmpty ? _searchQuery.value : null,
        sortBy: _sortBy.value,
        featuredOnly: _showFeaturedOnly.value,
        limit: 20,
        cursor: append && _products.isNotEmpty ? _products.last.id : null,
      );

      if (append) {
        _products.addAll(products);
      } else {
        _products.assignAll(products);
      }

      logger.i('Loaded ${products.length} products (append: $append)');
    } catch (e) {
      logger.e('Failed to load products', error: e);
    } finally {
      if (!append) {
        _isLoading.value = false;
      }
    }
  }

  /// Search products
  Future<void> searchProducts(String query) async {
    _searchQuery.value = query;
    await loadProducts();
  }

  /// Filter by category
  void filterByCategory(ProductCategory? category) {
    _selectedCategory.value = category;
    loadProducts();
  }

  /// Update sort order
  void updateSortBy(ProductSortBy newSortBy) {
    _sortBy.value = newSortBy;
    loadProducts();
  }

  /// Update price range filter
  void updatePriceRange(double min, double max) {
    _priceRange.assignAll([min, max]);
    loadProducts();
  }

  /// Toggle featured only filter
  void toggleFeaturedOnly() {
    _showFeaturedOnly.value = !_showFeaturedOnly.value;
    loadProducts();
  }

  /// Clear all filters
  void clearFilters() {
    _selectedCategory.value = null;
    _searchQuery.value = '';
    _priceRange.assignAll([0.0, 1000.0]);
    _showFeaturedOnly.value = false;
    _sortBy.value = ProductSortBy.newest;
    loadProducts();
  }

  /// Load more products (pagination)
  Future<void> loadMoreProducts() async {
    if (_products.isNotEmpty) {
      await loadProducts(append: true);
    }
  }

  /// Refresh marketplace data
  Future<void> refresh() async {
    await _initializeMarketplace();
  }

  /// Get product by ID with view count increment
  Future<Product?> getProduct(String productId) async {
    try {
      // Increment view count
      await _productService.incrementViewCount(productId);
      
      // Get product details
      return await _productService.getProduct(productId);
    } catch (e) {
      logger.e('Failed to get product', error: e);
      return null;
    }
  }

  /// Get products by store
  Future<List<Product>> getStoreProducts(String storeId) async {
    try {
      // Find store by ID to get seller ID
      final store = await _marketplaceService.getStore(storeId);
      if (store == null) return [];

      return await _productService.getProductsBySeller(store.sellerId);
    } catch (e) {
      logger.e('Failed to get store products', error: e);
      return [];
    }
  }

  /// Get related products
  Future<List<Product>> getRelatedProducts(String productId, String categoryId) async {
    try {
      final products = await _productService.getProducts(
        categoryId: categoryId,
        sortBy: ProductSortBy.popular,
        limit: 10,
      );

      // Remove the current product from related products
      return products.where((p) => p.id != productId).toList();
    } catch (e) {
      logger.e('Failed to get related products', error: e);
      return [];
    }
  }

  /// Get popular search terms (could be enhanced with analytics)
  List<String> getPopularSearchTerms() {
    return [
      'Electronics',
      'Clothing',
      'Books',
      'Home & Garden',
      'Sports',
      'Beauty',
      'Toys',
      'Automotive',
    ];
  }

  /// Get category hierarchy for breadcrumbs
  List<ProductCategory> getCategoryBreadcrumbs(String categoryId) {
    final breadcrumbs = <ProductCategory>[];
    var currentCategory = _categories.firstWhereOrNull((c) => c.id == categoryId);

    while (currentCategory != null) {
      breadcrumbs.insert(0, currentCategory);
      
      if (currentCategory.parentId != null) {
        currentCategory = _categories.firstWhereOrNull(
          (c) => c.id == currentCategory!.parentId,
        );
      } else {
        break;
      }
    }

    return breadcrumbs;
  }

  /// Check if product is in current results
  bool isProductInResults(String productId) {
    return _products.any((p) => p.id == productId);
  }

  /// Get filter summary text
  String getFilterSummary() {
    final filters = <String>[];
    
    if (_selectedCategory.value != null) {
      filters.add('Category: ${_selectedCategory.value!.name}');
    }
    
    if (_searchQuery.value.isNotEmpty) {
      filters.add('Search: "${_searchQuery.value}"');
    }
    
    if (_priceRange[0] > 0 || _priceRange[1] < 1000) {
      filters.add('Price: \$${_priceRange[0].toStringAsFixed(0)} - \$${_priceRange[1].toStringAsFixed(0)}');
    }
    
    if (_showFeaturedOnly.value) {
      filters.add('Featured only');
    }

    return filters.isEmpty ? 'All products' : filters.join(', ');
  }

  /// Get sort display name
  String getSortDisplayName(ProductSortBy sortBy) {
    switch (sortBy) {
      case ProductSortBy.newest:
        return 'Newest First';
      case ProductSortBy.oldest:
        return 'Oldest First';
      case ProductSortBy.priceAsc:
        return 'Price: Low to High';
      case ProductSortBy.priceDesc:
        return 'Price: High to Low';
      case ProductSortBy.popular:
        return 'Most Popular';
      case ProductSortBy.rating:
        return 'Highest Rated';
    }
  }
}