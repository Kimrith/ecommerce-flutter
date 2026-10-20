import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:midterm/services/api_service.dart';

class KhqrPaymentDialog extends StatefulWidget {
  final String orderId;
  final String orderNumber;
  final double totalAmount;
  final String qrCodeBase64;
  final String md5;
  final String? khqrString;
  final String? deepLink;
  final VoidCallback onPaymentSuccess;

  const KhqrPaymentDialog({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.totalAmount,
    required this.qrCodeBase64,
    required this.md5,
    this.khqrString,
    this.deepLink,
    required this.onPaymentSuccess,
  });

  @override
  State<KhqrPaymentDialog> createState() => _KhqrPaymentDialogState();
}

class _KhqrPaymentDialogState extends State<KhqrPaymentDialog> {
  Timer? _countdownTimer;
  Timer? _pollingTimer;
  int _remainingSeconds = 300; // 5 minutes standard KHQR expiry
  bool _isChecking = false;
  Uint8List? _qrBytes;

  @override
  void initState() {
    super.initState();
    _decodeQrImage();
    _startCountdownTimer();
    _startPolling();
  }

  void _decodeQrImage() {
    try {
      String raw = widget.qrCodeBase64.trim();
      if (raw.contains(',')) {
        raw = raw.split(',').last;
      }
      _qrBytes = base64Decode(raw);
    } catch (e) {
      debugPrint('Failed to decode QR code base64: $e');
    }
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        _pollingTimer?.cancel();
      }
    });
  }

  // Automatic polling every 3 seconds to check payment status
  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (_isChecking || !mounted) return;
    _isChecking = true;

    try {
      final result = await ApiService.verifyKhqr(
        orderId: widget.orderId,
        md5: widget.md5,
      );

      final isPaid = result['isPaid'] == true || result['status'] == 'SUCCESS';

      if (isPaid && mounted) {
        _pollingTimer?.cancel();
        _countdownTimer?.cancel();
        Navigator.of(context).pop(); // close modal
        widget.onPaymentSuccess();
        return;
      }
    } catch (e) {
      debugPrint('Auto verification poll error: $e');
    } finally {
      if (mounted) {
        _isChecking = false;
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Official Bakong KHQR Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: const BoxDecoration(
                  color: Color(0xFFE53935),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'KHQR',
                            style: TextStyle(
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Bakong Payment',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'National Bank of Cambodia',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Merchant & Order details
                    Text(
                      'AH LEANG STORE',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order: ${widget.orderNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Amount display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE53935).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        '\$${widget.totalAmount.toStringAsFixed(2)} USD',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE53935),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // QR Code Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_qrBytes != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _qrBytes!,
                                width: 220,
                                height: 220,
                                fit: BoxFit.contain,
                              ),
                            )
                          else
                            const SizedBox(
                              width: 220,
                              height: 220,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFE53935),
                                ),
                              ),
                            ),
                          // KHQR Center Badge
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.qr_code_2,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Countdown timer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: _remainingSeconds < 60 ? Colors.red : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Expires in: $_formattedTime',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _remainingSeconds < 60
                                ? Colors.red
                                : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Supported Banking Apps hint
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Scan with any Bakong-enabled app (Bakong, ABA, Wing, ACLEDA, Sathapana)',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.3,
                                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Auto-verification live status indicator
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE53935).withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Color(0xFFE53935),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Checking payment every 3s...',
                            style: TextStyle(
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Cancel / Close
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel Payment',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
