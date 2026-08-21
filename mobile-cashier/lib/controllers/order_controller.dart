import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../models/order_item.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../controllers/history_controller.dart';
import '../service/api_service.dart';
import '../service/printer_service.dart';

enum OrderStatus {
  active,
  hold,
  completed,
  cancelled,
}

class OrderController with ChangeNotifier {
  List<OrderItem> _items = [];
  OrderStatus _status = OrderStatus.active;
  double _discountPercentage = 0;
  final HistoryController? _historyController;
  final ApiService _apiService;
  int? _selectedUserId;
  String? _selectedUserName;
  String _selectedPaymentMethod = 'cash';
  String? _notes;
  bool _isEmployeeCodeVerified = false;

  OrderController(this._apiService, [this._historyController]);

  List<OrderItem> get items => _items;
  OrderStatus get status => _status;
  double get discountPercentage => _discountPercentage;

  // Calculate totals
  double get subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);
  double get discountAmount => subtotal * (_discountPercentage / 100);
  double get total => subtotal - discountAmount;
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Menambah satu unit ke keranjang.
  ///
  /// [variant] boleh null untuk produk berukuran tunggal — ukurannya dipilih
  /// sendiri di sini supaya kasir tidak ditanyai hal yang tidak ambigu.
  /// Untuk produk multi-ukuran, pemanggil wajib menentukan ukurannya lebih
  /// dulu (lihat `addProductWithSize` di widget/size_picker_sheet.dart);
  /// backend menolak POST /api/sales tanpa product_variant_id.
  void addProduct(Product product, {ProductVariant? variant}) {
    final chosen = variant ??
        (product.variants.length == 1 ? product.variants.first : null);
    final key = '${product.id}:${chosen?.id ?? '-'}';

    final existingIndex = _items.indexWhere((item) => item.lineKey == key);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(OrderItem(product: product, variant: chosen));
    }

    notifyListeners();
  }

  void removeProduct(Product product, {ProductVariant? variant}) {
    final chosen = variant ??
        (product.variants.length == 1 ? product.variants.first : null);
    final key = '${product.id}:${chosen?.id ?? '-'}';

    final index = _items.indexWhere((item) => item.lineKey == key);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  // Update quantity of an item
  void updateQuantity(int index, int quantity) {
    if (index >= 0 && index < _items.length) {
      if (quantity > 0) {
        _items[index].quantity = quantity;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  // Increment item quantity
  void incrementQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  // Decrement item quantity
  void decrementQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  // Remove item from order
  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  // Clear all items
  void clearOrder() {
    _items = [];
    _discountPercentage = 0;
    _status = OrderStatus.active;
    _isEmployeeCodeVerified = false;
    notifyListeners();
  }

  // Hold the order
  void holdOrder() {
    _status = OrderStatus.hold;
    notifyListeners();
  }

  // Process payment for the order
  Future<bool> processPayment(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    final contextIsValid = true;

    try {
      if (_items.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Tidak ada item dalam pesanan'),
            backgroundColor: KtColor.danger,
          ),
        );
        return false;
      }

      // Validate employee code verification
      if (_selectedUserId == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Pilih karyawan terlebih dahulu'),
            backgroundColor: KtColor.danger,
          ),
        );
        return false;
      }

      if (!_isEmployeeCodeVerified) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Verifikasi kode karyawan terlebih dahulu'),
            backgroundColor: KtColor.danger,
          ),
        );
        return false;
      }
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Memproses pembayaran..."),
                ],
              ),
            ),
          );
        },
      );
      // Siapkan items
      final items = _items
          .map((item) => {
                'product_id': int.tryParse(item.product.id.toString()) ?? 0,
                // Wajib untuk produk multi-ukuran; backend menolak tanpa ini
                // daripada menebak ukuran mana yang stoknya dikurangi.
                if (item.variant != null)
                  'product_variant_id': item.variant!.id,
                'quantity': item.quantity,
              })
          .toList();
      // POST ke /api/sales
      await _apiService.postSales(
        userId: _selectedUserId!,
        paymentMethod: _selectedPaymentMethod,
        items: items,
      );
      // Tambahkan ke history
      Order? completedOrder;
      if (_historyController != null) {
        // Buat order dengan informasi karyawan
        debugPrint(
            'Creating order with karyawan: $_selectedUserName ?? $_selectedUserId.toString()');
        completedOrder = Order(
          id: 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
          date: DateTime.now(),
          items: List<OrderItem>.from(_items),
          subtotal: subtotal,
          discount: discountAmount,
          total: total,
          status: mapFromControllerStatus(OrderStatus.completed),
          karyawan: _selectedUserName ?? _selectedUserId.toString(),
        );
        debugPrint('Created order with karyawan: ${completedOrder.karyawan}');
        await _historyController.addOrder(completedOrder);
      }
      navigator.pop();
      if (contextIsValid) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Pembayaran berhasil!'),
            backgroundColor: KtColor.successText,
          ),
        );
      }

      // Cetak struk otomatis jika order berhasil dibuat
      if (completedOrder != null) {
        // Import PrinterService
        final printerService = PrinterService();
        if (printerService.isConnected) {
          try {
            await printerService.printReceipt(completedOrder);
          } catch (e) {
            debugPrint('Error saat mencetak struk: $e');
            if (contextIsValid) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(
                      'Pembayaran berhasil, tetapi gagal mencetak struk: $e'),
                  backgroundColor: KtColor.warningText,
                ),
              );
            }
          }
        }
      }

      return true;
    } catch (e) {
      navigator.pop();
      if (contextIsValid) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Pembayaran gagal: $e'),
            backgroundColor: KtColor.danger,
          ),
        );
      }
      return false;
    }
  }

  // Set discount percentage
  void setDiscount(double percentage) {
    _discountPercentage = percentage;
    notifyListeners();
  }

  void setSelectedUserId(int? id) {
    _selectedUserId = id;
    // Reset code verification when user changes
    _isEmployeeCodeVerified = false;
    notifyListeners();
  }

  void setSelectedUserName(String? name) {
    _selectedUserName = name;
    debugPrint('OrderController: setSelectedUserName: $_selectedUserName');
    notifyListeners();
  }

  void setEmployeeCodeVerified(bool verified) {
    _isEmployeeCodeVerified = verified;
    notifyListeners();
  }

  void setSelectedPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  void setNotes(String? notes) {
    _notes = notes;
    notifyListeners();
  }

  int? get selectedUserId => _selectedUserId;
  String? get selectedUserName => _selectedUserName;
  String get selectedPaymentMethod => _selectedPaymentMethod;
  String? get notes => _notes;
  bool get isEmployeeCodeVerified => _isEmployeeCodeVerified;
}
