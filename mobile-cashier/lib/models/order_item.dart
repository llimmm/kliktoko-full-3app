import 'product.dart';

class OrderItem {
  final Product product;

  /// Ukuran yang dipilih kasir. Null hanya untuk produk berukuran tunggal
  /// atau data lama; POST /api/sales menolak produk multi-ukuran tanpa ini.
  final ProductVariant? variant;

  int quantity;

  OrderItem({
    required this.product,
    this.variant,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;

  /// Identitas satu baris keranjang.
  ///
  /// Dulu keranjang dicocokkan lewat `product.name`, sehingga Seragam Pramuka
  /// ukuran M dan L menyatu jadi satu baris — jumlahnya benar, ukurannya
  /// hilang, dan stok yang dikurangi jadi salah ukuran. Satu baris kini
  /// ditentukan oleh pasangan produk + ukuran.
  String get lineKey => '${product.id}:${variant?.id ?? '-'}';

  /// "Seragam Pramuka (M)" — dipakai di keranjang dan struk.
  String get displayName =>
      variant == null ? product.name : '${product.name} (${variant!.size})';

  OrderItem copyWith({
    Product? product,
    ProductVariant? variant,
    int? quantity,
  }) {
    return OrderItem(
      product: product ?? this.product,
      variant: variant ?? this.variant,
      quantity: quantity ?? this.quantity,
    );
  }
}
