import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AppImageWidget extends StatefulWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData fallbackIcon;
  final double fallbackIconSize;
  final String? seedText;

  const AppImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.inventory_2_outlined,
    this.fallbackIconSize = 40,
    this.seedText,
  });

  @override
  State<AppImageWidget> createState() => _AppImageWidgetState();
}

class _AppImageWidgetState extends State<AppImageWidget> {
  int _attemptIndex = 0;
  List<String> _candidateUrls = [];

  @override
  void initState() {
    super.initState();
    _initUrls();
  }

  @override
  void didUpdateWidget(covariant AppImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl || oldWidget.seedText != widget.seedText) {
      _attemptIndex = 0;
      _initUrls();
    }
  }

  void _initUrls() {
    final list = <String>[];
    final primary = ApiService.buildFullImageUrl(widget.imageUrl);

    if (primary.isNotEmpty) {
      list.add(primary);

      // HTTP fallback if HTTPS fails (e.g. self-signed SSL dev cert)
      if (primary.startsWith('https://')) {
        list.add(primary.replaceFirst('https://', 'http://'));
      }

      // Android emulator fallback IP (10.0.2.2)
      if (primary.contains('localhost')) {
        final hostIpUrl = primary.replaceAll('localhost', '10.0.2.2');
        if (!list.contains(hostIpUrl)) {
          list.add(hostIpUrl);
        }
        if (hostIpUrl.startsWith('https://')) {
          final httpHostIpUrl = hostIpUrl.replaceFirst('https://', 'http://');
          if (!list.contains(httpHostIpUrl)) {
            list.add(httpHostIpUrl);
          }
        }
      }
    }

    // High quality sample product image fallback if backend image file is missing (404) or CORS blocked
    final seed = widget.seedText ?? widget.imageUrl ?? 'item';
    final cleanSeed = Uri.encodeComponent(seed.trim().isNotEmpty ? seed.trim() : 'item');
    list.add('https://picsum.photos/seed/$cleanSeed/300/300');

    _candidateUrls = list;
  }

  void _handleError() {
    if (_attemptIndex < _candidateUrls.length - 1) {
      if (mounted) {
        setState(() {
          _attemptIndex++;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_candidateUrls.isEmpty || _attemptIndex >= _candidateUrls.length) {
      return _buildFallback(context);
    }

    final currentUrl = _candidateUrls[_attemptIndex];

    // Handle Base64 Data URI
    if (currentUrl.startsWith('data:image')) {
      try {
        final base64String = currentUrl.split(',').last;
        final decodedBytes = base64Decode(base64String);
        return Image.memory(
          decodedBytes,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) {
            _handleError();
            return _buildFallback(context);
          },
        );
      } catch (e) {
        _handleError();
        return _buildFallback(context);
      }
    }

    return Image.network(
      currentUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('AppImageWidget failed loading [$currentUrl], trying candidate ${_attemptIndex + 1}');
        WidgetsBinding.instance.addPostFrameCallback((_) => _handleError());
        return _buildFallback(context);
      },
    );
  }

  Widget _buildFallback(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: widget.width,
      height: widget.height,
      color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
      child: Center(
        child: Icon(
          widget.fallbackIcon,
          size: widget.fallbackIconSize,
          color: isDark ? Colors.white38 : Colors.grey.shade400,
        ),
      ),
    );
  }
}
