import 'package:flutter/material.dart';
import '../models/categories.dart';
import 'app_image.dart';

class CategoryItem extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;

  const CategoryItem({
    super.key,
    required this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
              ),
              child: ClipOval(
                child: AppImageWidget(
                  imageUrl: category.imageUrl,
                  seedText: category.name,
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.category_outlined,
                  fallbackIconSize: 26,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade300 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}