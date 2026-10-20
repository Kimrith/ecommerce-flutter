import 'package:flutter/material.dart';

/// Utility class for displaying modern, styled floating toast notifications.
class AppToast {
  /// Base toast display method using floating ScaffoldMessenger SnackBar
  static void showToast(
    BuildContext context, {
    required String message,
    required IconData icon,
    Color backgroundColor = const Color(0xFF323232),
    Color iconColor = Colors.white,
    Color textColor = Colors.white,
    Duration duration = const Duration(milliseconds: 1800),
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 6,
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        duration: duration,
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    showToast(
      context,
      message: message,
      icon: Icons.check_circle_outline,
      backgroundColor: const Color(0xFF2E7D32),
      iconColor: Colors.white,
    );
  }

  static void showError(BuildContext context, String message) {
    showToast(
      context,
      message: message,
      icon: Icons.error_outline,
      backgroundColor: const Color(0xFFC62828),
      iconColor: Colors.white,
    );
  }

  static void toggleFavorite(BuildContext context, String productName, bool isFavorite) {
    showFavoriteToast(context, productName: productName, isFavorite: isFavorite);
  }

  static void successCart(BuildContext context, String productName, [int quantity = 1]) {
    showCartToast(context, productName: productName, quantity: quantity);
  }

  /// Toast notification for Favorite actions (Added / Removed)
  static void showFavoriteToast(
    BuildContext context, {
    required String productName,
    required bool isFavorite,
  }) {
    if (isFavorite) {
      showToast(
        context,
        message: 'Added "$productName" to Favorites',
        icon: Icons.favorite,
        backgroundColor: const Color(0xFFE53935), // Vibrant red
        iconColor: Colors.white,
      );
    } else {
      showToast(
        context,
        message: 'Removed "$productName" from Favorites',
        icon: Icons.favorite_border,
        backgroundColor: const Color(0xFF616161), // Dark Grey
        iconColor: Colors.white70,
      );
    }
  }

  /// Toast notification for Cart actions (Added / Updated)
  static void showCartToast(
    BuildContext context, {
    required String productName,
    required int quantity,
  }) {
    showToast(
      context,
      message: 'Added "$productName" to Cart (Qty: $quantity)',
      icon: Icons.shopping_cart_checkout,
      backgroundColor: const Color(0xFF1E88E5), // Vibrant Blue
      iconColor: Colors.white,
    );
  }

  /// Toast notification for Cart removal actions
  static void showRemoveCartToast(
    BuildContext context, {
    required String productName,
  }) {
    showToast(
      context,
      message: 'Removed "$productName" from Cart',
      icon: Icons.remove_shopping_cart,
      backgroundColor: const Color(0xFF757575),
      iconColor: Colors.white,
    );
  }

  /// General info or warning toast
  static void showInfoToast(
    BuildContext context, {
    required String message,
    IconData icon = Icons.info_outline,
  }) {
    showToast(
      context,
      message: message,
      icon: icon,
      backgroundColor: const Color(0xFF424242),
      iconColor: Colors.white,
    );
  }
}
