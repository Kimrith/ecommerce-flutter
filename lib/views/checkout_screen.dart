import 'package:flutter/material.dart';
import 'package:midterm/config/app_colors.dart';
import 'package:midterm/models/product.dart';
import 'package:midterm/services/api_service.dart';
import 'package:midterm/services/auth_service.dart';
import 'package:midterm/services/cart_storage.dart';
import 'package:midterm/widgets/app_image.dart';
import 'package:midterm/widgets/app_toast.dart';
import 'package:midterm/widgets/khqr_payment_dialog.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Cart products and quantities
  List<Product> _items = [];
  Map<dynamic, int> _quantities = {};

  // Editable shipping details
  String _recipientName = 'Customer';
  String _shippingAddress = 'Street 2004, Teuk Thla, Sen Sok, Phnom Penh';
  String _contactPhone = '+855 12 345 678';

  // Order financial calculations
  double get _subtotal {
    double sum = 0.0;
    for (final item in _items) {
      final qty = _quantities[item.id] ?? 1;
      sum += item.effectivePrice * qty;
    }
    return sum;
  }

  double get _discount => 0.00;
  double get _total => _subtotal - _discount;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      _initCheckoutData(args);
    }
  }

  Future<void> _initCheckoutData(Object? args) async {
    final user = await AuthService.getCurrentUser();
    if (user != null) {
      _recipientName = user.name.isNotEmpty ? user.name : 'Customer';
      if (user.phone != null && user.phone!.isNotEmpty) {
        _contactPhone = user.phone!;
      }
    }

    // Try reading arguments passed from CartScreen
    if (args is Map) {
      final passedItems = args['items'];
      final passedQuantities = args['quantities'];

      if (passedItems is List<Product> && passedItems.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _items = List<Product>.from(passedItems);
          if (passedQuantities is Map) {
            _quantities = Map<dynamic, int>.from(passedQuantities);
          }
          _isLoading = false;
        });
        return;
      }
    }

    // Fallback: Dynamically load cart quantities from SharedPreferences
    try {
      final storedQuantities = await CartStorageService.loadAllCartQuantities();
      if (storedQuantities.isNotEmpty) {
        final productResponse = await ApiService.fetchProducts(page: 1, pageSize: 50);
        final matchedItems = productResponse.items
            .where((p) => (storedQuantities[p.id] ?? 0) > 0)
            .toList();

        if (mounted) {
          setState(() {
            _items = matchedItems;
            _quantities = storedQuantities;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading checkout cart: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showEditAddressModal() {
    final nameCtrl = TextEditingController(text: _recipientName);
    final phoneCtrl = TextEditingController(text: _contactPhone);
    final addrCtrl = TextEditingController(text: _shippingAddress);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Delivery Address',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Recipient Name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Contact Phone',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addrCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Full Delivery Address',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (addrCtrl.text.trim().isEmpty) {
                    AppToast.showError(context, 'Please enter a shipping address');
                    return;
                  }
                  setState(() {
                    _recipientName = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : _recipientName;
                    _contactPhone = phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : _contactPhone;
                    _shippingAddress = addrCtrl.text.trim();
                  });
                  Navigator.pop(ctx);
                  AppToast.showSuccess(context, 'Address updated successfully');
                },
                child: const Text('Save Address', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePlaceOrder() async {
    if (_items.isEmpty) {
      AppToast.showError(context, 'Your cart is empty');
      return;
    }

    // Bakong KHQR Payment Flow
    await _processKhqrOrder();
  }

  // KHQR / Bakong Flow: Create PENDING order -> Generate KHQR -> Popup QR -> User pays -> Verify -> Push PAID to DB
  Future<void> _processKhqrOrder() async {
    setState(() => _isSubmitting = true);

    try {
      final orderItems = _items.map((item) => {
        'productId': item.id.toString(),
        'quantity': _quantities[item.id] ?? 1,
      }).toList();

      final fullShippingInfo = '$_shippingAddress (Recipient: $_recipientName, Phone: $_contactPhone)';

      // 1. Create order in Database (status: PENDING)
      final orderData = await ApiService.createOrder(
        items: orderItems,
        shippingAddressString: fullShippingInfo,
        paymentMethod: 'BAKONG_KHQR',
      );

      final orderId = (orderData['id'] ?? orderData['_id']).toString();
      final orderNumber = (orderData['orderNumber'] ?? 'ORD').toString();

      // 2. Request Bakong KHQR QR Code generation from backend
      final khqrData = await ApiService.generateKhqr(
        orderId: orderId,
        currency: 'USD',
      );

      final qrCode = (khqrData['qrCode'] ?? '').toString();
      final md5 = (khqrData['md5'] ?? '').toString();
      final amount = (khqrData['totalAmount'] is num)
          ? (khqrData['totalAmount'] as num).toDouble()
          : _total;
      final khqrString = khqrData['khqrString']?.toString();
      final deepLink = khqrData['deepLink']?.toString();

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // 3. Show KHQR Payment Popup Dialog (User scans to pay first)
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => KhqrPaymentDialog(
          orderId: orderId,
          orderNumber: orderNumber,
          totalAmount: amount,
          qrCodeBase64: qrCode,
          md5: md5,
          khqrString: khqrString,
          deepLink: deepLink,
          onPaymentSuccess: () async {
            // 4. On successful verification, clear the cart storage and show confirmation
            await CartStorageService.clearCart(_items.map((e) => e.id));
            if (!mounted) return;
            _showOrderSuccessDialog(orderNumber: orderNumber);
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.showError(context, 'Failed to initiate KHQR payment: ${e.toString()}');
    }
  }

  void _showOrderSuccessDialog({required String orderNumber}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 60,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment & Order Successful!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your Bakong KHQR payment was successfully verified. The order is now recorded in the database.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Order Number:'),
                  Text(
                    orderNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop(); // close dialog
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Delivery Information Section
            _buildSectionHeader('Delivery Address', Icons.location_on_outlined),
            const SizedBox(height: 8),
            _buildAddressCard(isDark),

            const SizedBox(height: 20),

            // 2. Order Items Review
            _buildSectionHeader('Order Items (${_items.length})', Icons.shopping_bag_outlined),
            const SizedBox(height: 8),
            _buildOrderItemsCard(isDark),

            const SizedBox(height: 20),

            // 3. Payment Method Selector
            _buildSectionHeader('Payment Method', Icons.payment_outlined),
            const SizedBox(height: 8),
            _buildPaymentMethods(isDark),

            const SizedBox(height: 20),

            // 4. Order Summary
            _buildSectionHeader('Order Summary', Icons.receipt_long_outlined),
            const SizedBox(height: 8),
            _buildOrderSummaryCard(isDark),

            const SizedBox(height: 28),
          ],
        ),
      ),
      // Sticky Bottom Bar for Final Action
      bottomNavigationBar: _buildBottomCheckoutBar(isDark),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _recipientName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              InkWell(
                onTap: _showEditAddressModal,
                child: const Text(
                  'Change',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.phone, size: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                _contactPhone,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _shippingAddress,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsCard(bool isDark) {
    if (_items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
        ),
        child: const Center(
          child: Text('No items in checkout.'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const Divider(height: 16),
        itemBuilder: (context, index) {
          final item = _items[index];
          final qty = _quantities[item.id] ?? 1;
          final lineTotal = item.effectivePrice * qty;

          return Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AppImageWidget(
                  imageUrl: item.imageUrl,
                  width: 55,
                  height: 55,
                  fit: BoxFit.cover,
                  seedText: item.name,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${item.effectivePrice.toStringAsFixed(2)} x $qty',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${lineTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentMethods(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary,
          width: 1.6,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.qr_code_scanner,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'KHQR / Bakong',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Instant Pay',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Scan QR with any Bakong banking app (ABA, Wing, ACLEDA...)',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: AppColors.primary,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', '\$${_subtotal.toStringAsFixed(2)}', isDark),
          if (_discount > 0) ...[
            const SizedBox(height: 10),
            _buildSummaryRow('Discount', '-\$${_discount.toStringAsFixed(2)}', isDark, isDiscount: true),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${_total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDiscount ? Colors.green : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCheckoutBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Pay',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                Text(
                  '\$${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: (_isSubmitting || _items.isEmpty) ? null : _handlePlaceOrder,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Pay with KHQR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}