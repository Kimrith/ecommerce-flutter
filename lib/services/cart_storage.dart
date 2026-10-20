import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import 'badge_service.dart';

class CartStorageService {
  // GET: Load all cart quantities dynamically from storage keys
  static Future<Map<dynamic, int>> loadAllCartQuantities() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<dynamic, int> loadedQuantities = {};
    final keys = prefs.getKeys();

    for (final key in keys) {
      if (key.startsWith('cart_qty_')) {
        final idStr = key.replaceFirst('cart_qty_', '');
        final dynamic productId = int.tryParse(idStr) ?? idStr;
        final qty = prefs.getInt(key) ?? 0;

        if (qty > 0) {
          loadedQuantities[productId] = qty;
        }
      }
    }
    return loadedQuantities;
  }

  // GET: Load quantities specifically for a provided list of products
  static Future<Map<dynamic, int>> loadCartQuantities(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<dynamic, int> loadedQuantities = {};

    for (final product in products) {
      final qty = prefs.getInt('cart_qty_${product.id}') ?? 0;
      if (qty > 0) {
        loadedQuantities[product.id] = qty;
      }
    }
    return loadedQuantities;
  }

  // SET: Update quantity for a single product (handles increment/decrement)
  static Future<Map<dynamic, int>> updateQuantity(
      dynamic productId,
      int delta,
      Map<dynamic, int> currentQuantities,
      ) async {
    final currentQty = currentQuantities[productId] ?? 0;
    final newQty = currentQty + delta;

    if (newQty <= 0) {
      await removeProduct(productId);
      currentQuantities.remove(productId);
    } else {
      await saveQuantity(productId, newQty);
      currentQuantities[productId] = newQty;
    }
    return Map.from(currentQuantities);
  }

  // SET: Save quantity helper
  static Future<void> saveQuantity(dynamic productId, int qty) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cart_qty_$productId', qty);
    await BadgeService.updateCounts();
  }

  // REMOVE: Remove a single product from storage
  static Future<Map<dynamic, int>> removeAndGetUpdated(
      dynamic productId,
      Map<dynamic, int> currentQuantities,
      ) async {
    await removeProduct(productId);
    currentQuantities.remove(productId);
    return Map.from(currentQuantities);
  }

  static Future<void> removeProduct(dynamic productId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart_qty_$productId');
    await BadgeService.updateCounts();
  }

  // CLEAR: Remove all cart products from storage
  static Future<void> clearAll(Map<dynamic, int> currentQuantities) async {
    await clearCart(currentQuantities.keys);
    currentQuantities.clear();
  }

  static Future<void> clearCart([Iterable<dynamic>? productIds]) async {
    final prefs = await SharedPreferences.getInstance();
    if (productIds != null && productIds.isNotEmpty) {
      for (final id in productIds) {
        await prefs.remove('cart_qty_$id');
      }
    } else {
      final keys = prefs.getKeys().toList();
      for (final key in keys) {
        if (key.startsWith('cart_qty_')) {
          await prefs.remove(key);
        }
      }
    }
    await BadgeService.updateCounts();
  }

  // CALCULATE TOTAL: Uses the double effectivePrice directly from the Product model
  static double calculateTotal(List<Product> items, Map<dynamic, int> quantities) {
    double total = 0.0;
    for (final item in items) {
      final qty = quantities[item.id] ?? 0;
      total += item.effectivePrice * qty;
    }
    return total;
  }
}
