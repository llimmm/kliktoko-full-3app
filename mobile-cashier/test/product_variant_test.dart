import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_simoto/controllers/order_controller.dart';
import 'package:kasir_simoto/models/product.dart';
import 'package:kasir_simoto/service/api_service.dart';
import 'package:kasir_simoto/config/api_config.dart';

/// Payload di bawah disalin dari respons GET /api/products yang sebenarnya.
/// Kalau backend mengubah bentuknya, uji ini yang gagal lebih dulu — bukan
/// kasir yang diam-diam mengirim transaksi tanpa ukuran lalu ditolak 500.
Map<String, dynamic> _seragamPramuka() => {
      'id': 1,
      'code': 'PRD-60858',
      'name': 'Seragam Pramuka',
      'price': '75000.00',
      'stock_quantity': 55,
      'size_id': 1,
      'category_id': 1,
      'variants': [
        {
          'id': 1,
          'product_id': 1,
          'size_id': 1,
          'stock_quantity': 12,
          'size': {'id': 1, 'name': 'S', 'code': 'S'},
        },
        {
          'id': 2,
          'product_id': 1,
          'size_id': 2,
          'stock_quantity': 0,
          'size': {'id': 2, 'name': 'M', 'code': 'M'},
        },
        {
          'id': 3,
          'product_id': 1,
          'size_id': 3,
          'stock_quantity': 3,
          'size': {'id': 3, 'name': 'L', 'code': 'L'},
        },
      ],
    };

void main() {
  // ApiService memuat token dari SharedPreferences di konstruktornya; tanpa
  // binding, tiap pembuatan controller membanjiri output dengan peringatan.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Product.fromJson — stok per ukuran', () {
    test('membaca varian beserta kode ukuran dan stoknya', () {
      final p = Product.fromJson(_seragamPramuka());

      expect(p.variants.length, 3);
      expect(p.variants.map((v) => v.size).toList(), ['S', 'M', 'L']);
      expect(p.variants.map((v) => v.stock).toList(), [12, 0, 3]);
      // id varian inilah yang dikirim sebagai product_variant_id.
      expect(p.variants.map((v) => v.id).toList(), [1, 2, 3]);
    });

    test('menandai habis dan menipis secara terpisah', () {
      final p = Product.fromJson(_seragamPramuka());

      // Inti masalahnya: total 55 unit terlihat aman, padahal ukuran M nol.
      expect(p.stock, 55);
      expect(p.variants[1].isOutOfStock, isTrue);
      expect(p.variants[2].isLow, isTrue);
      expect(p.variants[0].isLow, isFalse);
    });

    test('produk tanpa variants tetap terbaca (API versi lama)', () {
      final p = Product.fromJson({
        'id': 9,
        'name': 'Produk Lama',
        'size': 'XL',
        'stock_quantity': 7,
        'price': 1000,
      });

      expect(p.variants, isEmpty);
      expect(p.stock, 7);
    });
  });

  group('OrderController — satu baris keranjang per ukuran', () {
    OrderController buatController() =>
        OrderController(ApiService(baseUrl: ApiConfig.baseUrl), null);

    test('dua ukuran dari produk yang sama jadi dua baris terpisah', () {
      final p = Product.fromJson(_seragamPramuka());
      final c = buatController();

      c.addProduct(p, variant: p.variants[0]); // S
      c.addProduct(p, variant: p.variants[2]); // L

      // Dulu keranjang dicocokkan lewat product.name, sehingga keduanya
      // menyatu jadi satu baris dan ukuran yang dijual jadi salah.
      expect(c.items.length, 2);
      expect(c.items.map((i) => i.variant?.size).toList(), ['S', 'L']);
      expect(c.items.every((i) => i.quantity == 1), isTrue);
    });

    test('ukuran yang sama ditambah dua kali menaikkan jumlah, bukan baris',
        () {
      final p = Product.fromJson(_seragamPramuka());
      final c = buatController();

      c.addProduct(p, variant: p.variants[0]);
      c.addProduct(p, variant: p.variants[0]);

      expect(c.items.length, 1);
      expect(c.items.first.quantity, 2);
    });

    test('mengurangi hanya menyentuh baris ukuran yang dimaksud', () {
      final p = Product.fromJson(_seragamPramuka());
      final c = buatController();

      c.addProduct(p, variant: p.variants[0]); // S
      c.addProduct(p, variant: p.variants[2]); // L
      c.removeProduct(p, variant: p.variants[2]); // buang L

      expect(c.items.length, 1);
      expect(c.items.first.variant?.size, 'S');
    });

    test('produk berukuran tunggal tidak perlu ditanyakan ukurannya', () {
      final p = Product.fromJson({
        'id': 5,
        'name': 'Topi Seragam',
        'price': 25000,
        'stock_quantity': 10,
        'variants': [
          {
            'id': 77,
            'product_id': 5,
            'stock_quantity': 10,
            'size': {'code': 'All'},
          },
        ],
      });
      final c = buatController();

      c.addProduct(p); // tanpa variant

      // Ukurannya dipilih sendiri, supaya checkout tetap membawa
      // product_variant_id dan tidak ditolak backend.
      expect(c.items.first.variant?.id, 77);
      expect(c.items.first.displayName, 'Topi Seragam (All)');
    });
  });
}
