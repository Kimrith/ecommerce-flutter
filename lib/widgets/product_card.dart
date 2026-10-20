import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../routes/app_routes.dart';
import '../widgets/app_toast.dart';

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({
    super.key,
    required this.product,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isFavorite = false;
  int _quantity = 0;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFavorite = prefs.getBool('fav_${widget.product.id}') ?? false;
      int defaultCart = widget.product.isCartRed ? 1 : 0;
      _quantity = prefs.getInt('cart_qty_${widget.product.id}') ?? defaultCart;
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFavorite = !_isFavorite;
    });
    await prefs.setBool('fav_${widget.product.id}', _isFavorite);

    if (!mounted) return;
    AppToast.toggleFavorite(context, widget.product.name, _isFavorite);
  }

  Future<void> _incrementCart() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _quantity++;
    });
    await prefs.setInt('cart_qty_${widget.product.id}', _quantity);

    if (!mounted) return;
    AppToast.successCart(context, widget.product.name, _quantity);
  }

  // Helper widget to handle rendering Base64, Network, or Fallback images
  Widget _buildProductImage() {
    final imgUrl = widget.product.Imgurl;

    if (imgUrl.startsWith('data:image')) {
      try {
        final base64String = imgUrl.split(',').last;
        final decodedBytes = base64Decode(base64String);

        return Image.memory(
          decodedBytes,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey));
          },
        );
      } catch (e) {
        return const Center(child: Icon(Icons.error, size: 40, color: Colors.red));
      }
    } else if (imgUrl.startsWith('http')) {
      return Image.network(
        imgUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey));
        },
      );
    } else {
      return const Center(
        child: Icon(Icons.phone_iphone, size: 60, color: Colors.blueGrey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isInCart = _quantity > 0;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.productDetail,
          arguments: widget.product,
        );
      },
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 110,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildProductImage(),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF333333) : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: _isFavorite
                              ? Colors.red
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        onPressed: _toggleFavorite,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                widget.product.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                widget.product.category,
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${widget.product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  GestureDetector(
                    onTap: _incrementCart,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: isInCart
                            ? Colors.red
                            : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 16,
                            color: isInCart
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                          if (_quantity > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '$_quantity',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}