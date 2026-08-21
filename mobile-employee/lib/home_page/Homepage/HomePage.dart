import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../../navigation/NavController.dart';
import '../HomeController/HomeController.dart';
import 'package:intl/intl.dart';
import '../../../gudang_page/GudangModel/ProductModel.dart';
import 'package:kliktoko/profile_page/ProfilePage/HistoryKerjaPage.dart'; // Added import for HistoryKerjaPage
import '../../../APIService/ApiService.dart';
import '../../theme/app_theme.dart';
import '../../theme/kt_components.dart';

// Create a separate controller just for the clock
class ClockController extends GetxController {
  var timeString = ''.obs;
  var dateString = ''.obs;
  var isLoading = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;
  Timer? _timer;
  Timer? _apiRefreshTimer;
  DateTime? _lastApiTime;
  int _apiTimeOffset = 0; // Offset in seconds from API time

  final ApiService _apiService = ApiService();

  @override
  void onInit() {
    super.onInit();
    // Initialize time immediately
    _updateTimeFromAPI();
    // Start timer to update every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    // Start timer to refresh from API every 5 minutes
    _apiRefreshTimer =
        Timer.periodic(const Duration(minutes: 5), (_) => _updateTimeFromAPI());
  }

  @override
  void onClose() {
    _timer?.cancel();
    _apiRefreshTimer?.cancel();
    super.onClose();
  }

  void _updateTime() {
    if (_lastApiTime != null) {
      // Calculate current time based on API time + offset
      final now = _lastApiTime!.add(Duration(seconds: _apiTimeOffset));
      timeString.value = DateFormat('HH:mm:ss').format(now);
      dateString.value = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
      _apiTimeOffset++;
    } else {
      // Fallback to system time if API time not available
      final now = DateTime.now();
      timeString.value = DateFormat('HH:mm:ss').format(now);
      dateString.value = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
    }
  }

  Future<void> _updateTimeFromAPI() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final response = await _apiService.getCurrentTimezone();

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final currentTime = data['current_time'];

        if (currentTime != null) {
          // Parse the API time
          _lastApiTime = DateTime.parse(currentTime);
          _apiTimeOffset = 0; // Reset offset

          // Update display immediately
          timeString.value = DateFormat('HH:mm:ss').format(_lastApiTime!);
          dateString.value =
              DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_lastApiTime!);

          print('Updated time from API: $currentTime');
        }
      } else {
        // If API fails, fallback to system time
        _lastApiTime = null;
        _updateTime();
        hasError.value = true;
        errorMessage.value = 'Failed to get time from server, using local time';
        print('API time failed, using system time: ${response['error']}');
      }
    } catch (e) {
      print('Error fetching time from API: $e');
      // Fallback to system time
      _lastApiTime = null;
      _updateTime();
      hasError.value = true;
      errorMessage.value = 'Failed to get time from server, using local time';
    } finally {
      isLoading.value = false;
    }
  }

  // Method to manually refresh time from API
  Future<void> refreshTime() async {
    await _updateTimeFromAPI();
  }
}

// Simple clock widget
class ClockWidget extends StatelessWidget {
  const ClockWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use Get.put to ensure controller is registered before use
    final controller = Get.put(ClockController(), tag: 'clock');

