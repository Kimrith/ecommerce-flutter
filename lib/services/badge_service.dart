import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BadgeService {
  static final ValueNotifier<int> cartCountNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<int> favoriteCountNotifier = ValueNotifier<int>(0);

  /// Load and update the real-time count for cart and favorites directly from storage
  static Future<void> updateCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    int cartTotal = 0;
    int favTotal = 0;

    for (final key in keys) {
      if (key.startsWith('cart_qty_')) {
        final qty = prefs.getInt(key) ?? 0;
        cartTotal += qty;
      } else if (key.startsWith('fav_')) {
        final isFav = prefs.getBool(key) ?? false;
        if (isFav) {
          favTotal++;
        }
      }
    }

    cartCountNotifier.value = cartTotal;
    favoriteCountNotifier.value = favTotal;
  }
}