import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/cart_storage.dart';
import '../widgets/product_card.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  List<Product> _products = [];
  Map<dynamic, int> _cartQuantities = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProductsAndCart();
  }

  Future<void> _loadProductsAndCart() async {
    try {
      final loadedQuantities = await CartStorageService.loadAllCartQuantities();
      final response = await ApiService.fetchProducts(page: 1, pageSize: 50);

      setState(() {
        _cartQuantities = loadedQuantities;
        _products = response.items;
        _isLoading = false;
      });
    } catch (e) {
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
                  _loadProductsAndCart();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final displayProducts = _products.map(_applyCartStatus).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: displayProducts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemBuilder: (context, index) {
            final product = displayProducts[index];
            return ProductCard(product: product);
          },
        ),
      ),
    );
  }
}
