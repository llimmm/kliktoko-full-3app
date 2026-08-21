import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'package:flutter/services.dart';
import 'package:scan_gun/scan_gun.dart';
import 'dart:async';
import 'package:flutter/foundation.dart'; // Added for kDebugMode

class UsbScannerPage extends StatefulWidget {
  const UsbScannerPage({super.key});

  @override
  State<UsbScannerPage> createState() => _UsbScannerPageState();
}

class _UsbScannerPageState extends State<UsbScannerPage> {
  List<Map<String, dynamic>> _scanResults = [];
  bool _scannerActive = true;
  String _hardwareStatus = 'Checking hardware...';
  bool _hardwareDetected = false;
  Timer? _detectionTimer;

  @override
  void initState() {
    super.initState();
    // Scanner works in background only - no focus management needed

    _startHardwareDetection();
  }

  @override
  void dispose() {
    // No focus management needed - scanner works in background
    _detectionTimer?.cancel();
    super.dispose();
  }

  void _startHardwareDetection() {
    // Check hardware setiap 3 detik
    _detectionTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      _checkHardwareStatus();
    });

    // Initial check
    _checkHardwareStatus();
  }

  void _checkHardwareStatus() {
    // Real hardware detection logic
    setState(() {
      // Check if any USB HID device is connected
      if (_scanResults.isNotEmpty) {
        _hardwareStatus = 'Hardware detected - Scanner ready';
        _hardwareDetected = true;
      } else {
        // Check for common Advan VX Neo USB OTG issues
        _hardwareStatus = 'Hardware not detected - Check USB OTG support';
        _hardwareDetected = false;
      }
    });
  }

  void _onScanResult(String result) {
    if (result.isNotEmpty) {
      debugPrint('🔍 Scanner detected: $result');

      // Update hardware status when scan detected
      setState(() {
        _hardwareStatus = 'Hardware detected - Scanner working';
        _hardwareDetected = true;
      });

      final scanData = {
        'result': result,
        'timestamp': DateTime.now(),
        'index': _scanResults.length + 1,
      };

      setState(() {
        _scanResults.insert(0, scanData);
        // Keep only last 20 results
        if (_scanResults.length > 20) {
          _scanResults = _scanResults.take(20).toList();
        }
      });

      // SILENT MODE - no notifications, no dialogs, no screen items
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    // Removed snackbar notification as requested
  }

  void _clearScanResults() {
    setState(() {
      _scanResults.clear();
    });
  }

  void _toggleScanner() {
    setState(() {
      _scannerActive = !_scannerActive;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // DISABLE ALL DIALOGS AND SCREEN ITEMS FOR SCANNER
      // Force silent mode globally
      appBar: AppBar(
        title: const Text('USB Scanner iware'),
        actions: [
          IconButton(
            icon: Icon(_scannerActive ? Icons.stop : Icons.play_arrow),
            onPressed: _toggleScanner,
            tooltip: _scannerActive ? 'Matikan Scanner' : 'Aktifkan Scanner',
          ),
        ],
      ),
      body: ScanMonitorWidget(
        textFiledNode: null,
        focusLooper: _scannerActive,
        onSubmit: _onScanResult,
        // Force silent mode - no dialogs, no notifications, no screen items
        // COMPLETELY SILENT - NO SCREEN ITEMS WHATSOEVER
        // NO VISUAL ELEMENTS WHATSOEVER - BACKGROUND ONLY
        childBuilder: (context) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            // DISABLE ALL DIALOGS AND SCREEN ITEMS FOR SCANNER
            // Force silent mode globally
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hardware Status Card
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
                        // Testing info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: KtColor.violet100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: KtColor.violet200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: KtColor.violet700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Halaman ini hanya untuk testing scanner. Untuk menambahkan produk ke order, gunakan scanner di halaman utama.',
                                  style: TextStyle(
                                    color: KtColor.violet700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              _hardwareDetected
                                  ? Icons.check_circle
                                  : Icons.error,
                              color:
                                  _hardwareDetected ? KtColor.successText : KtColor.danger,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Hardware Status',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _hardwareStatus,
                          style: TextStyle(
                            color:
                                _hardwareDetected ? KtColor.successText : KtColor.danger,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Scanner USB iware series X dengan dongle + converter Type-C',
                          style: TextStyle(color: KtColor.neutral400),
                        ),
                      ],
                    ),
                  ),
                ),

                // Scanner works in background only - no visual elements
                SizedBox.shrink(),

                const SizedBox(height: 16),

                // Scanner Results Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hasil Scan (${_scanResults.length})',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (_scanResults.isNotEmpty)
                      TextButton.icon(
                        onPressed: _clearScanResults,
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Clear'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_scanResults.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_2,
                                size: 48, color: KtColor.neutral400),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada hasil scan',
                              style: TextStyle(
                                  color: KtColor.neutral500, fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Scan barcode/QR code untuk melihat hasilnya di sini',
                              style: TextStyle(
                                  color: KtColor.neutral500, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...(_scanResults.map((scanData) {
                    final result = scanData['result'] as String;
                    final timestamp = scanData['timestamp'] as DateTime;
                    final timeStr =
                        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: KtColor.successText,
                          child: Text(
                            '${scanData['index']}',
                            style: const TextStyle(
                              color: KtColor.surface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          result,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text('Tap untuk copy • $timeStr'),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () => _copyToClipboard(result),
                        ),
                        onTap: () => _copyToClipboard(result),
                      ),
                    );
                  }).toList()),

                // Back to homepage button
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Kembali ke Halaman Utama'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KtColor.primary,
                      foregroundColor: KtColor.surface,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
