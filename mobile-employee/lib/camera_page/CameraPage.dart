import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:kliktoko/gudang_page/GudangControllers/GudangController.dart';
import 'package:kliktoko/ReusablePage/detailpage.dart'; // Corrected import casing
import 'package:kliktoko/attendance_page/AttendanceController.dart';
import 'package:kliktoko/theme/app_theme.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  bool _isCameraPermissionGranted = false;
  bool _isFlashOn = false;
  bool _isProcessingCode = false;
  MobileScannerController? _controller;
  final GudangController _gudangController = Get.find<GudangController>();
  final AttendanceController _attendanceController =
      Get.put(AttendanceController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestCameraPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Improved lifecycle management
    if (_controller == null) return;

    try {
      if (state == AppLifecycleState.resumed) {
        _controller?.start();
      } else if (state == AppLifecycleState.inactive ||
          state == AppLifecycleState.paused ||
          state == AppLifecycleState.detached) {
        _controller?.stop();
      }
    } catch (e) {
      debugPrint('Error in lifecycle management: $e');
    }
  }

  Future<void> _requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();

      // Check if widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        _isCameraPermissionGranted = status.isGranted;
        if (_isCameraPermissionGranted) {
          _initializeScanner();
        }
      });
    } catch (e) {
      debugPrint('Error requesting camera permission: $e');
      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accessing camera permissions: $e')),
        );
      }
    }
  }

  void _initializeScanner() {
    try {
      _controller = MobileScannerController(
        facing: CameraFacing.back,
        torchEnabled: _isFlashOn,
      );
      _controller?.start();
    } catch (e) {
      debugPrint('Error initializing scanner: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing camera: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
      _controller?.dispose();
    } catch (e) {
      debugPrint('Error disposing camera controller: $e');
    }
    super.dispose();
  }

  // Toggle flash with error handling
  void _toggleFlash() async {
    try {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      await _controller?.toggleTorch();
    } catch (e) {
      // Revert state if failed
      if (mounted) {
        setState(() {
          _isFlashOn = !_isFlashOn;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not toggle flash: $e')),
        );
      }
    }
  }

  // Process the QR code data with improved error handling
  void _processQRCode(String code) async {
    if (_isProcessingCode) return;

    setState(() {
      _isProcessingCode = true;
    });

    try {
      // Pause scanning
      await _controller?.stop();

      // Search for product by the scanned code
      final foundProduct = await _searchProductByCode(code);

      // Show result overlay
      _showScanResultOverlay(code, foundProduct);
    } catch (e) {
      debugPrint('Error processing QR code: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing code: $e')),
        );
      }
      _resetScanner();
    }
  }

  // New method to search product by code
  Future<dynamic> _searchProductByCode(String code) async {
    // Trim and clean the code
    final cleanCode = code.trim();

    // Search for product by code using the controller
    final product = _gudangController.findProductByCode(cleanCode);

    // If product found, return it
    if (product != null) {
      return product;
    }

    // If not found, try to search by updating the search query
    // This will trigger a search in the inventory items
    _gudangController.updateSearchQuery(cleanCode);

    // Check if any results after filtering
    if (_gudangController.filteredItems.isNotEmpty) {
      // Return the first match
      return _gudangController.filteredItems.first;
    }

    // No product found
    return null;
  }

  // Updated to show product if found
  void _showScanResultOverlay(String code, dynamic foundProduct) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
              margin: EdgeInsets.only(bottom: 20),
            ),
            Icon(
              foundProduct != null ? Icons.check_circle : Icons.info_outline,
              color: foundProduct != null
                  ? AppTheme.primaryPurple
                  : AppTheme.warningColor,
              size: 60,
            ),
            SizedBox(height: 20),
            Text(
              foundProduct != null ? 'Product Found' : 'Code Scanned',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppTheme.lightBorderColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  SelectableText(
                    code,
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  if (foundProduct != null) ...[
                    SizedBox(height: 10),
                    Divider(),
                    SizedBox(height: 10),
                    Text(
                      foundProduct.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Size: ${foundProduct.size} • Stock: ${foundProduct.stock}",
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Rp.${foundProduct.price.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _resetScanner();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.borderColor,
                    foregroundColor: AppTheme.primaryText,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: Text('Scan Again'),
                ),
                if (foundProduct != null)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to product detail page
                      Get.to(() => ProductDetailPage(product: foundProduct));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    child: Text('View Details'),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Get.back(result: code); // Return the QR code value
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    child: Text('Confirm'),
                  ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    ).then((_) {
      if (mounted && _isProcessingCode) {
        _resetScanner();
      }
    });
  }

  // Reset scanner after processing a code
  void _resetScanner() {
    if (!mounted) return;

    setState(() {
      _isProcessingCode = false;
    });

    try {
      _controller?.start();
    } catch (e) {
      debugPrint('Error resetting scanner: $e');
      // Attempt to reinitialize if needed
      if (_controller == null) {
        _initializeScanner();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraPermissionGranted) {
      return _buildPermissionDeniedScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Scanner View with error handling
            _controller == null
                ? _buildLoadingIndicator()
                : MobileScanner(
                    controller: _controller,
                    onDetect: (capture) {
                      try {
                        final List<Barcode> barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty && !_isProcessingCode) {
                          final Barcode barcode = barcodes.first;
                          if (barcode.rawValue != null) {
                            _processQRCode(barcode.rawValue!);
                          }
                        }
                      } catch (e) {
                        debugPrint('Error detecting barcode: $e');
                      }
                    },
                    errorBuilder: (context, error, child) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error, color: AppTheme.errorColor, size: 50),
                            SizedBox(height: 10),
                            Text(
                              'Camera Error: ${error.errorCode}',
                              style: TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                _initializeScanner();
                              },
                              child: Text('Try Again'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

            // Scan overlay - Modified for ISBN size (narrower rectangle)
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.7,
                height: MediaQuery.of(context).size.width *
                    0.25, // Changed height to make it rectangular for ISBN
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isProcessingCode
                        ? AppTheme.lightText
                        : AppTheme.primaryPurple,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            // Top Controls - Updated title
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Get.back(),
                  ),
                  Text(
                    'Scan ISBN Code', // Updated title
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: _toggleFlash,
                  ),
                ],
              ),
            ),

            // Bottom Instructions - Updated for ISBN
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 50),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Loading indicator when camera is initializing6
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: AppTheme.primaryPurple,
          ),
          SizedBox(height: 20),
          Text(
            'Initializing camera...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  // Screen shown when camera permission is denied
  Widget _buildPermissionDeniedScreen() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt,
                  color: AppTheme.secondaryText,
                  size: 80,
                ),
                SizedBox(height: 20),
                Text(
                  'Camera Permission Required',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'Please grant camera permission to scan product codes.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final status = await Permission.camera.request();

                      if (!mounted) return;

                      setState(() {
                        _isCameraPermissionGranted = status.isGranted;
                        if (_isCameraPermissionGranted) {
                          _initializeScanner();
                        } else if (status.isPermanentlyDenied) {
                          // Show settings dialog if permission permanently denied
                          _showOpenSettingsDialog();
                        }
                      });
                    } catch (e) {
                      debugPrint('Error requesting permission: $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text('Grant Permission'),
                ),
                SizedBox(height: 15),
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Show dialog to open app settings if permission permanently denied
  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Camera Permission'),
        content: Text(
          'Camera permission was permanently denied. Please open settings to enable it manually.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
            ),
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
