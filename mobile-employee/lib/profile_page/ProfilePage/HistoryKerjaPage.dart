import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kliktoko/attendance_page/AttendanceController.dart';
import '../../theme/app_theme.dart';

class HistoryKerjaPage extends StatefulWidget {
  const HistoryKerjaPage({Key? key}) : super(key: key);

  @override
  State<HistoryKerjaPage> createState() => _HistoryKerjaPageState();
}

class _HistoryKerjaPageState extends State<HistoryKerjaPage> {
  String selectedFilter = 'Semua';
  final List<String> filterOptions = [
    'Semua',
    '7 Hari Lalu',
    'Tepat Waktu',
    'Terlambat',
  ];

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AttendanceController>()) {
      Get.put(AttendanceController());
    }
    final controller = Get.find<AttendanceController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.attendanceController.loadAttendanceHistory();
    });

    return Scaffold(
      backgroundColor: AppTheme.lightPurpleBackground,
      appBar: AppBar(
        title: const Text(
          'Riwayat Kehadiran',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppTheme.darkCardBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              icon:
                  const Icon(Icons.filter_list, color: Colors.white, size: 24),
              onSelected: (String value) {
                setState(() {
                  selectedFilter = value;
                });
              },
              itemBuilder: (BuildContext context) =>
                  filterOptions.map((String option) {
                return PopupMenuItem<String>(
                  value: option,
                  child: Row(
                    children: [
                      Icon(
                        _getFilterIcon(option),
                        size: 18,
                        color: selectedFilter == option
                            ? AppTheme.primaryPurple
                            : AppTheme.secondaryText,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        option,
                        style: TextStyle(
                          color: selectedFilter == option
                              ? AppTheme.primaryPurple
                              : AppTheme.primaryText,
                          fontWeight: selectedFilter == option
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (selectedFilter == option) ...[
                        const Spacer(),
                        const Icon(
                          Icons.check,
                          size: 16,
                          color: AppTheme.primaryPurple,
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
              onPressed: () =>
                  controller.attendanceController.loadAttendanceHistory(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: GetX<AttendanceController>(
          builder: (ctrl) => ctrl.attendanceController.isHistoryLoading.value
              ? _buildLoadingState()
              : _buildContent(context, ctrl),
        ),
      ),
    );
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'Semua':
        return Icons.list;
      case '7 Hari Lalu':
        return Icons.calendar_today;
      case 'Tepat Waktu':
        return Icons.check_circle;
      case 'Terlambat':
        return Icons.schedule;
      default:
        return Icons.list;
    }
  }

  Widget _buildLoadingState() {
    return Container(
      color: AppTheme.lightPurpleBackground,
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
                children: const [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Memuat Riwayat...',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.primaryText,
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

  Widget _buildContent(BuildContext context, AttendanceController controller) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh radius location check first
        try {
          await controller.refreshLocation();
        } catch (e) {
          print('Error refreshing location: $e');
        }

        // Then refresh attendance history
        await controller.attendanceController.loadAttendanceHistory();
      },
      color: AppTheme.primaryPurple,
      child: controller.attendanceController.attendanceHistory.isEmpty
          ? _buildEmptyState()
          : _buildHistoryList(context, controller),
    );
  }

  Widget _buildHistoryList(
      BuildContext context, AttendanceController controller) {
    List<Map<String, dynamic>> filteredHistory =
        _getFilteredHistory(controller);

    if (filteredHistory.isEmpty) {
      return _buildEmptyFilterState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredHistory.length,
      itemBuilder: (context, index) {
        final item = filteredHistory[index];
        return _buildHistoryCard(item, context);
      },
    );
  }

  Widget _buildEmptyFilterState() {
    String message = '';
    String subtitle = '';
    IconData icon = Icons.filter_list;

    switch (selectedFilter) {
      case '7 Hari Lalu':
        message = 'Tidak Ada Riwayat 7 Hari Terakhir';
        subtitle = 'Belum ada catatan kehadiran dalam 7 hari terakhir';
        icon = Icons.calendar_today;
        break;
      case 'Tepat Waktu':
        message = 'Tidak Ada Riwayat Tepat Waktu';
        subtitle = 'Belum ada catatan kehadiran tepat waktu';
        icon = Icons.check_circle;
        break;
      case 'Terlambat':
        message = 'Tidak Ada Riwayat Terlambat';
        subtitle = 'Belum ada catatan kehadiran terlambat';
        icon = Icons.schedule;
        break;
      default:
        message = 'Tidak Ada Riwayat';
        subtitle = 'Belum ada catatan kehadiran';
        icon = Icons.history;
    }

    return Container(
      color: AppTheme.lightPurpleBackground,
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
                  color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                // Dulu Icons.filter_list mati di sini, sehingga ikon yang
                // sudah dipilih per filter di atas dibuang percuma dan semua
                // keadaan kosong tampil sama.
                child: Icon(
                  icon,
                  size: 60,
                  color: AppTheme.primaryPurple,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 20,
                  color: AppTheme.primaryText,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.secondaryText,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    selectedFilter = 'Semua';
                  });
                },
                icon: const Icon(Icons.refresh, color: AppTheme.primaryPurple),
                label: const Text(
                  'Lihat Semua Riwayat',
                  style: TextStyle(
                    color: AppTheme.primaryPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: AppTheme.lightPurpleBackground,
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
            children: const [
              SizedBox(height: 24),
              Text(
                'Belum Ada Riwayat',
                style: TextStyle(
                  fontSize: 20,
                  color: AppTheme.primaryText,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Riwayat kehadiran akan muncul setelah Anda melakukan absen',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.secondaryText,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredHistory(
      AttendanceController controller) {
    List<Map<String, dynamic>> allHistory =
        controller.attendanceController.attendanceHistory;

    switch (selectedFilter) {
      case 'Semua':
        return allHistory;
      case '7 Hari Lalu':
        return _filterByLast7Days(allHistory);
      case 'Tepat Waktu':
        return _filterByStatus(allHistory, 'Tepat Waktu');
      case 'Terlambat':
        return _filterByStatus(allHistory, 'Terlambat');
      default:
        return allHistory;
    }
  }

  List<Map<String, dynamic>> _filterByLast7Days(
      List<Map<String, dynamic>> history) {
    DateTime now = DateTime.now();
    DateTime sevenDaysAgo = now.subtract(const Duration(days: 7));

    return history.where((item) {
      try {
        String dateStr = item['tanggal'] ?? '';
        if (dateStr.isEmpty) return false;

        DateTime itemDate = DateTime.parse(dateStr);
        return itemDate.isAfter(sevenDaysAgo) ||
            itemDate.isAtSameMomentAs(sevenDaysAgo);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  List<Map<String, dynamic>> _filterByStatus(
      List<Map<String, dynamic>> history, String status) {
    return history.where((item) {
      String itemStatus = item['status'] ?? '';

      if (status == 'Tepat Waktu') {
        return !itemStatus.toLowerCase().contains('terlambat');
      } else if (status == 'Terlambat') {
        return itemStatus.toLowerCase().contains('terlambat');
      }

      return false;
    }).toList();
  }

  Widget _buildHistoryCard(Map<String, dynamic> item, BuildContext context) {
    String date = item['tanggal'] ?? '';
    try {
      if (date.isNotEmpty) {
        final parsedDate = DateTime.parse(date);
        date = DateFormat('d MMM yyyy', 'id_ID').format(parsedDate);
      }
    } catch (_) {}

    String shiftName = item['nama_shift'] ?? '';
    String shiftTime = item['waktu_shift'] ?? '';
    String status = item['status'] ?? '';
    String checkIn = item['check_in'] ?? '-';

    bool isLate = status.toLowerCase().contains('terlambat');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showHistoryDetail(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isLate ? Icons.schedule : Icons.check_circle,
                      size: 20,
                      color: isLate
                          ? AppTheme.warningColor
                          : AppTheme.primaryPurple,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shiftName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryText,
                            ),
                          ),
                          Text(
                            shiftTime,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLate
                            ? AppTheme.warningColor.withValues(alpha: 0.1)
                            : AppTheme.primaryPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isLate
                              ? AppTheme.warningColor
                              : AppTheme.primaryPurple,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppTheme.secondaryText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppTheme.secondaryText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      checkIn,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: AppTheme.lightText,
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

  void _showHistoryDetail(Map<String, dynamic> item) {
    String date = item['tanggal'] ?? '';
    try {
      if (date.isNotEmpty) {
        final parsedDate = DateTime.parse(date);
        date = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(parsedDate);
      }
    } catch (_) {}

    String shiftName = item['nama_shift'] ?? '';
    String shiftTime = item['waktu_shift'] ?? '';
    String status = item['status'] ?? '';
    String checkIn = item['check_in'] ?? '-';
    String checkOut = item['check_out'] ?? '-';
    String durasi = item['durasi'] ?? '';

    bool isLate = status.toLowerCase().contains('terlambat');

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.history,
                    color: AppTheme.primaryPurple,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Detail Kehadiran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryText,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.secondaryText),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSimpleDetailRow('Tanggal', date),
              const SizedBox(height: 16),
              _buildSimpleDetailRow('Shift', '$shiftName ($shiftTime)'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Status: ',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLate
                          ? AppTheme.warningColor.withValues(alpha: 0.1)
                          : AppTheme.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isLate
                            ? AppTheme.warningColor
                            : AppTheme.primaryPurple,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSimpleDetailRow('Waktu Masuk', checkIn),
              const SizedBox(height: 16),
              _buildSimpleDetailRow('Waktu Keluar', checkOut),
              if (durasi.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSimpleDetailRow('Durasi Kerja', durasi),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Get.back(),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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

  Widget _buildSimpleDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
      ],
    );
  }
}
