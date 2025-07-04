import 'dart:convert';

/// Marketplace Store model for seller profiles
class MarketplaceStore {
  final String? id;
  final String sellerId;
  final String storeName;
  final String? storeDescription;
  final String? storeLogoUrl;
  final String? storeBannerUrl;
  final String businessEmail;
  final String? businessPhone;
  final String? businessAddress;
  final bool isVerified;
  final bool isActive;
  final int totalProducts;
  final int totalSales;
  final double averageRating;
  final double commissionRate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MarketplaceStore({
    this.id,
    required this.sellerId,
    required this.storeName,
    this.storeDescription,
    this.storeLogoUrl,
    this.storeBannerUrl,
    required this.businessEmail,
    this.businessPhone,
    this.businessAddress,
    this.isVerified = false,
    this.isActive = true,
    this.totalProducts = 0,
    this.totalSales = 0,
    this.averageRating = 0.0,
    this.commissionRate = 0.05,
    this.createdAt,
    this.updatedAt,
  });

  factory MarketplaceStore.fromJson(Map<String, dynamic> json) {
    return MarketplaceStore(
      id: json['\$id'],
      sellerId: json['seller_id'] ?? '',
      storeName: json['store_name'] ?? '',
      storeDescription: json['store_description'],
      storeLogoUrl: json['store_logo_url'],
      storeBannerUrl: json['store_banner_url'],
      businessEmail: json['business_email'] ?? '',
      businessPhone: json['business_phone'],
      businessAddress: json['business_address'],
      isVerified: json['is_verified'] ?? false,
      isActive: json['is_active'] ?? true,
      totalProducts: json['total_products'] ?? 0,
      totalSales: json['total_sales'] ?? 0,
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      commissionRate: (json['commission_rate'] ?? 0.05).toDouble(),
      createdAt: json['\$createdAt'] != null 
          ? DateTime.parse(json['\$createdAt']) 
          : null,
      updatedAt: json['\$updatedAt'] != null 
          ? DateTime.parse(json['\$updatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seller_id': sellerId,
      'store_name': storeName,
      'store_description': storeDescription,
      'store_logo_url': storeLogoUrl,
      'store_banner_url': storeBannerUrl,
      'business_email': businessEmail,
      'business_phone': businessPhone,
      'business_address': businessAddress,
      'is_verified': isVerified,
      'is_active': isActive,
      'total_products': totalProducts,
      'total_sales': totalSales,
      'average_rating': averageRating,
      'commission_rate': commissionRate,
    };
  }

  MarketplaceStore copyWith({
    String? id,
    String? sellerId,
    String? storeName,
    String? storeDescription,
    String? storeLogoUrl,
    String? storeBannerUrl,
    String? businessEmail,
    String? businessPhone,
    String? businessAddress,
    bool? isVerified,
    bool? isActive,
    int? totalProducts,
    int? totalSales,
    double? averageRating,
    double? commissionRate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MarketplaceStore(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      storeName: storeName ?? this.storeName,
      storeDescription: storeDescription ?? this.storeDescription,
      storeLogoUrl: storeLogoUrl ?? this.storeLogoUrl,
      storeBannerUrl: storeBannerUrl ?? this.storeBannerUrl,
      businessEmail: businessEmail ?? this.businessEmail,
      businessPhone: businessPhone ?? this.businessPhone,
      businessAddress: businessAddress ?? this.businessAddress,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      totalProducts: totalProducts ?? this.totalProducts,
      totalSales: totalSales ?? this.totalSales,
      averageRating: averageRating ?? this.averageRating,
      commissionRate: commissionRate ?? this.commissionRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Product Category model
class ProductCategory {
  final String? id;
  final String name;
  final String slug;
  final String? description;
  final String? parentId;
  final String? iconUrl;
  final int displayOrder;
  final bool isActive;
  final int productCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductCategory({
    this.id,
    required this.name,
    required this.slug,
    this.description,
    this.parentId,
    this.iconUrl,
    this.displayOrder = 0,
    this.isActive = true,
    this.productCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['\$id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      parentId: json['parent_id'],
      iconUrl: json['icon_url'],
      displayOrder: json['display_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      productCount: json['product_count'] ?? 0,
      createdAt: json['\$createdAt'] != null 
          ? DateTime.parse(json['\$createdAt']) 
          : null,
      updatedAt: json['\$updatedAt'] != null 
          ? DateTime.parse(json['\$updatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'slug': slug,
      'description': description,
      'parent_id': parentId,
      'icon_url': iconUrl,
      'display_order': displayOrder,
      'is_active': isActive,
      'product_count': productCount,
    };
  }
}

/// Product model with inventory tracking
class Product {
  final String? id;
  final String sellerId;
  final String storeId;
  final String categoryId;
  final String title;
  final String description;
  final String? shortDescription;
  final String? sku;
  final double price;
  final double? comparePrice;
  final String currency;
  final int stockQuantity;
  final int lowStockThreshold;
  final bool trackInventory;
  final double? weight;
  final String? dimensions;
  final List<String> tags;
  final bool isFeatured;
  final bool isActive;
  final int viewCount;
  final int salesCount;
  final double averageRating;
  final int reviewCount;
  final bool requiresShipping;
  final String? shippingClass;
  final List<ProductImage> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    this.id,
    required this.sellerId,
    required this.storeId,
    required this.categoryId,
    required this.title,
    required this.description,
    this.shortDescription,
    this.sku,
    required this.price,
    this.comparePrice,
    this.currency = 'USD',
    this.stockQuantity = 0,
    this.lowStockThreshold = 5,
    this.trackInventory = true,
    this.weight,
    this.dimensions,
    this.tags = const [],
    this.isFeatured = false,
    this.isActive = true,
    this.viewCount = 0,
    this.salesCount = 0,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.requiresShipping = true,
    this.shippingClass,
    this.images = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['\$id'],
      sellerId: json['seller_id'] ?? '',
      storeId: json['store_id'] ?? '',
      categoryId: json['category_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      shortDescription: json['short_description'],
      sku: json['sku'],
      price: (json['price'] ?? 0.0).toDouble(),
      comparePrice: json['compare_price']?.toDouble(),
      currency: json['currency'] ?? 'USD',
      stockQuantity: json['stock_quantity'] ?? 0,
      lowStockThreshold: json['low_stock_threshold'] ?? 5,
      trackInventory: json['track_inventory'] ?? true,
      weight: json['weight']?.toDouble(),
      dimensions: json['dimensions'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      isFeatured: json['is_featured'] ?? false,
      isActive: json['is_active'] ?? true,
      viewCount: json['view_count'] ?? 0,
      salesCount: json['sales_count'] ?? 0,
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      requiresShipping: json['requires_shipping'] ?? true,
      shippingClass: json['shipping_class'],
      createdAt: json['\$createdAt'] != null 
          ? DateTime.parse(json['\$createdAt']) 
          : null,
      updatedAt: json['\$updatedAt'] != null 
          ? DateTime.parse(json['\$updatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seller_id': sellerId,
      'store_id': storeId,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'short_description': shortDescription,
      'sku': sku,
      'price': price,
      'compare_price': comparePrice,
      'currency': currency,
      'stock_quantity': stockQuantity,
      'low_stock_threshold': lowStockThreshold,
      'track_inventory': trackInventory,
      'weight': weight,
      'dimensions': dimensions,
      'tags': tags,
      'is_featured': isFeatured,
      'is_active': isActive,
      'view_count': viewCount,
      'sales_count': salesCount,
      'average_rating': averageRating,
      'review_count': reviewCount,
      'requires_shipping': requiresShipping,
      'shipping_class': shippingClass,
    };
  }

  /// Check if product is in stock
  bool get isInStock => !trackInventory || stockQuantity > 0;

  /// Check if product has low stock
  bool get isLowStock => trackInventory && stockQuantity <= lowStockThreshold;

  /// Get discount percentage
  double? get discountPercentage {
    if (comparePrice != null && comparePrice! > price) {
      return ((comparePrice! - price) / comparePrice!) * 100;
    }
    return null;
  }

  Product copyWith({
    String? id,
    String? sellerId,
    String? storeId,
    String? categoryId,
    String? title,
    String? description,
    String? shortDescription,
    String? sku,
    double? price,
    double? comparePrice,
    String? currency,
    int? stockQuantity,
    int? lowStockThreshold,
    bool? trackInventory,
    double? weight,
    String? dimensions,
    List<String>? tags,
    bool? isFeatured,
    bool? isActive,
    int? viewCount,
    int? salesCount,
    double? averageRating,
    int? reviewCount,
    bool? requiresShipping,
    String? shippingClass,
    List<ProductImage>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      storeId: storeId ?? this.storeId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      comparePrice: comparePrice ?? this.comparePrice,
      currency: currency ?? this.currency,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      trackInventory: trackInventory ?? this.trackInventory,
      weight: weight ?? this.weight,
      dimensions: dimensions ?? this.dimensions,
      tags: tags ?? this.tags,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      viewCount: viewCount ?? this.viewCount,
      salesCount: salesCount ?? this.salesCount,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      requiresShipping: requiresShipping ?? this.requiresShipping,
      shippingClass: shippingClass ?? this.shippingClass,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Product Image model
class ProductImage {
  final String? id;
  final String productId;
  final String imageUrl;
  final String? altText;
  final int displayOrder;
  final bool isPrimary;

  const ProductImage({
    this.id,
    required this.productId,
    required this.imageUrl,
    this.altText,
    this.displayOrder = 0,
    this.isPrimary = false,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['\$id'],
      productId: json['product_id'] ?? '',
      imageUrl: json['image_url'] ?? '',
      altText: json['alt_text'],
      displayOrder: json['display_order'] ?? 0,
      isPrimary: json['is_primary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'image_url': imageUrl,
      'alt_text': altText,
      'display_order': displayOrder,
      'is_primary': isPrimary,
    };
  }
}

/// Shopping Cart model
class ShoppingCart {
  final String? id;
  final String userId;
  final String? sessionId;
  final int totalItems;
  final double totalAmount;
  final String currency;
  final DateTime? expiresAt;
  final List<CartItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ShoppingCart({
    this.id,
    required this.userId,
    this.sessionId,
    this.totalItems = 0,
    this.totalAmount = 0.0,
    this.currency = 'USD',
    this.expiresAt,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory ShoppingCart.fromJson(Map<String, dynamic> json) {
    return ShoppingCart(
      id: json['\$id'],
      userId: json['user_id'] ?? '',
      sessionId: json['session_id'],
      totalItems: json['total_items'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at']) 
          : null,
      createdAt: json['\$createdAt'] != null 
          ? DateTime.parse(json['\$createdAt']) 
          : null,
      updatedAt: json['\$updatedAt'] != null 
          ? DateTime.parse(json['\$updatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'session_id': sessionId,
      'total_items': totalItems,
      'total_amount': totalAmount,
      'currency': currency,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }
}

/// Cart Item model
class CartItem {
  final String? id;
  final String cartId;
  final String productId;
  final String? variantId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final Product? product;

  const CartItem({
    this.id,
    required this.cartId,
    required this.productId,
    this.variantId,
    this.quantity = 1,
    required this.unitPrice,
    required this.totalPrice,
    this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['\$id'],
      cartId: json['cart_id'] ?? '',
      productId: json['product_id'] ?? '',
      variantId: json['variant_id'],
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unit_price'] ?? 0.0).toDouble(),
      totalPrice: (json['total_price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cart_id': cartId,
      'product_id': productId,
      'variant_id': variantId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }

  CartItem copyWith({
    String? id,
    String? cartId,
    String? productId,
    String? variantId,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    Product? product,
  }) {
    return CartItem(
      id: id ?? this.id,
      cartId: cartId ?? this.cartId,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      product: product ?? this.product,
    );
  }
}

/// Order model for purchase management
class Order {
  final String? id;
  final String orderNumber;
  final String buyerId;
  final String sellerId;
  final OrderStatus status;
  final double subtotal;
  final double taxAmount;
  final double shippingAmount;
  final double discountAmount;
  final double totalAmount;
  final String currency;
  final PaymentStatus paymentStatus;
  final String shippingAddress;
  final String? billingAddress;
  final String? trackingNumber;
  final String? notes;
  final DateTime? estimatedDelivery;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final List<OrderItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Order({
    this.id,
    required this.orderNumber,
    required this.buyerId,
    required this.sellerId,
    this.status = OrderStatus.pending,
    required this.subtotal,
    this.taxAmount = 0.0,
    this.shippingAmount = 0.0,
    this.discountAmount = 0.0,
    required this.totalAmount,
    this.currency = 'USD',
    this.paymentStatus = PaymentStatus.pending,
    required this.shippingAddress,
    this.billingAddress,
    this.trackingNumber,
    this.notes,
    this.estimatedDelivery,
    this.shippedAt,
    this.deliveredAt,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['\$id'],
      orderNumber: json['order_number'] ?? '',
      buyerId: json['buyer_id'] ?? '',
      sellerId: json['seller_id'] ?? '',
      status: OrderStatus.fromString(json['status'] ?? 'pending'),
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      taxAmount: (json['tax_amount'] ?? 0.0).toDouble(),
      shippingAmount: (json['shipping_amount'] ?? 0.0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0.0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      paymentStatus: PaymentStatus.fromString(json['payment_status'] ?? 'pending'),
      shippingAddress: json['shipping_address'] ?? '',
      billingAddress: json['billing_address'],
      trackingNumber: json['tracking_number'],
      notes: json['notes'],
      estimatedDelivery: json['estimated_delivery'] != null 
          ? DateTime.parse(json['estimated_delivery']) 
          : null,
      shippedAt: json['shipped_at'] != null 
          ? DateTime.parse(json['shipped_at']) 
          : null,
      deliveredAt: json['delivered_at'] != null 
          ? DateTime.parse(json['delivered_at']) 
          : null,
      createdAt: json['\$createdAt'] != null 
          ? DateTime.parse(json['\$createdAt']) 
          : null,
      updatedAt: json['\$updatedAt'] != null 
          ? DateTime.parse(json['\$updatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_number': orderNumber,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'status': status.value,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'shipping_amount': shippingAmount,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'currency': currency,
      'payment_status': paymentStatus.value,
      'shipping_address': shippingAddress,
      'billing_address': billingAddress,
      'tracking_number': trackingNumber,
      'notes': notes,
      'estimated_delivery': estimatedDelivery?.toIso8601String(),
      'shipped_at': shippedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
    };
  }
}

/// Order Item model
class OrderItem {
  final String? id;
  final String orderId;
  final String productId;
  final String productTitle;
  final String? productImage;
  final String? variantId;
  final String? variantDetails;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const OrderItem({
    this.id,
    required this.orderId,
    required this.productId,
    required this.productTitle,
    this.productImage,
    this.variantId,
    this.variantDetails,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['\$id'],
      orderId: json['order_id'] ?? '',
      productId: json['product_id'] ?? '',
      productTitle: json['product_title'] ?? '',
      productImage: json['product_image'],
      variantId: json['variant_id'],
      variantDetails: json['variant_details'],
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unit_price'] ?? 0.0).toDouble(),
      totalPrice: (json['total_price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'product_id': productId,
      'product_title': productTitle,
      'product_image': productImage,
      'variant_id': variantId,
      'variant_details': variantDetails,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }
}

/// Order Status enumeration
enum OrderStatus {
  pending('pending'),
  confirmed('confirmed'),
  processing('processing'),
  shipped('shipped'),
  delivered('delivered'),
  cancelled('cancelled'),
  refunded('refunded');

  const OrderStatus(this.value);
  final String value;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

/// Payment Status enumeration
enum PaymentStatus {
  pending('pending'),
  processing('processing'),
  paid('paid'),
  failed('failed'),
  cancelled('cancelled'),
  refunded('refunded');

  const PaymentStatus(this.value);
  final String value;

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}

/// Product Review model
class ProductReview {
  final String? id;
  final String productId;
  final String userId;
  final String? orderId;
  final int rating;
  final String? title;
  final String content;
  final List<String> images;
  final bool isVerifiedPurchase;
  final int helpfulCount;
  final bool isApproved;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductReview({
    this.id,
    required this.productId,
    required this.userId,
    this.orderId,
    required this.rating,
    this.title,
    required this.content,
    this.images = const [],
    this.isVerifiedPurchase = false,
    this.helpfulCount = 0,
    this.isApproved = true,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      id: json['\$id'],
      productId: json['product_id'] ?? '',
      userId: json['user_id'] ?? '',
      orderId: json['order_id'],
      rating: json['rating'] ?? 1,
      title: json['title'],
      content: json['content'] ?? '',
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      isVerifiedPurchase: json['is_verified_purchase'] ?? false,
      helpfulCount: json['helpful_count'] ?? 0,
      isApproved: json['is_approved'] ?? true,
      createdAt: json['\$createdAt'] != null 
          ? DateTime.parse(json['\$createdAt']) 
          : null,
      updatedAt: json['\$updatedAt'] != null 
          ? DateTime.parse(json['\$updatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'user_id': userId,
      'order_id': orderId,
      'rating': rating,
      'title': title,
      'content': content,
      'images': images,
      'is_verified_purchase': isVerifiedPurchase,
      'helpful_count': helpfulCount,
      'is_approved': isApproved,
    };
  }
}