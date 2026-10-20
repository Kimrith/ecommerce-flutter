import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/product.dart';
import 'product_detail.dart';

class FavoriteItem extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;
  final VoidCallback onRemoveFavorite;

  const FavoriteItem({
    super.key,
    required this.product,
    required this.onAddToCart,
    required this.onRemoveFavorite,
  });

  Widget _buildProductImage(String imgUrl) {
    if (imgUrl.startsWith('data:image')) {
      try {
        final base64String = imgUrl.split(',').last;
        final decodedBytes = base64Decode(base64String);
        return Image.memory(decodedBytes, fit: BoxFit.cover);
      } catch (e) {
        return const Icon(Icons.broken_image, size: 24, color: Colors.grey);
      }
    } else if (imgUrl.startsWith('http')) {
      return Image.network(
        imgUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, size: 24, color: Colors.grey),
      );
    } else {
      return const Icon(Icons.phone_iphone, size: 28, color: Colors.blueGrey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetail(product: product),
            ),
          );
        },
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildProductImage(product.Imgurl),
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
              tooltip: 'Add to Cart & View Detail',
              onPressed: () {
                onAddToCart();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetail(product: product),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.favorite,
                color: Colors.red,
              ),
              tooltip: 'Remove Favorite',
              onPressed: onRemoveFavorite,
            ),
          ],
        ),
      ),
    );
  }
}
