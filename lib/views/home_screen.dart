import 'package:flutter/material.dart';
import '../models/categories.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/cart_storage.dart';
import '../widgets/banner.dart';
import '../widgets/category_item.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<dynamic, int> _cartQuantities = {};
  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        CartStorageService.loadAllCartQuantities(),
        ApiService.fetchProducts(page: 1, pageSize: 20),
        ApiService.fetchCategories(page: 1, pageSize: 20),
      ]);

      if (!mounted) return;

      setState(() {
        _cartQuantities = results[0] as Map<dynamic, int>;
        _products = (results[1] as ProductResponse).items;
        _categories = (results[2] as CategoryResponse).data;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Product _applyCartStatus(Product p) {
    final qty = _cartQuantities[p.id] ?? 0;
    return p.copyWith(isCartRed: qty > 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Failed to load content',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _isLoading = true);
                    _loadInitialData();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final displayProducts = _products.map(_applyCartStatus).toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PromoBanner(),
                const SizedBox(height: 20),

                // Categories Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'See All',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Categories List (Remote API Data)
                SizedBox(
                  height: 90,
                  child: _categories.isEmpty
                      ? const Center(
                    child: Text(
                      'No categories found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                      : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      return CategoryItem(category: _categories[index]);
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Popular Products Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Popular Products',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'See All',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Popular Products List
                SizedBox(
                  height: 270,
                  child: displayProducts.isEmpty
                      ? const Center(
                    child: Text(
                      'No products available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                      : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: displayProducts.length,
                    separatorBuilder: (context, index) =>
                    const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return ProductCard(
                        product: displayProducts[index],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // New Products Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New Products',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'See All',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // New Products List (reversed order as an example of recent entries)
                SizedBox(
                  height: 270,
                  child: displayProducts.isEmpty
                      ? const Center(
                    child: Text(
                      'No products available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                      : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: displayProducts.length,
                    separatorBuilder: (context, index) =>
                    const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return ProductCard(
                        product: displayProducts.reversed.toList()[index],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
