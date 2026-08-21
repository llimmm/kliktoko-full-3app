import 'package:flutter_test/flutter_test.dart';
import 'package:kliktoko/gudang_page/GudangModel/ProductModel.dart';

/// Payload ini disalin dari respons GET /api/products yang sebenarnya.
/// Kalau backend mengubah bentuknya, uji ini yang gagal lebih dulu —
/// bukan layar gudang yang diam-diam menampilkan stok kosong.
void main() {
  group('Product.fromJson — stok per ukuran', () {
    test('membaca varian beserta kode ukuran dan stoknya', () {
      final p = Product.fromJson({
        'id': 1,
        'name': 'Seragam Pramuka',
        'code': 'PRD-60858',
        'price': '75000.00',
        'stock_quantity': 55,
        'size_id': 1,
        'variants': [
          {'id': 10, 'stock_quantity': 12, 'size': {'id': 1, 'code': 'S'}},
          {'id': 11, 'stock_quantity': 0, 'size': {'id': 2, 'code': 'M'}},
          {'id': 12, 'stock_quantity': 5, 'size': {'id': 3, 'code': 'L'}},
        ],
      });

      expect(p.variants.length, 3);
      expect(p.variants.map((v) => v.size).toList(), ['S', 'M', 'L']);
      expect(p.variants.map((v) => v.stock).toList(), [12, 0, 5]);
    });

    test('menandai habis dan menipis secara terpisah', () {
      final p = Product.fromJson({
        'name': 'Jaket',
        'stock_quantity': 39,
        'variants': [
          {'id': 1, 'stock_quantity': 0, 'size': {'code': 'M'}},
          {'id': 2, 'stock_quantity': 3, 'size': {'code': 'L'}},
          {'id': 3, 'stock_quantity': 36, 'size': {'code': 'XL'}},
        ],
      });

      // Inti masalahnya: total 39 unit terlihat aman, padahal ukuran M nol.
      expect(p.stock, 39);
      expect(p.variants[0].isOutOfStock, isTrue);
      expect(p.variants[1].isLow, isTrue);
      expect(p.variants[2].isOutOfStock, isFalse);
      expect(p.variants[2].isLow, isFalse);
    });

    test('produk dengan satu ukuran habis masuk peringatan stok', () {
      // Kasus nyata dari seeder: Jaket Abu Sekolah total 39 unit terlihat
      // aman, padahal ukuran M nol. Memakai stock_quantity menyembunyikannya.
      final p = Product.fromJson({
        'name': 'Jaket Abu Sekolah',
        'stock_quantity': 39,
        'variants': [
          {'id': 1, 'stock_quantity': 0, 'size': {'code': 'M'}},
          {'id': 2, 'stock_quantity': 22, 'size': {'code': 'L'}},
          {'id': 3, 'stock_quantity': 17, 'size': {'code': 'XL'}},
        ],
      });

      expect(p.stock, 39);
      expect(p.hasOutOfStockSize, isTrue);
      expect(p.outOfStockSizes, ['M']);
    });

    test('produk yang semua ukurannya ada stok tidak masuk peringatan', () {
      final p = Product.fromJson({
        'name': 'Kaos Olahraga Anak',
        'stock_quantity': 73,
        'variants': [
          {'id': 4, 'stock_quantity': 40, 'size': {'code': 'S'}},
          {'id': 5, 'stock_quantity': 33, 'size': {'code': 'M'}},
        ],
      });

      expect(p.hasOutOfStockSize, isFalse);
      expect(p.outOfStockSizes, isEmpty);
    });

    test('tanpa variants, peringatan jatuh ke total stok (API lama)', () {
      final habis = Product.fromJson({'name': 'X', 'stock_quantity': 0});
      final ada = Product.fromJson({'name': 'Y', 'stock_quantity': 5});

      expect(habis.hasOutOfStockSize, isTrue);
      expect(ada.hasOutOfStockSize, isFalse);
    });

    test('produk tanpa variants tetap terbaca (API versi lama)', () {
      final p = Product.fromJson({
        'name': 'Produk Lama',
        'size': 'XL',
        'stock_quantity': 7,
      });

      expect(p.variants, isEmpty);
      expect(p.stock, 7);
      expect(p.size, 'XL');
    });
  });
}
