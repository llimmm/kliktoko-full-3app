import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/order_item.dart';
import '../service/api_service.dart';

class HistoryController with ChangeNotifier {
  List<Order> _orderHistory = [];
  final ApiService _apiService;

  // Tambahan untuk pencarian dan sortir
  String searchQuery = '';
  String sortOrder = 'desc'; // 'desc' untuk terbaru, 'asc' untuk terlama
  List<Order> _filteredOrderHistory = [];

  HistoryController(this._apiService) {
    applySearchAndSort();
  }

  List<Order> get orderHistory => _orderHistory;
  List<Order> get filteredOrderHistory => _filteredOrderHistory;

  void applySearchAndSort() {
    List<Order> filtered = _orderHistory;
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((order) {
        final idMatch =
            order.id.toLowerCase().contains(searchQuery.toLowerCase());
        final karyawanMatch = (order.karyawan ?? '')
            .toLowerCase()
            .contains(searchQuery.toLowerCase());
        return idMatch || karyawanMatch;
      }).toList();
    }
    filtered.sort((a, b) => sortOrder == 'desc'
        ? b.date.compareTo(a.date)
        : a.date.compareTo(b.date));
    _filteredOrderHistory = filtered;
    notifyListeners();
  }

  // Load orders from API
  Future<void> loadOrders() async {
    try {
      final salesData = await _apiService.getSalesHistory();
      _orderHistory.clear();
      for (final saleData in salesData) {
        try {
          final items = <OrderItem>[];
          if (saleData['items'] != null) {
            for (final itemData in saleData['items']) {
              final product = Product(
                id: itemData['kode_produk'] ?? '',
                name: itemData['nama_produk'] ?? '',
                price: double.parse(itemData['harga_satuan'] ?? '0'),
                category: 'Uncategorized',
                size: '-',
                stock: 0,
                isNew: false,
                code: itemData['kode_produk'] ?? '',
              );
              // 'ukuran' baru ada di API; penjualan lama mengirim null dan
              // barisnya tampil tanpa keterangan ukuran, bukan error.
              final kodeUkuran = itemData['ukuran']?.toString();
              items.add(OrderItem(
                product: product,
                variant: kodeUkuran == null || kodeUkuran.isEmpty
                    ? null
                    : ProductVariant(id: 0, size: kodeUkuran, stock: 0),
                quantity: itemData['jumlah'] ?? 0,
              ));
            }
          }
          final order = Order(
            id: saleData['id'].toString(),
            date: DateTime.parse(saleData['tanggal']),
            items: items,
            subtotal: double.parse(saleData['total_harga'] ?? '0'),
            discount: 0,
            total: double.parse(saleData['total_harga'] ?? '0'),
            status: saleData['status']?.toString().toLowerCase() == 'selesai'
                ? OrderStatus.completed
                : OrderStatus.cancelled,
            karyawan: saleData['karyawan'],
          );
          _orderHistory.add(order);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing order: \$e');
          }
        }
      }
      applySearchAndSort();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading orders: \$e');
      }
      rethrow;
    }
  }

  // Add a new order to the history
  Future<void> addOrder(Order order) async {
    _orderHistory.insert(0, order);
    notifyListeners();
  }

  // Clear order history
  Future<void> clearHistory() async {
    _orderHistory.clear();
    notifyListeners();
  }
}
