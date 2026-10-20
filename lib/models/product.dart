class Product {
  final dynamic id;
  final String name;
  final String slug;
  final String? description;
  final double price;
  final double discountPrice;
  final double effectivePrice;
  final int stockQuantity;
  final int availableQuantity;
  final String? size;
  final String? color;
  final String imageUrl;
  final String status;
  final DateTime? publishAt;
  final dynamic categoryId;
  final String categoryName;
  final dynamic sellerId;
  final String sellerName;
  final String sellerRole;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<dynamic> variants;

  // Local UI state (not from API)
  final bool isCartRed;

  // Compatibility getters
  // ignore: non_constant_identifier_names
  String get Imgurl => imageUrl;
  String get category => categoryName;

  const Product({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    this.discountPrice = 0.0,
    required this.effectivePrice,
    this.stockQuantity = 0,
    this.availableQuantity = 0,
    this.size,
    this.color,
    required this.imageUrl,
    this.status = 'ACTIVE',
    this.publishAt,
    this.categoryId = '',
    this.categoryName = '',
    this.sellerId = '',
    this.sellerName = '',
    this.sellerRole = '',
    this.createdAt,
    this.updatedAt,
    this.variants = const [],
    this.isCartRed = false,
  });

  static String _parseImageUrl(Map<String, dynamic> json) {
    final possibleKeys = [
      'imageUrl',
      'image_url',
      'image',
      'img',
      'imagePath',
      'image_path',
      'productImage',
      'mainImage',
      'primaryImage',
      'coverImage',
      'file',
      'filePath',
      'file_path',
      'picture',
      'photo',
      'thumbnail',
      'src',
      'avatar',
      'cover',
    ];

    for (final key in possibleKeys) {
      if (json.containsKey(key) && json[key] != null) {
        final val = json[key];
        if (val is String && val.trim().isNotEmpty) {
          return val.trim();
        } else if (val is Map) {
          final urlVal = val['url'] ?? val['src'] ?? val['path'];
          if (urlVal is String && urlVal.trim().isNotEmpty) {
            return urlVal.trim();
          }
        }
      }
    }

    final listKeys = ['images', 'photos', 'pictures', 'gallery'];
    for (final key in listKeys) {
      if (json.containsKey(key) && json[key] is List) {
        final list = json[key] as List;
        if (list.isNotEmpty) {
          final first = list.first;
          if (first is String && first.trim().isNotEmpty) {
            return first.trim();
          } else if (first is Map) {
            final urlVal = first['url'] ?? first['src'] ?? first['path'];
            if (urlVal is String && urlVal.trim().isNotEmpty) {
              return urlVal.trim();
            }
          }
        }
      }
    }

    return '';
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['Id'] ?? json['_id'];

    // Category extraction
    String catName = '';
    dynamic catId = json['categoryId'] ?? json['CategoryId'];
    if (json['category'] is Map<String, dynamic>) {
      catName = json['category']['name']?.toString() ?? '';
      catId ??= json['category']['id'];
    } else if (json['category'] is String) {
      catName = json['category'];
    } else if (json['categoryName'] != null) {
      catName = json['categoryName'].toString();
    }

    final double priceVal = (json['price'] as num?)?.toDouble() ?? 0.0;
    final double discountVal = (json['discountPrice'] as num?)?.toDouble() ?? 0.0;
    final double effectiveVal = (json['effectivePrice'] as num?)?.toDouble() ?? (discountVal > 0 ? discountVal : priceVal);
    final int stockVal = (json['stock'] as num?)?.toInt() ?? (json['stockQuantity'] as num?)?.toInt() ?? 0;
    final int availableVal = (json['availableQuantity'] as num?)?.toInt() ?? stockVal;

    return Product(
      id: rawId is int ? rawId : (rawId?.toString() ?? ''),
      name: (json['name'] ?? json['Name']) as String? ?? '',
      slug: (json['slug'] ?? json['Slug']) as String? ?? '',
      description: (json['description'] ?? json['Description']) as String?,
      price: priceVal,
      discountPrice: discountVal,
      effectivePrice: effectiveVal,
      stockQuantity: stockVal,
      availableQuantity: availableVal,
      size: json['size'] as String?,
      color: json['color'] as String?,
      imageUrl: _parseImageUrl(json),
      status: json['status'] as String? ?? 'ACTIVE',
      publishAt: json['publishAt'] != null
          ? DateTime.tryParse(json['publishAt'].toString())
          : null,
      categoryId: catId is int ? catId : (catId?.toString() ?? ''),
      categoryName: catName,
      sellerId: json['sellerId'] is int ? json['sellerId'] : (json['sellerId']?.toString() ?? ''),
      sellerName: json['sellerName'] as String? ?? '',
      sellerRole: json['sellerRole'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      variants: json['variants'] as List<dynamic>? ?? [],
      isCartRed: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'price': price,
      'discountPrice': discountPrice,
      'effectivePrice': effectivePrice,
      'stockQuantity': stockQuantity,
      'availableQuantity': availableQuantity,
      'size': size,
      'color': color,
      'imageUrl': imageUrl,
      'status': status,
      'publishAt': publishAt?.toIso8601String(),
      'categoryId': categoryId,
      'categoryName': categoryName,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerRole': sellerRole,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'variants': variants,
      'isCartRed': isCartRed,
    };
  }

  Product copyWith({
    dynamic id,
    String? name,
    String? slug,
    String? description,
    double? price,
    double? discountPrice,
    double? effectivePrice,
    int? stockQuantity,
    int? availableQuantity,
    String? size,
    String? color,
    String? imageUrl,
    String? status,
    DateTime? publishAt,
    dynamic categoryId,
    String? categoryName,
    dynamic sellerId,
    String? sellerName,
    String? sellerRole,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<dynamic>? variants,
    bool? isCartRed,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      effectivePrice: effectivePrice ?? this.effectivePrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      size: size ?? this.size,
      color: color ?? this.color,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      publishAt: publishAt ?? this.publishAt,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerRole: sellerRole ?? this.sellerRole,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      variants: variants ?? this.variants,
      isCartRed: isCartRed ?? this.isCartRed,
    );
  }
}

class ProductResponse {
  final List<Product> items;
  final int totalItems;
  final int pageNumber;
  final int pageSize;
  final int totalPages;

  const ProductResponse({
    required this.items,
    required this.totalItems,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
  });

  factory ProductResponse.fromJson(dynamic json) {
    if (json is List) {
      final list = json
          .whereType<Map<String, dynamic>>()
          .map((item) => Product.fromJson(item))
          .toList();
      return ProductResponse(
        items: list,
        totalItems: list.length,
        pageNumber: 1,
        pageSize: list.isNotEmpty ? list.length : 10,
        totalPages: 1,
      );
    }

    if (json is Map<String, dynamic>) {
      final Map<String, dynamic> container = (json['data'] is Map<String, dynamic>)
          ? json['data'] as Map<String, dynamic>
          : json;

      final rawItems = container['items'] ??
          container['products'] ??
          (json['data'] is List ? json['data'] : null) ??
          [];

      final list = (rawItems as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map((item) => Product.fromJson(item))
              .toList() ??
          [];

      final meta = (container['meta'] is Map<String, dynamic>)
          ? container['meta'] as Map<String, dynamic>
          : <String, dynamic>{};

      final total = (meta['total'] ??
          meta['totalItems'] ??
          container['totalItems'] ??
          container['total'] ??
          list.length) as int? ?? list.length;
      final page = (meta['page'] ?? meta['pageNumber'] ?? container['pageNumber'] ?? 1) as int? ?? 1;
      final size = (meta['limit'] ?? meta['pageSize'] ?? container['pageSize'] ?? 10) as int? ?? 10;
      final pages = (meta['totalPages'] ?? container['totalPages'] ?? 1) as int? ?? 1;

      return ProductResponse(
        items: list,
        totalItems: total,
        pageNumber: page,
        pageSize: size,
        totalPages: pages,
      );
    }

    return const ProductResponse(
      items: [],
      totalItems: 0,
      pageNumber: 1,
      pageSize: 10,
      totalPages: 1,
    );
  }
}
