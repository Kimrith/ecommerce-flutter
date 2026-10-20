import 'package:flutter/material.dart';
import 'package:midterm/Auth/login.dart';
import 'package:midterm/Auth/register.dart';
import 'package:midterm/main.dart';
import 'package:midterm/models/product.dart';
import 'package:midterm/services/auth_service.dart';
import 'package:midterm/views/cart_screen.dart';
import 'package:midterm/views/favorite_screen.dart';
import 'package:midterm/views/checkout_screen.dart';
import 'package:midterm/views/product_screeen.dart';
import 'package:midterm/views/profile_screen.dart';
import 'package:midterm/views/splash_screen.dart';
import 'package:midterm/widgets/product_detail.dart';

class AppRoutes {
  // Route Names
  static const String splash = '/splash';
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  static const String product = '/product';
  static const String productDetail = '/productDetail';
  static const String cart = '/cart';
  static const String favorite = '/favorite';
  static const String profile = '/profile';
  static const String checkout = '/checkout';

  // Routes Map
  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashScreen(),
      home: (context) => const MainNavigationScreen(),
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      product: (context) => const ProductScreen(),
      checkout: (context) => const CheckoutScreen(),
      productDetail: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Product) {
          return ProductDetail(product: args);
        }
        return const Scaffold(
          body: Center(child: Text('Product not found')),
        );
      },
      cart: (context) => const CartScreen(),
      favorite: (context) => const FavoriteScreen(),
      profile: (context) => const ProfileScreen(),
      // checkout: (context) => const CheckoutScreen(),
    };
  }

  /// Auth Guard: Executes [onAuthenticated] if logged in,
  /// otherwise prompts to Login or Register.
  static Future<void> requireAuth(
      BuildContext context, {
        required VoidCallback onAuthenticated,
      }) async {
    final isLoggedIn = await AuthService.isLoggedIn();

    if (!context.mounted) return;

    if (isLoggedIn) {
      onAuthenticated();
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Sign in Required'),
          content: const Text(
            'You need an account to proceed to checkout. Please sign in or register.',
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
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRoutes.login).then((_) async {
                  if (await AuthService.isLoggedIn() && context.mounted) {
                    onAuthenticated();
                  }
                });
              },
              child: const Text('Sign In'),
            ),
          ],
        ),
      );
    }
  }
}