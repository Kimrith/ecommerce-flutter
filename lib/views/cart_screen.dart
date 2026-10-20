import 'package:flutter/material.dart';
import 'package:midterm/routes/app_routes.dart';
import 'package:midterm/services/auth_service.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/cart_storage.dart';
import '../widgets/app_image.dart';
import '../widgets/app_toast.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Product> _allProducts = [];
  Map<dynamic, int> _cartQuantities = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCartAndProducts();
  }

  Future<void> _loadCartAndProducts() async {
    try {
      final loadedQuantities = await CartStorageService.loadAllCartQuantities();
      final response = await ApiService.fetchProducts(page: 1, pageSize: 50);

      setState(() {
        _cartQuantities = loadedQuantities;
        _allProducts = response.items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateQuantity(dynamic productId, int delta) async {
    final updatedMap = await CartStorageService.updateQuantity(
      productId,
      delta,
      _cartQuantities,
    );
    setState(() {
      _cartQuantities = updatedMap;
    });
  }

  Future<void> _removeItem(dynamic productId) async {
    final updatedMap = await CartStorageService.removeAndGetUpdated(
      productId,
      _cartQuantities,
    );
    setState(() {
      _cartQuantities = updatedMap;
    });
  }

  Future<void> _clearAllCart() async {
    await CartStorageService.clearAll(_cartQuantities);
    setState(() {
      _cartQuantities.clear();
    });
    if (!mounted) return;
    AppToast.showSuccess(context, 'Shopping cart cleared');
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              _clearAllCart();
            },
            child: const Text('Remove All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Auth Guard for Checkout
  Future<void> _handleCheckout() async {
    final isLoggedIn = await AuthService.isLoggedIn();

    if (!mounted) return;

    if (!isLoggedIn) {
      _showAuthPrompt();
      return;
    }

    final purchasedItems = _allProducts
        .where((product) => (_cartQuantities[product.id] ?? 0) > 0)
        .toList();

    // User is logged in -> Navigate to checkout with items
    Navigator.pushNamed(
      context,
      AppRoutes.checkout,
      arguments: {
        'items': purchasedItems,
        'quantities': Map<dynamic, int>.from(_cartQuantities),
      },
    ).then((_) {
      if (mounted) {
        _loadCartAndProducts();
      }
    });
  }

  void _showAuthPrompt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Account Required'),
        content: const Text(
          'Please sign in or create an account to proceed with your order.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, AppRoutes.register);
            },
            child: const Text('Register'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, AppRoutes.login).then((_) async {
                if (await AuthService.isLoggedIn() && mounted) {
                  Navigator.pushNamed(context, AppRoutes.checkout);
                }
              });
            },
            child: const Text('Log In', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_errorMessage'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadCartAndProducts();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final purchasedItems = _allProducts
        .where((product) => (_cartQuantities[product.id] ?? 0) > 0)
        .toList();

    if (purchasedItems.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                "Your cart is empty",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Add items to your cart to see them here.",
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final totalAmount = CartStorageService.calculateTotal(purchasedItems, _cartQuantities);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${purchasedItems.length} ${purchasedItems.length == 1 ? "Item" : "Items"} in Cart',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showClearAllDialog,
                  icon: const Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                  label: const Text(
                    'Remove All',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: purchasedItems.length,
              itemBuilder: (context, index) {
                final product = purchasedItems[index];
                final qty = _cartQuantities[product.id] ?? 1;

                return Card(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AppImageWidget(
                              imageUrl: product.imageUrl,
                              seedText: product.name,
                              width: 65,
                              height: 65,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.categoryName,
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                r"$" + product.effectivePrice.toStringAsFixed(2),
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.close,
                                size: 20,
                                color: isDark ? Colors.grey.shade400 : Colors.grey,
                              ),
                              onPressed: () => _removeItem(product.id),
                              tooltip: 'Remove Item',
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () => _updateQuantity(product.id, -1),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Icon(
                                        Icons.remove,
                                        size: 16,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text(
                                      '$qty',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () => _updateQuantity(product.id, 1),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Icon(
                                        Icons.add,
                                        size: 16,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Price',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _handleCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Checkout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}