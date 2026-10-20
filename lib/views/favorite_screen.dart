import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../data/product_data.dart';
import '../widgets/app_toast.dart';
import 'dart:convert';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<Product> _allProducts = [
    ...ProductData.popularProducts,
    ...ProductData.newProducts,
  ];

  Map<dynamic, bool> _favoritesMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoritesData();
  }

  // Get saved favorite status from local storage
  Future<void> _loadFavoritesData() async {
    try {
      final res = await ApiService.fetchProducts(page: 1, pageSize: 50);
      if (res.items.isNotEmpty) {
        _allProducts = res.items;
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    Map<dynamic, bool> loadedFavorites = {};

    for (var product in _allProducts) {
      bool isFav = prefs.getBool('fav_${product.id}') ?? false;
      if (isFav) {
        loadedFavorites[product.id] = true;
      }
    }

    if (!mounted) return;
    setState(() {
      _favoritesMap = loadedFavorites;
      _isLoading = false;
    });
  }

  // Clear all favorites from local storage
  Future<void> _clearAllFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    for (var id in _favoritesMap.keys) {
      await prefs.remove('fav_$id');
    }
    setState(() {
      _favoritesMap.clear();
    });
  }

  // Add item from Favorites directly to Shopping Cart
  Future<void> _addToCart(Product product) async {
    final prefs = await SharedPreferences.getInstance();
    int currentQty = prefs.getInt('cart_qty_${product.id}') ?? 0;
    await prefs.setInt('cart_qty_${product.id}', currentQty + 1);
    if (!mounted) return;
    AppToast.showSuccess(context, '${product.name} added to cart');
  }

  // Remove single item from favorites
  Future<void> _removeFavorite(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fav_$productId');
    setState(() {
      _favoritesMap.remove(productId);
    });
    if (!mounted) return;
    AppToast.showSuccess(context, 'Removed from favorites');
  }

  // Dialog prompt before clearing all favorites
  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Favorites'),
        content: const Text('Are you sure you want to remove all items from your favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              _clearAllFavorites();
            },
            child: const Text('Remove All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter only the products marked as favorite
    final favoriteItems = _allProducts
        .where((product) => _favoritesMap[product.id] == true)
        .toList();

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (favoriteItems.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                "No favorite items yet",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Tap the heart icon on products to see them here.",
                style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Header Bar with Item Count & Clear All Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${favoriteItems.length} ${favoriteItems.length == 1 ? "Item" : "Items"} in Favorites',
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
                    'Clear All',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // List of Favorites
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView.builder(
                itemCount: favoriteItems.length,
                itemBuilder: (context, index) {
                  final product = favoriteItems[index];

                  return Card(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: product.Imgurl.startsWith('data:image')
                              ? Image.memory(
                            base64Decode(product.Imgurl.split(',').last),
                            fit: BoxFit.cover,
                          )
                              : product.Imgurl.startsWith('http')
                              ? Image.network(
                            product.Imgurl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                          )
                              : const Icon(Icons.phone_iphone, color: Colors.blueGrey),
                        ),
                      ),
                      title: Text(
                        product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        'Category: ${product.category}',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.add_shopping_cart,
                              color: isDark ? Colors.lightBlueAccent : Colors.blue,
                            ),
                            tooltip: 'Add to Cart',
                            onPressed: () => _addToCart(product),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.favorite,
                              color: Colors.red,
                            ),
                            tooltip: 'Remove Favorite',
                            onPressed: () => _removeFavorite(product.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}