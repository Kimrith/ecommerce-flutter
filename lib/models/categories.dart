class Category {
  final dynamic id;
  final String name;
  final String slug;
  final String status;
  final String? description;
  final String imageUrl;
  final int productCount;
  final dynamic userId;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.status = 'ACTIVE',
    this.description,
    required this.imageUrl,
    this.productCount = 0,
    this.userId = 0,
    this.createdBy = '',
    this.createdAt,
    this.updatedAt,
  });

  static String _parseImageUrl(Map<String, dynamic> json) {
    final possibleKeys = [
      'imageUrl',
      'image_url',
      'image',
      'img',
      'imagePath',
      'image_path',
      'categoryImage',
      'icon',
      'iconUrl',
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

  factory Category.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['Id'] ?? json['_id'];

    int count = 0;
    if (json['_count'] is Map && json['_count']['products'] != null) {
      count = (json['_count']['products'] as num).toInt();
    } else {
      count = (json['productCount'] ??
              json['ProductCount'] ??
              json['productsCount'] ??
              json['ProductsCount']) as int? ??
          0;
    }

    return Category(
      id: rawId is int ? rawId : (rawId?.toString() ?? ''),
      name: (json['name'] ?? json['Name']) as String? ?? '',
      slug: (json['slug'] ?? json['Slug']) as String? ?? '',
      status: (json['status'] ?? json['Status']) as String? ?? 'ACTIVE',
      description: (json['description'] ?? json['Description']) as String?,
      imageUrl: _parseImageUrl(json),
      productCount: count,
      userId: json['userId'] ?? json['UserId'] ?? '',
      createdBy: (json['createdBy'] ?? json['CreatedBy']) as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : json['CreatedAt'] != null
              ? DateTime.tryParse(json['CreatedAt'].toString())
              : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : json['UpdatedAt'] != null
              ? DateTime.tryParse(json['UpdatedAt'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'status': status,
      'description': description,
      'imageUrl': imageUrl,
      'productCount': productCount,
      'userId': userId,
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class CategoryResponse {
  final List<Category> data;
  final int totalItems;
  final int pageNumber;
  final int pageSize;
  final int totalPages;

  const CategoryResponse({
    required this.data,
    required this.totalItems,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
  });

  factory CategoryResponse.fromJson(dynamic json) {
    if (json is List) {
      final list = json
          .whereType<Map<String, dynamic>>()
          .map((item) => Category.fromJson(item))
          .toList();
      return CategoryResponse(
        data: list,
        totalItems: list.length,
        pageNumber: 1,
        pageSize: list.isNotEmpty ? list.length : 10,
        totalPages: 1,
      );
    } else if (json is Map<String, dynamic>) {
      final rawData = json['data'] ??
          json['Data'] ??
          json['items'] ??
          json['Items'] ??
          json['result'] ??
          json['Result'] ??
          json['values'] ??
          json[r''] ??
          [];
      final list = (rawData as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map((item) => Category.fromJson(item))
              .toList() ??
          [];

      final total = (json['totalItems'] ??
          json['TotalItems'] ??
          json['total'] ??
          json['Total'] ??
          list.length) as int? ?? list.length;
      final page = (json['pageNumber'] ?? json['PageNumber'] ?? 1) as int? ?? 1;
      final size = (json['pageSize'] ?? json['PageSize'] ?? 10) as int? ?? 10;
      final pages = (json['totalPages'] ?? json['TotalPages'] ?? 1) as int? ?? 1;

      return CategoryResponse(
        data: list,
        totalItems: total,
        pageNumber: page,
        pageSize: size,
        totalPages: pages,
      );
    }

    return const CategoryResponse(
      data: [],
      totalItems: 0,
      pageNumber: 1,
      pageSize: 10,
      totalPages: 1,
    );
  }
}
