import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../service/printer_service.dart';

class PrinterPage extends StatefulWidget {
  final Function(bool isConnected, BluetoothDevice? selectedDevice)?
      onConnectionChanged;

  const PrinterPage({super.key, this.onConnectionChanged});

  @override
  State<PrinterPage> createState() => _PrinterPageState();
}

class _PrinterPageState extends State<PrinterPage> {
  final PrinterService _printerService = PrinterService();
  bool _isLoading = true;
  String _statusMessage = '';
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _initPrinter();
  }

  @override
  void dispose() {
    // Panggil callback untuk memberitahu halaman sebelumnya tentang status koneksi printer
    if (widget.onConnectionChanged != null) {
      widget.onConnectionChanged!(
          _printerService.isConnected, _printerService.selectedDevice);
    }
    super.dispose();
  }

  /// blue_thermal_printer hanya ada di Android/iOS/macOS. Di Windows plugin-nya
  /// tidak terdaftar, sehingga daftar perangkat selalu kosong dan pesan
  /// bawaannya menyuruh kasir memeriksa Bluetooth — menyesatkan, karena
  /// masalahnya platform, bukan Bluetooth-nya.
  bool get _didukungPlatformIni => Platform.isAndroid || Platform.isIOS;

  Future<void> _initPrinter() async {
    if (!_didukungPlatformIni) {
      setState(() {
        _isLoading = false;
        _statusMessage =
            'Printer struk hanya tersedia di perangkat Android. '
            'Halaman ini tidak berfungsi saat app dijalankan di desktop.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Memuat daftar printer...';
    });

    try {
      await _printerService.init();
      setState(() {
        _isLoading = false;
        if (_printerService.devices.isEmpty) {
          _statusMessage =
              'Tidak ada printer yang tersedia. Pastikan Bluetooth aktif dan printer sudah dipasangkan.';
        } else {
          _statusMessage = '';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Gagal memuat daftar printer: $e';
      });
    }
  }

  Future<void> _connectPrinter(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
      _statusMessage = 'Menghubungkan ke ${device.name}...';
    });

    try {
      _printerService.selectDevice(device);
      bool connected = await _printerService.connect();

      setState(() {
        _isConnecting = false;
        if (connected) {
          _statusMessage = 'Terhubung ke ${device.name}';
        } else {
          _statusMessage = 'Gagal terhubung ke ${device.name}';
        }
      });

      if (connected) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Berhasil terhubung ke ${device.name}')));
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _disconnectPrinter() async {
    setState(() {
      _isConnecting = true;
      _statusMessage = 'Memutuskan koneksi printer...';
    });

    try {
      bool disconnected = await _printerService.disconnect();

      setState(() {
        _isConnecting = false;
        if (disconnected) {
          _statusMessage = 'Printer terputus';
        } else {
          _statusMessage = 'Gagal memutuskan koneksi printer';
        }
      });

      if (disconnected) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Printer terputus')));
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _refreshDevices() async {
    await _initPrinter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Printer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshDevices,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: KtColor.violet700),
                        const SizedBox(width: 8),
                        const Text(
                          'Informasi Printer',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Status: ${_printerService.isConnected ? "Terhubung" : "Tidak terhubung"}',
                      style: TextStyle(
                        color: _printerService.isConnected
                            ? KtColor.successText
                            : KtColor.danger,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_printerService.selectedDevice != null &&
                        _printerService.isConnected)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Printer: ${_printerService.selectedDevice!.name}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    if (_printerService.isConnected)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: ElevatedButton.icon(
                          onPressed: _isConnecting ? null : _disconnectPrinter,
                          icon: const Icon(Icons.bluetooth_disabled),
                          label: const Text('Putuskan Koneksi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KtColor.danger,
                            foregroundColor: KtColor.surface,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Daftar Printer Tersedia',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (_statusMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _statusMessage,
                  style: TextStyle(color: KtColor.warningText),
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _printerService.devices.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bluetooth_disabled,
                                  size: 64, color: KtColor.neutral400),
                              const SizedBox(height: 16),
                              Text(
                                'Tidak ada printer yang tersedia',
                                style: TextStyle(color: KtColor.neutral500),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _refreshDevices,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _printerService.devices.length,
                          itemBuilder: (context, index) {
                            final device = _printerService.devices[index];
                            final bool isSelected =
                                _printerService.selectedDevice?.address ==
                                    device.address;
                            final bool isConnected =
                                isSelected && _printerService.isConnected;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: isConnected
                                      ? KtColor.successText
                                      : Colors.transparent,
                                  width: isConnected ? 2 : 0,
                                ),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  Icons.print,
                                  color: isConnected
                                      ? KtColor.successText
                                      : KtColor.neutral600,
                                ),
                                title: Text(
                                  device.name ?? 'Unknown Device',
                                  style: TextStyle(
                                    fontWeight: isConnected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(device.address ?? ''),
                                trailing: ElevatedButton(
                                  onPressed: isConnected || _isConnecting
                                      ? null
                                      : () => _connectPrinter(device),
                                  child: Text(
                                      isConnected ? 'Terhubung' : 'Hubungkan'),
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
}
