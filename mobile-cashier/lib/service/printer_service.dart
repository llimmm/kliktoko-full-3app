import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import '../models/order.dart';
import 'package:intl/intl.dart';

// Singleton pattern untuk memastikan hanya ada satu instance PrinterService
class PrinterService {
  // Singleton instance
  static final PrinterService _instance = PrinterService._internal();

  // Factory constructor untuk mengembalikan instance yang sama
  factory PrinterService() {
    return _instance;
  }

  // Private constructor
  PrinterService._internal();
  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;

  // Getter untuk mendapatkan daftar perangkat Bluetooth
  List<BluetoothDevice> get devices => _devices;

  // Getter untuk mendapatkan perangkat yang dipilih
  BluetoothDevice? get selectedDevice => _selectedDevice;

  // Getter untuk status koneksi
  bool get isConnected => _connected;

  // Inisialisasi service printer
  Future<void> init() async {
    try {
      // Periksa apakah Bluetooth diaktifkan
      bool? isEnabled = await _printer.isOn;
      if (isEnabled != true) {
        return;
      }

      // Dapatkan daftar perangkat yang dipasangkan
      _devices = await _printer.getBondedDevices();
    } catch (e) {
      debugPrint('Error initializing printer: $e');
    }
  }

  // Pilih perangkat printer
  void selectDevice(BluetoothDevice device) {
    _selectedDevice = device;
  }

  // Hubungkan ke printer
  Future<bool> connect() async {
    if (_selectedDevice == null) {
      return false;
    }

    try {
      _connected = await _printer.connect(_selectedDevice!);
      return _connected;
    } catch (e) {
      debugPrint('Error connecting to printer: $e');
      _connected = false;
      return false;
    }
  }

  // Putuskan koneksi printer
  Future<bool> disconnect() async {
    try {
      await _printer.disconnect();
      _connected = false;
      return true;
    } catch (e) {
      debugPrint('Error disconnecting printer: $e');
      return false;
    }
  }

  // Cetak struk pesanan
  Future<bool> printReceipt(Order order) async {
    if (!_connected) {
      return false;
    }

    try {
      // Format tanggal dan mata uang
      final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
      final currencyFormat = NumberFormat.currency(
        locale: 'id',
        symbol: 'Rp ',
        decimalDigits: 0,
      );

      // Cetak header struk
      await _printer.printNewLine();
      await _printer.printCustom('UD Syukur', 3, 1);
      await _printer.printNewLine();
      await _printer.printCustom('Struk Pembelian', 2, 1);
      await _printer.printCustom('--------------------------------', 1, 1);

      // Cetak informasi pesanan
      await _printer.printCustom('No. Pesanan: #${order.id}', 1, 0);
      await _printer.printCustom(
          'Tanggal: ${dateFormat.format(order.date)}', 1, 0);
      debugPrint('Printing receipt with karyawan: ${order.karyawan}');
      await _printer.printCustom('Kasir: ${order.karyawan ?? "-"}', 1, 0);
      await _printer.printCustom('--------------------------------', 1, 1);

      // Cetak item pesanan
      await _printer.printCustom('Nama Barang', 2, 1);
      for (var item in order.items) {
        await _printer.printCustom(item.displayName, 1, 0);
        await _printer.printLeftRight(
            '${item.quantity}x ${currencyFormat.format(item.product.price)}',
            currencyFormat.format(item.totalPrice),
            1);
        await _printer.printNewLine();
      }

      // Cetak ringkasan pembayaran
      await _printer.printCustom('--------------------------------', 1, 1);
      await _printer.printLeftRight(
          'Subtotal', currencyFormat.format(order.subtotal), 1);
      await _printer.printLeftRight('Metode', 'QRIS', 1);
      await _printer.printCustom('--------------------------------', 1, 1);
      await _printer.printLeftRight(
          'TOTAL', currencyFormat.format(order.total), 2);

      // Cetak footer
      await _printer.printNewLine();
      await _printer.printCustom('Terima Kasih', 2, 1);
      await _printer.printCustom('Atas Kunjungan Anda', 1, 1);
      await _printer.printNewLine();
      await _printer.printNewLine();
      await _printer.paperCut();

      return true;
    } catch (e) {
      debugPrint('Error printing receipt: $e');
      return false;
    }
  }

  // Print barcode label
  Future<bool> printBarcodeLabel(String content) async {
    if (!_connected) {
      debugPrint('Printer not connected');
      return false;
    }

    try {
      // Print barcode label content
      await _printer.printCustom(content, 1, 1);
      await _printer.printNewLine();
      await _printer.printNewLine();
      await _printer.paperCut();

      return true;
    } catch (e) {
      debugPrint('Error printing barcode label: $e');
      return false;
    }
  }
}
