import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../attendance_page/AttendanceApiService.dart';
import '../attendance_page/SharedAttendanceController.dart';
import '../theme/app_theme.dart';

class AttendanceCameraPage extends StatefulWidget {
  final String shiftId;

  const AttendanceCameraPage({Key? key, required this.shiftId})
      : super(key: key);

  @override
  State<AttendanceCameraPage> createState() => _AttendanceCameraPageState();
}

class _AttendanceCameraPageState extends State<AttendanceCameraPage>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraPermissionGranted = false;
  bool _isFlashOn = false;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  File? _capturedImage;
  final AttendanceApiService _attendanceService = AttendanceApiService();
  final SharedAttendanceController _attendanceController =
      SharedAttendanceController.to;

  // Color scheme based on app theme
  final Color primaryPurple = AppTheme.primaryPurple;
  final Color darkPurple = AppTheme.primaryText;
  final Color lightPurple = AppTheme.lightPurpleBackground;
  final Color accentPurple = AppTheme.accentPurple;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestCameraPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;

    try {
      if (state == AppLifecycleState.resumed) {
        _initializeCamera();
      } else if (state == AppLifecycleState.inactive ||
          state == AppLifecycleState.paused ||
          state == AppLifecycleState.detached) {
        _cameraController?.dispose();
      }
    } catch (e) {
      debugPrint('Error in lifecycle management: $e');
    }
  }

  Future<void> _requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();

      if (!mounted) return;

      setState(() {
        _isCameraPermissionGranted = status.isGranted;
        if (_isCameraPermissionGranted) {
          _initializeCamera();
        }
      });
    } catch (e) {
      debugPrint('Error requesting camera permission: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accessing camera permissions: $e')),
        );
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras available');
      }

      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing camera: $e')),
        );
      }
    }
  }

  Future<void> _toggleFlash() async {
    try {
      if (_cameraController == null || !_cameraController!.value.isInitialized)
        return;

      if (!_cameraController!.value.flashMode.index
              .isEqual(FlashMode.off.index) &&
          !_cameraController!.value.flashMode.index
              .isEqual(FlashMode.torch.index)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flash not supported on this device')),
        );
        return;
      }

      setState(() {
        _isFlashOn = !_isFlashOn;
      });

      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not toggle flash: $e')),
      );
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    try {
      setState(() {
        _isProcessing = true;
      });

      final XFile photo = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = File(photo.path);
      });
    } catch (e) {
      debugPrint('Error taking picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking picture: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _checkInWithPhoto() async {
    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a photo first')),
      );
      return;
    }

    try {
      setState(() {
        _isProcessing = true;
      });

      await _attendanceService.checkInWithPhoto(
          widget.shiftId, _capturedImage!);

      await _attendanceController.checkAttendanceStatus();
      await _attendanceController.loadAttendanceHistory();

      Get.back(result: true);

      Get.snackbar(
        'Check-in Successful',
        'Your attendance has been recorded',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: accentPurple,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('Error during check-in with photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during check-in: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _retakePicture() {
    setState(() {
      _capturedImage = null;
    });
  }

  @override
  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
      _cameraController?.dispose();
    } catch (e) {
      debugPrint('Error disposing camera controller: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPurple,
      appBar: AppBar(
        title: const Text(
          'Foto Absensi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: darkPurple,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          if (_isCameraInitialized && _capturedImage == null)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: IconButton(
                icon: Icon(
                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: _isFlashOn ? primaryPurple : Colors.white,
                  size: 24,
                ),
                onPressed: _toggleFlash,
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isCameraPermissionGranted) {
      return _buildPermissionDeniedUI();
    }

    if (!_isCameraInitialized) {
      return _buildLoadingUI();
    }

    if (_capturedImage != null) {
      return _buildImagePreviewUI();
    }

    return _buildCameraUI();
  }

  Widget _buildLoadingUI() {
    return Container(
      color: lightPurple,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryPurple),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Menyiapkan Kamera...',
                    style: TextStyle(
                      fontSize: 16,
                      color: darkPurple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedUI() {
    return Container(
      color: lightPurple,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  size: 60,
                  color: AppTheme.errorColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Izin Kamera Diperlukan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkPurple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Untuk mengambil foto absensi, aplikasi memerlukan izin akses kamera',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.secondaryText,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _requestCameraPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Berikan Izin',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraUI() {
    return Container(
      color: lightPurple,
      child: Column(
        children: [
          // Header info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      color: primaryPurple,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Shift ${widget.shiftId}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Posisikan wajah Anda di dalam frame',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Camera preview - Made larger
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    CameraPreview(_cameraController!),
                    // Camera frame overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: primaryPurple.withValues(alpha: 0.8),
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    // Corner indicators
                    Positioned(
                      top: 15,
                      left: 15,
                      child: _buildCornerIndicator(true, true),
                    ),
                    Positioned(
                      top: 15,
                      right: 15,
                      child: _buildCornerIndicator(true, false),
                    ),
                    Positioned(
                      bottom: 15,
                      left: 15,
                      child: _buildCornerIndicator(false, true),
                    ),
                    Positioned(
                      bottom: 15,
                      right: 15,
                      child: _buildCornerIndicator(false, false),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Camera controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Spacer
                const SizedBox(width: 50),

                // Capture button
                GestureDetector(
                  onTap: _isProcessing ? null : _takePicture,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isProcessing ? AppTheme.lightText : primaryPurple,
                      boxShadow: [
                        BoxShadow(
                          color: primaryPurple.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isProcessing
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 28,
                          ),
                  ),
                ),

                // Spacer
                const SizedBox(width: 50),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCornerIndicator(bool isTop, bool isLeft) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: primaryPurple,
            width: 3,
          ),
          left: BorderSide(
            color: primaryPurple,
            width: 3,
          ),
          right: isLeft
              ? BorderSide.none
              : BorderSide(
                  color: primaryPurple,
                  width: 3,
                ),
          bottom: isTop
              ? BorderSide.none
              : BorderSide(
                  color: primaryPurple,
                  width: 3,
                ),
        ),
      ),
    );
  }

  Widget _buildImagePreviewUI() {
    return Container(
      color: lightPurple,
      child: Column(
        children: [
          // Header info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: primaryPurple,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Preview Foto',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Periksa foto Anda sebelum absen',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Image preview - Made larger
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _capturedImage!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // Retake button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _retakePicture,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.borderColor,
                      foregroundColor: darkPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.refresh, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Ambil Ulang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Check-in button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _checkInWithPhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Absen',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
