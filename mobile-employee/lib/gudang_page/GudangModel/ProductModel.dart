import 'package:kliktoko/APIService/ApiService.dart';

/// Satu ukuran dari sebuah produk beserta stoknya sendiri.
///
/// Backend menyimpan stok di tabel product_variants; `Product.stock` hanya
/// kolom cermin dari totalnya. Untuk toko seragam, yang menentukan pembeli
/// pulang dengan tangan kosong adalah stok per ukuran, bukan totalnya.
class ProductVariant {
  final int id;
  final String size;
  final int stock;

  ProductVariant({required this.id, required this.size, required this.stock});

  bool get isOutOfStock => stock == 0;
  bool get isLow => stock > 0 && stock <= 5;

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: int.tryParse(json['id'].toString()) ?? 0,
      // API mengirim relasi size yang sudah di-eager-load.
      size: (json['size'] is Map ? json['size']['code'] : null)?.toString() ?? '?',
      stock: int.tryParse(json['stock_quantity'].toString()) ?? 0,
    );
  }
}

class Product {
  final int? id;
  final String name;
  final String size;
  final int stock;
  final bool isNew;
  final double price;
  final String? imagePath;
  final String? description;
  final String? code;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? categoryId;
  final int? sizeId;
  final List<ProductVariant> variants;

  Product({
    this.id,
    required this.name,
    required this.size,
    required this.stock,
    required this.isNew,
    required this.price,
    this.imagePath,
    this.description,
    this.code,
    this.createdAt,
    this.updatedAt,
    this.categoryId,
    this.sizeId,
    this.variants = const [],
  });

  /// Kode ukuran yang stoknya nol, mis. ['M'] untuk Jaket Abu Sekolah.
  List<String> get outOfStockSizes =>
      variants.where((v) => v.isOutOfStock).map((v) => v.size).toList();

  /// Apakah produk ini perlu muncul di peringatan "Stok Habis".
  ///
  /// Untuk toko seragam, satu ukuran habis sudah berarti pembeli pulang dengan
  /// tangan kosong — walau total stok produknya masih puluhan. Memakai `stock`
  /// (kolom cermin dari jumlah seluruh varian) menyembunyikan persis keadaan
  /// itu: Jaket Abu Sekolah total 39 tapi ukuran M nol, dan peringatannya
  /// tidak pernah muncul. Produk tanpa variants (API lama) jatuh ke total.
  bool get hasOutOfStockSize =>
      variants.isEmpty ? stock == 0 : outOfStockSizes.isNotEmpty;

  // Getter for full image URL
  String? get image {
    return imagePath != null ? ApiService.getFullImageUrl(imagePath) : null;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      name: json['name'] as String? ?? 'Unknown Product',
      // If 'size' is provided directly, use it. Otherwise, use size_id to determine size
      size: json['size'] != null && (json['size'] as String).isNotEmpty
          ? json['size'] as String
          : _getSizeFromId(json),
      stock: json['stock_quantity'] != null
          ? int.parse(json['stock_quantity'].toString())
          : (json['stock'] != null ? int.parse(json['stock'].toString()) : 0),
      isNew: json['is_new'] == true ||
          json['is_new'] == 1 ||
          json['isNew'] == true,
      price: _extractPrice(json),
      imagePath: json['image_path'] as String?,
      description: json['description'] as String?,
      code: json['code'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      categoryId: json['category_id'] != null
          ? int.parse(json['category_id'].toString())
          : null,
      sizeId: json['size_id'] != null
          ? int.parse(json['size_id'].toString())
          : null,
      // Kosong kalau backend belum mengirim variants — layar tetap jatuh ke
      // total stok lama, jadi versi API yang lebih tua tidak merusak apa pun.
      variants: json['variants'] is List
          ? (json['variants'] as List)
              .whereType<Map<String, dynamic>>()
              .map(ProductVariant.fromJson)
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'size': size,
        'stock_quantity': stock,
        'is_new': isNew ? 1 : 0,
        'price': price,
        if (imagePath != null) 'image_path': imagePath,
        if (description != null) 'description': description,
        if (code != null) 'code': code,
        if (categoryId != null) 'category_id': categoryId,
        if (sizeId != null) 'size_id': sizeId,
      };

  // Helper method to extract price from different JSON formats
  static double _extractPrice(Map<String, dynamic> json) {
    if (json['price'] == null) return 0.0;

    if (json['price'] is double) {
      return json['price'];
    } else if (json['price'] is int) {
      return json['price'].toDouble();
    } else {
      // Try to parse string to double
      try {
        return double.parse(json['price'].toString());
      } catch (e) {
        print('Error parsing price: $e');
        return 0.0;
      }
    }
  }

  // FIXED: Corrected the size_id mapping to accurately reflect database values
  static String _getSizeFromId(Map<String, dynamic> json) {
    if (json['size_id'] == null) return 'One Size';

    // Get the size_id as an integer
    final int sizeId = int.parse(json['size_id'].toString());

    // FIXED: Corrected size mapping based on the error you described
    // If setting size to 'S' shows as 'M', it means our mappings are off
    switch (sizeId) {
      case 0:
        return 'S'; // If your DB uses 0-based indexing
      case 1:
        return 'S'; // This was mapped to 'S' before
      case 2:
        return 'M';
      case 3:
        return 'L';
      case 4:
        return 'XL';
      case 5:
        return 'XXL';
      case 6:
        return 'XXXL';
      case 7:
        return '3L';
      default:
        // For any other ID, try to use a smarter fallback based on the ID value
        if (sizeId <= 0) return 'S';
        if (sizeId >= 8) return '3L';
        // Otherwise, convert to a string and return
        return 'Size $sizeId';
    }
  }
}
