import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/history_controller.dart';
import '../models/order.dart';
import '../service/printer_service.dart';
import 'printer_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final PrinterService _printerService = PrinterService();
  @override
  void initState() {
    super.initState();
    // Load order history when page is opened
    Future.microtask(() {
      if (mounted) {
        Provider.of<HistoryController>(context, listen: false).loadOrders();
        _printerService.init();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyController = Provider.of<HistoryController>(context);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Column(
          children: [
            // Search and Sort
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        historyController.searchQuery = value;
                        historyController.applySearchAndSort();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari ID pesanan atau nama karyawan',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: historyController.sortOrder,
                  items: const [
                    DropdownMenuItem(value: 'desc', child: Text('Terbaru')),
                    DropdownMenuItem(value: 'asc', child: Text('Terlama')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        historyController.sortOrder = value;
                        historyController.applySearchAndSort();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: historyController.filteredOrderHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long,
                              size: 64, color: KtColor.neutral400),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada riwayat pesanan',
                            style: TextStyle(color: KtColor.neutral500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: historyController.filteredOrderHistory.length,
                      itemBuilder: (context, index) {
                        final order =
                            historyController.filteredOrderHistory[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showOrderDetails(context, order),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: KtColor.violet100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.receipt_long,
                                        color: KtColor.primary, size: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text('#${order.id}',
                                                style: TextStyle(
                                                    color: KtColor.primary,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                order.karyawan ?? '-',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: KtColor.neutral600),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          order.karyawan != null &&
                                                  order.karyawan!.isNotEmpty
                                              ? order.karyawan!
                                              : '-',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                                currencyFormat
                                                    .format(order.total),
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: KtColor.successText)),
                                            const SizedBox(width: 12),
                                            Icon(Icons.inventory_2_outlined,
                                                size: 16, color: KtColor.neutral400),
                                            const SizedBox(width: 2),
                                            Text('${order.itemCount} produk',
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: KtColor.neutral600)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            ...order.items.map((item) => Chip(
                                                  label: Text(
                                                      '${item.displayName} (${item.quantity}x)'),
                                                  backgroundColor:
                                                      KtColor.neutral100,
                                                  labelStyle: const TextStyle(
                                                      fontSize: 12),
                                                )),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today,
                                              size: 14, color: KtColor.neutral400),
                                          const SizedBox(width: 4),
                                          Text(dateFormat.format(order.date),
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: KtColor.neutral500)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: order.status ==
                                                  OrderStatus.completed
                                              ? KtColor.success.withValues(alpha: 0.12)
                                              : KtColor.danger.withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          order.status == OrderStatus.completed
                                              ? 'Selesai'
                                              : 'Dibatalkan',
                                          style: TextStyle(
                                            color: order.status ==
                                                    OrderStatus.completed
                                                ? KtColor.successText
                                                : KtColor.dangerText,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Order order) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Fungsi untuk mencetak struk
    Future<void> _printReceipt() async {
      if (!_printerService.isConnected) {
        // Jika printer belum terhubung, tampilkan dialog untuk menghubungkan printer
        final bool? shouldConnect = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Printer Tidak Terhubung'),
            content: const Text(
                'Printer belum terhubung. Apakah Anda ingin menghubungkan printer sekarang?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hubungkan'),
              ),
            ],
          ),
        );

        if (shouldConnect == true) {
          // Buka halaman pengaturan printer dengan callback
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PrinterPage(
                onConnectionChanged: (isConnected, selectedDevice) {
                  // Update status koneksi printer saat halaman ditutup
                  // Gunakan Future.microtask untuk memastikan setState dipanggil setelah navigasi selesai
                  Future.microtask(() {
                    if (mounted) {
                      setState(() {
                        // Status koneksi sudah diperbarui di PrinterService karena menggunakan singleton
                      });
                    }
                  });
                },
              ),
            ),
          );

          // Periksa status koneksi setelah kembali dari halaman printer
          if (!_printerService.isConnected) {
            return; // Jika tidak berhasil terhubung, batalkan pencetakan
          }
        } else {
          return; // Jika pengguna membatalkan, batalkan pencetakan
        }
      }

      // Tampilkan indikator loading saat mencetak
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Mencetak struk...'),
            ],
          ),
        ),
      );

      try {
        // Cetak struk
        final success = await _printerService.printReceipt(order);

        // Tutup dialog loading
        Navigator.pop(context);

        // Tampilkan pesan hasil pencetakan
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                success ? 'Struk berhasil dicetak' : 'Gagal mencetak struk'),
            backgroundColor: success ? KtColor.successText : KtColor.danger,
          ),
        );
      } catch (e) {
        // Tutup dialog loading jika terjadi error
        Navigator.pop(context);

        // Tampilkan pesan error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: KtColor.danger,
          ),
        );
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          width: 480,
          decoration: BoxDecoration(
            color: KtColor.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: KtColor.violet100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.receipt_long,
                              color: KtColor.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '#${order.id}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: KtColor.neutral400),
                        const SizedBox(width: 4),
                        Text(
                            DateFormat('dd MMM yyyy, HH:mm').format(order.date),
                            style: TextStyle(
                                fontSize: 13, color: KtColor.neutral600)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: order.status == OrderStatus.completed
                            ? KtColor.success.withValues(alpha: 0.12)
                            : KtColor.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        order.status == OrderStatus.completed
                            ? 'Selesai'
                            : 'Dibatalkan',
                        style: TextStyle(
                          color: order.status == OrderStatus.completed
                              ? KtColor.successText
                              : KtColor.dangerText,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.person, size: 18, color: KtColor.neutral500),
                    const SizedBox(width: 6),
                    Text(order.karyawan ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Item Pesanan',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    separatorBuilder: (context, idx) =>
                        const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final item = order.items[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: KtColor.neutral200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.shopping_bag_outlined,
                                color: KtColor.neutral400),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.displayName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                                Text(
                                  '${item.quantity} x ${currencyFormat.format(item.product.price)}',
                                  style: TextStyle(
                                      color: KtColor.neutral500, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(currencyFormat.format(item.totalPrice),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      );
                    },
                  ),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal'),
                    Text(currencyFormat.format(order.subtotal)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(currencyFormat.format(order.total),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: order.status == OrderStatus.completed
                          ? _printReceipt
                          : null,
                      icon: const Icon(Icons.print),
                      label: const Text('Cetak Struk'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KtColor.primary,
                        foregroundColor: KtColor.surface,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PrinterPage(
                              onConnectionChanged:
                                  (isConnected, selectedDevice) {
                                // Update status koneksi printer saat halaman ditutup
                                // Gunakan Future.microtask untuk memastikan setState dipanggil setelah navigasi selesai
                                Future.microtask(() {
                                  if (mounted) {
                                    setState(() {
                                      // Status koneksi sudah diperbarui di PrinterService karena menggunakan singleton
                                    });
                                  }
                                });
                              },
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Pengaturan Printer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
