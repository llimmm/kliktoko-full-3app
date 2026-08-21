import 'package:flutter/foundation.dart';
import '../service/api_service.dart';

/// Satu ukuran dari sebuah produk beserta stoknya sendiri.
///
/// Backend menyimpan stok di tabel product_variants; `Product.stock` hanya
/// kolom cermin dari totalnya. Untuk toko seragam, yang menentukan pembeli
/// pulang dengan tangan kosong adalah stok per ukuran, bukan totalnya.
///
/// `id` di sini adalah `product_variant_id` yang wajib dikirim ke
/// POST /api/sales — tanpa itu backend menolak produk multi-ukuran.
class ProductVariant {
  final int id;
  final String size;
  final int stock;

  const ProductVariant({
    required this.id,
    required this.size,
    required this.stock,
  });

  bool get isOutOfStock => stock == 0;
  bool get isLow => stock > 0 && stock <= 5;

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: int.tryParse(json['id'].toString()) ?? 0,
      // API mengirim relasi size yang sudah di-eager-load.
      size: (json['size'] is Map ? json['size']['code'] : null)?.toString() ??
          '?',
      stock: int.tryParse(json['stock_quantity'].toString()) ?? 0,
    );
  }
}

class Product {
  final String id;
  final String name;
  final String size;
  final int stock;
  final bool isNew;
  final double price;
  final String? imageUrl;
  final String category;
  final String? imagePath;
  final String code;
  final int? categoryId;
  final int? sizeId;
  final String? barcode; // New field for barcode
  final List<ProductVariant> variants;

  Product({
    required this.id,
    required this.name,
    required this.size,
    required this.stock,
    required this.isNew,
    required this.price,
    this.imageUrl,
    this.imagePath,
    required this.category,
    required this.code,
    this.categoryId,
    this.sizeId,
    this.barcode,
    this.variants = const [],
  });

  // Generate ISBN barcode from product ID
  String get isbnBarcode {
    if (barcode != null && barcode!.isNotEmpty) {
      return barcode!;
    }
    // Generate ISBN-13 format from product ID
    return _generateIsbn13(id);
  }

  // Generate ISBN-13 barcode
  String _generateIsbn13(String productId) {
    // Convert product ID to 12 digits
    String base = productId.padLeft(12, '0').substring(0, 12);

    // Calculate check digit for ISBN-13
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      int digit = int.parse(base[i]);
      sum += digit * (i % 2 == 0 ? 1 : 3);
    }

    int checkDigit = (10 - (sum % 10)) % 10;
    return base + checkDigit.toString();
  }

  // Getter for the best available image URL
  String? get image {
    // First try imagePath as it's the most reliable
    if (imagePath != null && imagePath!.isNotEmpty) {
      return ApiService.getFullImageUrl(imagePath);
    }

    // Then try imageUrl
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      // If it's not already a full URL, convert it
      if (!imageUrl!.startsWith('http://') &&
          !imageUrl!.startsWith('https://')) {
        return ApiService.getFullImageUrl(imageUrl);
      }
      return imageUrl;
    }

    return null;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print('Parsing product JSON: ${json['name']}');
    }

    // Extract all possible image fields for debugging
    final imageFields = <String, dynamic>{};
    for (final key in json.keys) {
      if (key.toLowerCase().contains('image') ||
          key.toLowerCase().contains('photo')) {
        imageFields[key] = json[key];
      }
    }

    if (kDebugMode && imageFields.isNotEmpty) {
      print('Found image fields: $imageFields');
    }

    // Extract image from different possible field names
    String? extractedImageUrl = json['imageUrl'] as String? ??
        json['image_url'] as String? ??
        json['image'] as String? ??
        json['photo'] as String? ??
        json['photo_url'] as String?;

    // Extract imagePath specifically - this is often the most reliable
    String? extractedImagePath = json['image_path'] as String? ??
        json['path'] as String? ??
        json['photo_path'] as String?;

    if (kDebugMode) {
      print('Extracted imageUrl: $extractedImageUrl');
      print('Extracted imagePath: $extractedImagePath');
    }

    return Product(
      id: json['id']?.toString() ??
          json['product_id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ??
          json['product_name'] as String? ??
          'Unknown',
      size: json['size'] as String? ?? json['product_size'] as String? ?? '-',
      stock: json['stock'] is int
          ? json['stock'] as int
          : json['stock_quantity'] is int
              ? json['stock_quantity'] as int
              : int.tryParse(json['stock']?.toString() ??
                      json['stock_quantity']?.toString() ??
                      '0') ??
                  0,
      isNew: json['isNew'] == true || json['is_new'] == true,
      price: json['price'] is num
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price'].toString()) ?? 0.0,
      imageUrl: extractedImageUrl,
      imagePath: extractedImagePath,
      category: json['category'] as String? ??
          json['product_category'] as String? ??
          'Uncategorized',
      code: json['code']?.toString() ?? '',
      categoryId: json['category_id'] is int
          ? json['category_id'] as int
          : int.tryParse(json['category_id']?.toString() ?? ''),
      sizeId: json['size_id'] is int
          ? json['size_id'] as int
          : int.tryParse(json['size_id']?.toString() ?? ''),
      barcode: json['barcode'] as String?,
      // Kosong kalau backend belum mengirim variants — kasir jatuh ke total
      // stok lama, jadi API versi lebih tua tidak merusak apa pun.
      variants: json['variants'] is List
          ? (json['variants'] as List)
              .whereType<Map<String, dynamic>>()
              .map(ProductVariant.fromJson)
              .toList()
          : const [],
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? size,
    int? stock,
    bool? isNew,
    double? price,
    String? imageUrl,
    String? imagePath,
    String? category,
    String? code,
    int? categoryId,
    int? sizeId,
    String? barcode,
    List<ProductVariant>? variants,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      size: size ?? this.size,
      stock: stock ?? this.stock,
      isNew: isNew ?? this.isNew,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      code: code ?? this.code,
      categoryId: categoryId ?? this.categoryId,
      sizeId: sizeId ?? this.sizeId,
      barcode: barcode ?? this.barcode,
      variants: variants ?? this.variants,
    );
  }
}
