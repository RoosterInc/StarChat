import 'package:get/get.dart';
import '../features/marketplace/controllers/marketplace_controller.dart';
import '../features/marketplace/controllers/product_controller.dart';
import '../features/marketplace/controllers/cart_controller.dart';
import '../features/marketplace/controllers/checkout_controller.dart';
import '../features/marketplace/controllers/seller_dashboard_controller.dart';
import '../features/marketplace/services/marketplace_service.dart';
import '../features/marketplace/services/product_service.dart';
import '../features/marketplace/services/cart_service.dart';
import '../features/marketplace/services/order_service.dart';
import '../features/marketplace/services/payment_service.dart';

class MarketplaceBinding extends Bindings {
  @override
  void dependencies() {
    // Services
    Get.lazyPut(() => MarketplaceService(
      databases: Get.find<AuthController>().databases,
      storage: Get.find<AuthController>().storage,
      databaseId: 'StarChat_DB',
    ));
    
    Get.lazyPut(() => ProductService(
      databases: Get.find<AuthController>().databases,
      storage: Get.find<AuthController>().storage,
      databaseId: 'StarChat_DB',
    ));
    
    Get.lazyPut(() => CartService(
      databases: Get.find<AuthController>().databases,
      databaseId: 'StarChat_DB',
    ));
    
    Get.lazyPut(() => OrderService(
      databases: Get.find<AuthController>().databases,
      databaseId: 'StarChat_DB',
    ));
    
    Get.lazyPut(() => PaymentService());
    
    // Controllers
    Get.lazyPut(() => MarketplaceController());
    Get.lazyPut(() => ProductController());
    Get.lazyPut(() => CartController());
    Get.lazyPut(() => CheckoutController());
    Get.lazyPut(() => SellerDashboardController());
  }
}