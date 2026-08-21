import 'package:flutter/material.dart';
import '../controllers/order_controller.dart';
import '../models/product.dart';
import '../theme/tokens.dart';

/// Menambah produk ke keranjang, menanyakan ukuran hanya bila memang ambigu.
///
/// Produk berukuran tunggal langsung masuk keranjang — kasir tidak perlu
/// dihentikan untuk memilih satu-satunya pilihan yang ada.
Future<void> addProductWithSize(
  BuildContext context,
  OrderController orderController,
  Product product,
) async {
  if (product.variants.length <= 1) {
    orderController.addProduct(product);
    return;
  }

  final variant = await showModalBottomSheet<ProductVariant>(
    context: context,
    backgroundColor: KtColor.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(KtRadius.md)),
    ),
    builder: (_) => _SizePickerSheet(product: product),
  );

  if (variant != null) {
    orderController.addProduct(product, variant: variant);
  }
}

class _SizePickerSheet extends StatelessWidget {
  final Product product;

  const _SizePickerSheet({required this.product});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: KtColor.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: KtColor.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pilih ukuran',
              style: TextStyle(fontSize: 14, color: KtColor.textSecondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: product.variants
                  .map((v) => _SizeChip(
                        variant: v,
                        onTap: () => Navigator.pop(context, v),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ukuran habis tetap ditampilkan, hanya dinonaktifkan — kasir perlu tahu
/// ukuran itu ada tapi kosong, supaya bisa menjawab pembeli. Menyembunyikannya
/// membuat ukuran yang hilang terlihat seperti ukuran yang tidak pernah ada.
class _SizeChip extends StatelessWidget {
  final ProductVariant variant;
  final VoidCallback onTap;

  const _SizeChip({required this.variant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final habis = variant.isOutOfStock;

    // Warna stok menyampaikan data, bukan merek — sengaja bukan ungu.
    final Color stokWarna = habis
        ? KtColor.danger
        : variant.isLow
            ? KtColor.warning
            : KtColor.textSecondary;

    return InkWell(
      onTap: habis ? null : onTap,
      borderRadius: BorderRadius.circular(KtRadius.sm),
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 72,
          minHeight: KtBold.minTapTarget,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: habis ? KtColor.neutral100 : KtColor.surface,
          border: Border.all(
            color: habis ? KtColor.border : KtColor.primary,
            width: habis ? 1 : 2,
          ),
          borderRadius: BorderRadius.circular(KtRadius.sm),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              variant.size,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: habis ? KtColor.neutral400 : KtColor.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              habis ? 'habis' : 'sisa ${variant.stock}',
              style: TextStyle(fontSize: 11, color: stokWarna),
            ),
          ],
        ),
      ),
    );
  }
}
