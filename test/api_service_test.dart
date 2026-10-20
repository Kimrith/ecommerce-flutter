// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:midterm/services/api_service.dart';

void main() {
  test('ApiService can fetch products and categories from local server', () async {
    final products = await ApiService.fetchProducts(page: 1, pageSize: 10);
    print('Fetched ${products.items.length} products');
    expect(products.items.isNotEmpty, true);
    print('First product: ${products.items.first.name}, price: ${products.items.first.price}, image: ${products.items.first.imageUrl}');

    final categories = await ApiService.fetchCategories();
    print('Fetched ${categories.data.length} categories');
    expect(categories.data.isNotEmpty, true);
    print('First category: ${categories.data.first.name}, image: ${categories.data.first.imageUrl}');
  });
}