    return Center(
      child: Column(
        children: [
          // Current time with loading indicator
          Obx(() {
            if (controller.isLoading.value) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.secondaryText),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              );
            }

            return Text(
              controller.timeString.value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 40,
                color: AppTheme.primaryText,
              ),
            );
          }),
          const SizedBox(height: 4),
          // Current date
          Obx(() => Text(
                controller.dateString.value,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              )),
          const SizedBox(height: 8),
          // Error message only (no separate refresh button)
          Obx(() {
            if (controller.hasError.value) {
              return Text(
                controller.errorMessage.value,
                style: TextStyle(
                  fontSize: 12,
                  // warningColor #d97706 di atas latar violet50 hanya 2,90:1;
                  // warningText #b45309 = 4,58:1.
                  color: KtColor.warningText,
                ),
                textAlign: TextAlign.center,
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}

class HomePage extends GetView<HomeController> {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Make sure controller is initialized and registered with Get
    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController());
    }
    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    // Call loadUserData explicitly to ensure username is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.checkAuthAndLoadData();
    });
    return Scaffold(
        backgroundColor:
            AppTheme.lightPurpleBackground, // Light purple background color
        body: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top,
            ),
            child: RefreshIndicator(
              onRefresh: () async {
                // Refresh time from API first
                try {
                  final clockController =
                      Get.find<ClockController>(tag: 'clock');
                  await clockController.refreshTime();
                } catch (e) {
                  print('Error refreshing time: $e');
                }

                // Refresh radius location check
                try {
                  await controller.attendanceController.refreshLocation();
                } catch (e) {
                  print('Error refreshing location: $e');
                }

                // Then refresh other data
                await controller.loadProducts();
                // Also refresh attendance status when pulling to refresh
                try {
                  await controller.attendanceController.checkAttendanceStatus();
                  // Load attendance history
                  await controller.attendanceController.loadAttendanceHistory();
                } catch (e) {
                  print('Error refreshing attendance status: $e');
                }
                return;
              },
              color: AppTheme.primaryPurple,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      screenWidth *
                          0.04, // Horizontal padding (4% of screen width)
                      screenHeight * 0.04, // Top padding (4% of screen height)
                      screenWidth *
                          0.04, // Horizontal padding (4% of screen width)
                      screenWidth *
                          0.04), // Bottom padding (4% of screen width)
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Clock at the top
                      const ClockWidget(),
                      SizedBox(height: screenHeight * 0.04),
                      // Layered cards - Attendance status and Category cards
                      _buildLayeredCards(screenWidth, screenHeight),
                      SizedBox(height: screenHeight * 0.025),
                      // Out of stock section
                      _buildOutOfStockSection(screenWidth, screenHeight),
                      // Add extra space at the bottom to avoid navigation bar overlap
                      SizedBox(height: screenHeight * 0.08),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildLayeredCards(double screenWidth, double screenHeight) {
    return Column(
      children: [
        // Attendance status card
        _buildAttendanceCard(screenWidth, screenHeight),
        SizedBox(height: screenHeight * 0.025),
        // Attendance history card
        _buildAttendanceHistoryCard(screenWidth, screenHeight),
      ],
    );
  }

  Widget _buildAttendanceCard(double screenWidth, double screenHeight) {
    return KtCard(
      padding: EdgeInsets.all(screenWidth * 0.0399),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Kehadiran',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.secondaryText,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAttendanceInfo(screenWidth, screenHeight),
              _buildAttendanceButton(screenHeight),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceInfo(double screenWidth, double screenHeight) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Penanda jangkauan lokasi — ini DATA keadaan (di dalam / di luar
          // radius toko), jadi pengecualian sadar terhadap penjatahan warna,
          // sama seperti chip status lain. Dulu tint dari warnanya sendiri:
          // koral di luar jangkauan hanya 3,09:1 di piksel jadi. Blok pekat
          // berteks hitam: hijau 14,96:1, koral 11,06:1.
          Obx(() {
            final within = controller.attendanceController.isWithinRadius.value;
            return Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: KtStatusChip(
                  label: controller.attendanceController.locationStatus.value,
                  status: within ? KtStatus.success : KtStatus.danger,
                  icon: within ? Icons.location_on : Icons.location_off,
                ),
              ),
            );
          }),
          Obx(() {
            // Get status text and color based on attendance state
            String statusText = controller.getStatusMessage();
            Color statusColor = controller.getStatusColor();

            return Text(
              statusText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth < 360 ? 18 : 20,
                color: statusColor,
              ),
              overflow: TextOverflow.ellipsis,
            );
          }),
          SizedBox(height: screenHeight * 0.005),
          Obx(() {
            // Get shift time
            final shiftTime =
                controller.getShiftTime(controller.selectedShift.value);

            // Check if it's night time message (Selamat Tidur)
            final bool isNightMessage = shiftTime == 'Selamat Tidur!';

            return isNightMessage
                ? Text(
                    shiftTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.accentPurple,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : Row(
                    children: [
                      Text(
                        'Shift ${controller.selectedShift.value} | ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          shiftTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondaryText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
          }),
          // Add check-in time if available
          Obx(() {
            if (controller.hasCheckedIn.value &&
                controller.attendanceController.currentAttendance.value
                        .checkInTime !=
                    null &&
                controller.attendanceController.currentAttendance.value
                    .checkInTime!.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.login, size: 14, color: AppTheme.primaryPurple),
                    const SizedBox(width: 4),
                    Text(
                      'Check-in: ${controller.attendanceController.currentAttendance.value.checkInTime}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryPurple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          // Add check-out time if available
          Obx(() {
            if (controller.hasCheckedOut.value &&
                controller.attendanceController.currentAttendance.value
                        .checkOutTime !=
                    null &&
                controller.attendanceController.currentAttendance.value
                    .checkOutTime!.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    // infoColor #0284c7 hanya 4,10:1 di atas putih; infoText
                    // #0369a1 = 5,93:1. Ikon ikut supaya sewarna teksnya.
                    Icon(Icons.logout, size: 14, color: KtColor.infoText),
                    const SizedBox(width: 4),
                    Text(
                      'Check-out: ${controller.attendanceController.currentAttendance.value.checkOutTime}',
                      style: TextStyle(
                        fontSize: 12,
                        color: KtColor.infoText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  // Card showing attendance history
  Widget _buildAttendanceHistoryCard(double screenWidth, double screenHeight) {
    return KtCard(
      padding: EdgeInsets.all(screenWidth * 0.0399),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Riwayat Kehadiran',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryText)),
          SizedBox(height: screenHeight * 0.015),
            Obx(() {
              if (controller.attendanceController.isHistoryLoading.value) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
                      ),
                    ),
                  ),
                );
              }

              if (controller.attendanceController.attendanceHistory.isEmpty) {
                // Ikon dalam blok berteks/berikon hitam (16,55:1), bukan ikon
                // neutral400 pudar yang hanya 2,56:1 di atas putih.
                return const KtEmptyState(
                  icon: Icons.history_toggle_off,
                  title: 'Belum ada riwayat kehadiran',
                );
              }

              // Show most recent 3 attendance records
              final historyToShow = controller
                  .attendanceController.attendanceHistory
                  .take(3)
                  .toList();

              return Column(
                children: [
                  ...historyToShow
                      .map((item) => _buildHistoryItemNew(item, screenWidth)),
                  if (controller.attendanceController.attendanceHistory.length >
                      3)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Center(
                        child: TextButton(
                          onPressed: () {
                            Get.to(() => const HistoryKerjaPage());
                          },
                          child: Text('Lihat Semua',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryPurple,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
    );
  }

  // Helper widget to build history items for new API format
  Widget _buildHistoryItemNew(Map<String, dynamic> item, double screenWidth) {
    // Extract and format date
    String date = item['tanggal'] ?? '';
    try {
      if (date.isNotEmpty) {
        final parsedDate = DateTime.parse(date);
        date = DateFormat('d MMM yyyy', 'id_ID').format(parsedDate);
      }
    } catch (e) {
      print('Error parsing date: $e');
    }

    // Extract data from new API format
    String shiftName = item['nama_shift'] ?? '';
    String status = item['status'] ?? '';

    // Determine if late based on status
    bool isLate = status.toLowerCase().contains('terlambat');

    // Baris di dalam kartu putih: rata halaman (violet50), border hitam, tanpa
    // bayangan — dua bayangan keras bertindihan terbaca sebagai kesalahan.
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: KtBrutal.surface(
        background: KtColor.background,
        raised: false,
      ),
      child: Row(
        children: [
          // Shift name
          Expanded(
            flex: 2,
            child: Text(
              shiftName,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Date
          Expanded(
            flex: 2,
            child: Text(
              date,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppTheme.primaryText,
              ),
            ),
          ),
          // Status — chip keadaan (data): kuning untuk terlambat (15,93:1),
          // hijau untuk tepat waktu (14,96:1). Dulu tint kuning 15% hanya
          // 2,49:1 di piksel jadi.
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: KtStatusChip(
                label: status,
                status: isLate ? KtStatus.warning : KtStatus.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceButton(double screenHeight) {
    // Adjust button height based on screen size
    final buttonHeight = screenHeight < 600 ? 70.0 : 90.0;

    // CTA "buka absensi" — satu aksen merek layar ini. Ungu berteks/berikon
    // putih = 5,70:1. Border hitam + bayangan keras yang benar-benar tertekan
    // saat disentuh, bukan glow abu lembut yang di ambang terlihat.
    return KtPressable(
      onTap: () => Get.find<NavController>().changePage(3),
      child: Container(
        height: buttonHeight,
        width: KtBrutal.minTapTarget, // android.md: target sentuh >= 48dp
        decoration: KtBrutal.block(KtColor.primary, raised: true),
        child: const Center(
          child: Icon(
            Icons.chevron_right,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildOutOfStockSection(double screenWidth, double screenHeight) {
    // Primary purple color
    final Color primaryPurple = AppTheme.primaryPurple;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      clipBehavior: Clip.hardEdge,
      // Permukaan gelap sebagai jangkar visual layar. Border hitam + bayangan
      // keras, sama seperti kartu putih — permukaan setengah-brutal terbaca
      // sebagai rusak.
      decoration: KtBrutal.surface(
        background: KtColor.neutral900,
        raised: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOutOfStockHeader(screenWidth),
          SizedBox(height: screenHeight * 0.005),
          const Text(
            'Ayo segera tambah barang!',
            // neutral400 di atas kartu gelap = 6,91:1.
            style: TextStyle(color: KtColor.neutral400, fontSize: 12),
          ),
          SizedBox(height: screenHeight * 0.02),
          SizedBox(
            height: 100, // Fixed height since no text below
            child: Obx(() {
              // Show error message if there's an error
              if (controller.hasError.value) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Ikon galat di kartu gelap: coral (9,33:1), bukan
                      // danger #dc2626 yang cuma 3,67:1 di sini.
                      Icon(Icons.error_outline,
                          color: KtBlockColor.coral, size: 30),
                      SizedBox(height: 8),
                      Text(
                        controller.errorMessage.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (controller.errorMessage.value
                          .contains('session')) ...[
                        SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Get.offAllNamed('/login'),
                          style: TextButton.styleFrom(
                            backgroundColor: primaryPurple,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }

              // Show loading indicator
              if (controller.isLoading.value) {
                // Putih di atas kartu gelap (17,72:1); ungu hanya 3,11:1.
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                );
              }

              final outOfStockItems =
                  controller.getOutOfStockItemsForDisplay(3);

              // Show message if no items
              if (outOfStockItems.isEmpty) {
                return const Center(
                  child: Text(
                    'Tidak ada item stok habis',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                );
              }

              // Display the items
              return ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  ...outOfStockItems.map((item) => _buildProductItem(item)),
                  SizedBox(width: screenWidth * 0.03),
                  if (controller.outOfStockProducts.length > 3)
                    _buildMoreButton(primaryPurple),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildOutOfStockHeader(double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Stok Habis',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        // Di kartu gelap, ungu jatuh ke 3,11:1. Kontrol ini putih di atas
        // gelap (17,72:1): border putih + teks putih.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(KtRadius.sm),
          ),
          child: TextButton(
            onPressed: () => Get.find<NavController>().changePage(1),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              children: const [
                Text(
                  'Lihat gudang',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, color: Colors.white, size: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoreButton(Color primaryPurple) {
    return SizedBox(
      width: 35,
      height: 100, // Match the height of product cards
      child: Center(
        child: Container(
          height: 30,
          width: 30,
          decoration: BoxDecoration(
            color: primaryPurple,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductItem(Product item) {
    // Primary purple color
    final Color primaryPurple = AppTheme.primaryPurple;

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 10),
      child: Container(
        height: 80, // Fixed height for image only
        width: 100,
        margin: const EdgeInsets.only(top: 5),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: primaryPurple,
                borderRadius: BorderRadius.circular(KtRadius.sm),
                border: KtBrutal.outline,
              ),
              child: item.image != null && item.image!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(KtRadius.sm),
                      child: Image.network(
                        item.image!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading image: $error');
                          return const Center(
                            child: Icon(
                              Icons.checkroom,
                              size: 30, // Reduced icon size
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.checkroom,
                        size: 30, // Reduced icon size
                        color: Colors.white,
                      ),
                    ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(KtRadius.sm),
                  color: Colors.black.withValues(alpha: 0.7),
                ),
                child: const Center(
                  child: Text(
                    'STOK HABIS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10, // Reduced font size
                    ),
                  ),
                ),
              ),
            ),
            // Badge ukuran di pojok kanan atas
            Positioned(
              top: 3,
              right: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.size ?? 'N/A',
                  style: const TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Code badge di pojok kiri atas (jika ada)
            if (item.code != null)
              Positioned(
                top: 3,
                left: 3,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    item.code!,
                    style: const TextStyle(
                      color: AppTheme.primaryText,
                      fontSize: 7,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
