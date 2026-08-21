import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kliktoko/profile_page/ProfilePage/HistoryKerjaPage.dart';
import 'package:kliktoko/leave_page/LeavePage/LeavePage.dart';
import 'package:kliktoko/payroll_page/PayrollPage/PayrollPage.dart';
import 'package:kliktoko/profile_page/ProfilePage/form_laporan_kerja_page.dart';
import 'package:kliktoko/APIService/ApiService.dart';
import 'package:kliktoko/storage/storage_service.dart';
import 'package:kliktoko/attendance_page/SharedAttendanceController.dart';
import 'package:kliktoko/theme/app_theme.dart';

class ProfileController extends GetxController {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  var username = ''.obs;
  var userRole = 'Karyawan'.obs;
  var totalShiftsPerMonth = '0'.obs;

  // For attendance history integration
  late SharedAttendanceController _attendanceController;

  // Observable for attendance history
  final RxList<Map<String, dynamic>> attendanceHistory =
      <Map<String, dynamic>>[].obs;
  final RxBool isHistoryLoading = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Initialize the shared attendance controller
    if (!Get.isRegistered<SharedAttendanceController>()) {
      Get.put(SharedAttendanceController());
    }
    _attendanceController = Get.find<SharedAttendanceController>();

    // Initialize storage and load user data
    _storageService.init().then((_) {
      loadUserData();
      calculateTotalShifts();
      loadAttendanceHistory();
    });

    // Listen for changes in attendance history to recalculate shifts
    ever(_attendanceController.attendanceHistory, (_) {
      calculateTotalShifts();
      updateAttendanceHistory();
    });
  }

  var isLoading = false.obs;
  var errorMessage = ''.obs;

  Future<void> loadUserData() async {
    if (isLoading.value) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      // First try to get user data from local storage
      final localUserData = await _storageService.getUserData();
      if (localUserData != null && localUserData.containsKey('name')) {
        username.value = localUserData['name'];
        print('Loaded username from storage: ${username.value}');

        // Set user role if available
        if (localUserData.containsKey('role')) {
          userRole.value = localUserData['role'];
        }
      }

      // Then try to refresh from API if we have a token
      final token = await _storageService.getToken();
      if (token == null) {
        if (localUserData == null) {
          // Only redirect if we couldn't get data from storage either
          errorMessage.value = 'Sesi login telah berakhir';
          Get.offAllNamed('/login');
        }
        return;
      }

      final userData = await _apiService.getUserData(token);
      if (userData.containsKey('name')) {
        username.value = userData['name'];

        // Update role if available from API
        if (userData.containsKey('role')) {
          userRole.value = userData['role'];
        }

        await _storageService.saveUserData(userData); // Update cached user data
        print('Updated username from API: ${username.value}');
      } else {
        errorMessage.value = 'Data pengguna tidak lengkap';
      }
    } catch (e) {
      // If we have a username from storage, don't show an error
      if (username.value.isEmpty) {
        errorMessage.value = 'Gagal memuat data pengguna';
      }
      print('Error loading user data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Calculate total shifts from attendance history
  void calculateTotalShifts() {
    try {
      // First check if attendance history is loaded
      if (_attendanceController.attendanceHistory.isEmpty) {
        // If history is still loading, don't update yet
        if (_attendanceController.isHistoryLoading.value) {
          return;
        }
        // If not loading but still empty, try to load it
        _attendanceController.loadAttendanceHistory();
        return;
      }

      // Get current month and year
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      // Filter attendance records for current month
      final currentMonthAttendance =
          _attendanceController.attendanceHistory.where((attendance) {
        // Get date from attendance record
        String dateStr = attendance['date'] ??
            attendance['attendance_date'] ??
            attendance['created_at']?.toString().split(' ')[0] ??
            '';

        if (dateStr.isEmpty) return false;

        try {
          final date = DateTime.parse(dateStr);
          return date.month == currentMonth && date.year == currentYear;
        } catch (e) {
          print('Error parsing date in calculateTotalShifts: $e');
          return false;
        }
      }).toList();

      // Count total shifts in current month
      totalShiftsPerMonth.value = currentMonthAttendance.length.toString();
      print(
          'Calculated total shifts for ${DateFormat('MMMM yyyy').format(now)}: ${totalShiftsPerMonth.value}');
    } catch (e) {
      print('Error calculating total shifts: $e');
      totalShiftsPerMonth.value = '0'; // Default to 0
    }
  }

  // Update attendance history from shared controller
  void updateAttendanceHistory() {
    if (_attendanceController.attendanceHistory.isEmpty &&
        !_attendanceController.isHistoryLoading.value) {
      return;
    }

    // Copy the attendance history from shared controller
    attendanceHistory.value = _attendanceController.attendanceHistory
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    print('Updated attendance history: ${attendanceHistory.length} records');
  }

  // Manually refresh attendance data and recalculate shifts
  Future<void> refreshAttendanceData() async {
    try {
      isHistoryLoading.value = true;
      await _attendanceController.loadAttendanceHistory();
      calculateTotalShifts();
      updateAttendanceHistory();
      isHistoryLoading.value = false;
    } catch (e) {
      print('Error refreshing attendance data: $e');
      isHistoryLoading.value = false;
    }
  }

  // Load attendance history directly
  Future<void> loadAttendanceHistory() async {
    try {
      isHistoryLoading.value = true;
      await _attendanceController.loadAttendanceHistory();
      updateAttendanceHistory();
      isHistoryLoading.value = false;
    } catch (e) {
      print('Error loading attendance history: $e');
      isHistoryLoading.value = false;
    }
  }

  // Cuti dan slip gaji tinggal di halaman profil, bukan di navigasi bawah:
  // kelima slotnya sudah terpakai, dan keduanya memang hal personal.
  void goToLeavePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LeavePage()),
    );
  }

  void goToPayrollPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PayrollPage()),
    );
  }

  void goToHistoryKerjaPage(BuildContext context) {
    // Make sure data is loaded before navigating
    loadAttendanceHistory();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HistoryKerjaPage()),
    );
  }

  void goToFormLaporanKerjaPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FormLaporanKerjaPage()),
    );
  }

  void goToThemeSettings(BuildContext context) {
    Navigator.pushNamed(context, '/theme');
  }

  Future<void> logout() async {
    try {
      isLoading.value = true; // Show loading state

      // Clear all user data from storage
      await _storageService.clearAllUserData();

      // Reset controller states
      username.value = '';
      errorMessage.value = '';

      // Navigate to start page (replace the entire navigation stack)
      Get.offAllNamed('/start');

      // Show success message using Get.snackbar instead of ScaffoldMessenger
      Get.snackbar(
        'Logout Berhasil',
        'Anda telah berhasil keluar dari aplikasi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.successColor,
        colorText: AppTheme.primaryText,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('Error during logout: $e');

      // Navigate to start page even if there's an error
      Get.offAllNamed('/start');

      // Show error message using Get.snackbar
      Get.snackbar(
        'Error',
        'Terjadi kesalahan saat logout',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
