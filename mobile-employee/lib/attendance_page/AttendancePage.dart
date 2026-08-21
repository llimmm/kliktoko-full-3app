import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kliktoko/attendance_page/AttendanceController.dart';
import 'package:kliktoko/camera_page/AttendanceCameraPage.dart';
import 'package:intl/intl.dart';
import 'package:kliktoko/attendance_page/ShiftModel.dart';
import 'package:kliktoko/theme/app_theme.dart';
import 'package:kliktoko/theme/kt_components.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Inisialisasi controller
    if (!Get.isRegistered<AttendanceController>()) {
      Get.put(AttendanceController());
    }
    final controller = Get.find<AttendanceController>();

    // Load user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.attendanceController.loadUserData();
    });

    // Responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: GetX<AttendanceController>(
          builder: (ctrl) => ctrl.isLoading.value
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
                  ),
                )
              : _buildContent(context, screenWidth, screenHeight, ctrl),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, double screenWidth,
      double screenHeight, AttendanceController controller) {
    return RefreshIndicator(
        onRefresh: () async {
          // Refresh radius location check first
          await controller.refreshLocation();

          // Then refresh other data
          await controller.checkAttendanceStatus();
          controller.attendanceController.loadUserData();
          controller.attendanceController.determineShift();
          await controller.attendanceController.loadAttendanceHistory();
        },
        color: AppTheme.primaryPurple,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top,
          ),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            child: Padding(
              padding: EdgeInsets.fromLTRB(screenWidth * 0.04,
                  screenHeight * 0.04, screenWidth * 0.04, screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAttendanceStatusCard(
                      screenWidth, screenHeight, controller),
                  SizedBox(height: screenHeight * 0.025),
                  _buildShiftInfoCard(screenWidth, screenHeight, controller),
                  SizedBox(height: screenHeight * 0.025),
                  SizedBox(height: screenHeight * 0.04),
                  _buildCheckInOutButton(controller),
                  SizedBox(height: screenHeight * 0.010),
                ],
              ),
            ),
          ),
        ));
  }

  // Header with profile info
  // Widget _buildHeader(double screenWidth, AttendanceController controller) {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     children: [
  //       Expanded(
  //         child: Row(
  //           children: [
  //             CircleAvatar(
  //               radius: 20,
  //               backgroundColor: Colors.grey[300],
  //               backgroundImage: const AssetImage('assets/profile_pic.jpg'),
  //             ),
  //             SizedBox(width: screenWidth * 0.03),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Obx(() => Text(
  //                         controller.username.value.isNotEmpty
  //                             ? controller.username.value
  //                             : 'User',
  //                         style: const TextStyle(
  //                             fontWeight: FontWeight.bold, fontSize: 14),
  //                         overflow: TextOverflow.ellipsis,
  //                       )),
  //                   Obx(() {
  //                     final isOutsideShiftHours = controller
  //                         .attendanceController.isOutsideShiftHours.value;
  //                     final shiftStatus =
  //                         controller.attendanceController.shiftStatus.value;
  //                     return Row(
  //                       children: [
  //                         Flexible(
  //                           child: Text(
  //                             isOutsideShiftHours || !shiftStatus.isActive
  //                                 ? 'Selamat Beristirahat'
  //                                 : 'Selamat Datang Kembali',
  //                             style: const TextStyle(
  //                                 fontSize: 16, fontWeight: FontWeight.w500),
  //                             overflow: TextOverflow.ellipsis,
  //                           ),
  //                         ),
  //                         const SizedBox(width: 4),
  //                         Icon(
  //                             isOutsideShiftHours || !shiftStatus.isActive
  //                                 ? Icons.nightlight_round
  //                                 : Icons.waving_hand,
  //                             color:
  //                                 isOutsideShiftHours || !shiftStatus.isActive
  //                                     ? Colors.indigo
  //                                     : Colors.amber,
  //                             size: 18)
  //                       ],
  //                     );
  //                   }),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //       const Icon(Icons.notifications_outlined, color: Colors.red),
  //     ],
  //   );
  // }

  // Card showing attendance status
  Widget _buildAttendanceStatusCard(double screenWidth, double screenHeight,
      AttendanceController controller) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status Kehadiran',
              style: TextStyle(fontSize: 14, color: AppTheme.secondaryText)),
          const SizedBox(height: 11.5),

          // Radius Status Display
          // Penanda jangkauan.
          //
          // Dulu isian tint 10% dengan teks berwarna. "Di luar jangkauan" —
          // justru keadaan yang paling penting terbaca, karena itulah yang
          // menjelaskan kenapa karyawan tidak bisa absen — hanya mencapai
          // 4,13:1. Blok pekat berteks hitam: 14,96:1 di dalam jangkauan dan
          // 11,06:1 di luar.
          Obx(() {
            final di = controller.isWithinRadius.value;
            return Container(
              margin: const EdgeInsets.only(bottom: KtSpace.md),
              child: KtBlock(
                fill: di ? KtBlockColor.aman : KtBlockColor.habis,
                padding: const EdgeInsets.symmetric(
                    horizontal: KtSpace.sm, vertical: KtSpace.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      di ? Icons.location_on : Icons.location_off,
                      color: KtColor.black,
                      size: 14,
                    ),
                    const SizedBox(width: KtSpace.xs),
                    Flexible(
                      child: Text(
                        controller.locationStatus.value,
                        style: KtType.label.copyWith(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() {
                      // Loading indicator
                      if (controller.isLoading.value) {
                        return Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryPurple),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Memeriksa status...',
                              style: TextStyle(
                                  fontSize: 18, color: AppTheme.secondaryText),
                            ),
                          ],
                        );
                      }

                      // Status text and color based on shift status
                      String statusText;
                      Color? statusColor;

                      final status =
                          controller.attendanceController.shiftStatus.value;

                      // Varian teks, bukan varian isian. Sebagai teks di atas
                      // kartu putih, warningColor #D97706 hanya 3,19:1 dan
                      // infoColor #0284C7 hanya 4,10:1 — keduanya lolos hanya
                      // karena kebetulan ukurannya besar. warningText dan
                      // varian gelapnya lolos tanpa bergantung ukuran huruf.
                      if (status.isActive) {
                        if (status.data?.checkOut != null) {
                          statusText = 'Anda Sudah Check-out';
                          statusColor = KtColor.infoText;
                        } else if (status.data?.isLate ?? false) {
                          statusText = 'Anda Terlambat';
                          statusColor = KtColor.warningText;
                        } else {
                          statusText = 'Anda Sedang Aktif';
                          statusColor = KtColor.primary;
                        }
                      } else {
                        // Gunakan pesan dari API atau pesan default
                        if (status.message.isNotEmpty) {
                          statusText = status.message;
                          statusColor = AppTheme.secondaryText;
                        } else {
                          statusText = 'Tidak Ada Shift Saat Ini';
                          statusColor = AppTheme.secondaryText;
                        }
                      }

                      return Text(
                        statusText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: statusColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      );
                    }),
                    SizedBox(height: screenHeight * 0.005),

                    SizedBox(height: screenHeight * 0.005),

                    // Date
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 14, color: AppTheme.secondaryText),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                                .format(DateTime.now()),
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.secondaryText),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card showing shift info
  Widget _buildShiftInfoCard(double screenWidth, double screenHeight,
      AttendanceController controller) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jadwal Shift:',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: screenHeight * 0.015),
          Obx(() {
            final shiftMap = controller.attendanceController.shiftMap.value;
            final shiftStatus =
                controller.attendanceController.shiftStatus.value;

            // Cari shift yang aktif dari API
            ShiftModel? activeShift;
            for (final shift in shiftMap.values) {
              if (shift.isCurrentTimeInShift()) {
                activeShift = shift;
                break;
              }
            }

            // Jika tidak ada shift aktif dari API, cek shiftStatus sebagai fallback
            if (activeShift == null) {
              bool hasActiveShiftFromMessage =
                  shiftStatus.message.contains('belum absen di shift') &&
                      !shiftStatus.message.contains('tidak ada shift');

              if (hasActiveShiftFromMessage) {
                // Extract shift number from message
                final shiftMatch =
                    RegExp(r'shift (\d+)').firstMatch(shiftStatus.message);
                if (shiftMatch != null) {
                  final shiftNumber = shiftMatch.group(1);
                  // Find shift from shiftMap
                  for (final shift in shiftMap.values) {
                    if (shift.id.toString() == shiftNumber) {
                      activeShift = shift;
                      break;
                    }
                  }
                }
              }
            }

            if (shiftMap.isNotEmpty) {
              final shiftList = shiftMap.values.toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tampilkan semua shift yang tersedia
                  ...shiftList.map((shift) {
                    final formattedTime = shift.getFormattedTimeRange();
                    final isActive = activeShift?.id == shift.id;

                    // Shift yang sedang berjalan terangkat; yang lain rata.
                    // Dulu bedanya hanya rona isian dan tebal border 1 vs 2 —
                    // perbedaan yang harus dicari untuk terlihat. Sekarang
                    // yang aktif punya bayangan dan yang lain tidak.
                    return Container(
                      margin: const EdgeInsets.only(bottom: KtSpace.sm),
                      padding: const EdgeInsets.all(KtSpace.md),
                      decoration: KtBrutal.surface(
                        background:
                            isActive ? KtColor.violet100 : KtColor.neutral50,
                        radius: KtRadius.sm,
                        raised: isActive,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              // neutral400 hanya 2,46:1 terhadap latar baris —
                              // di bawah ambang grafis 3:1, jadi sebagai
                              // penanda ia praktis tidak ada. neutral600
                              // mencapai 7,41:1.
                              color: isActive
                                  ? KtColor.primary
                                  : KtColor.neutral600,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shift.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isActive
                                        ? AppTheme.primaryPurple
                                        : AppTheme.primaryText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formattedTime,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isActive
                                        ? AppTheme.primaryPurple
                                        : AppTheme.secondaryText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isActive)
                            // Ungu berteks putih (5,70:1) — satu-satunya isian
                            // berwarna yang tidak memakai teks hitam, karena
                            // ungu terhadap hitam cuma 3,69:1.
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: KtSpace.sm,
                                  vertical: KtSpace.xs),
                              decoration: KtBrutal.block(KtColor.primary),
                              child: Text(
                                'AKTIF',
                                style: KtType.label.copyWith(
                                  fontSize: 10,
                                  color: KtColor.neutral0,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),

                  // Tampilkan status dari API jika ada
                  // Kotak peringatan.
                  //
                  // Sebelumnya teks #D97706 di atas tint 10% warnanya sendiri:
                  // 2,86:1 — yang terburuk di berkas ini, dan angka yang sama
                  // persis dengan chip "menipis" yang gagal di layar gudang.
                  // Pola tint ini memang tidak pernah bisa lolos.
                  if (shiftStatus.message.isNotEmpty && activeShift == null)
                    Container(
                      margin: const EdgeInsets.only(top: KtSpace.sm),
                      child: KtBlock(
                        fill: KtBlockColor.menipis, // 15,93:1 thd hitam
                        child: Text(
                          shiftStatus.message,
                          style: KtType.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: KtColor.black,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            } else {
              // Keadaan memuat. craft-floor menuntut keadaan ini dibangun
              // dengan isi sungguhan, bukan dibiarkan jadi ruang kosong yang
              // tidak menjelaskan apa-apa.
              return Container(
                padding: const EdgeInsets.all(KtSpace.lg),
                decoration: KtBrutal.surface(
                  background: KtColor.neutral50,
                  radius: KtRadius.sm,
                  raised: false,
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(KtColor.primary),
                      ),
                    ),
                    const SizedBox(width: KtSpace.sm),
                    Text('Memuat jadwal shift...', style: KtType.caption),
                  ],
                ),
              );
            }
          }),
        ],
      ),
    );
  }

  // Improved Check-in/Check-out button
  Widget _buildCheckInOutButton(AttendanceController controller) {
    return Obx(() {
      final bool isCheckedIn = controller.hasCheckedIn.value;
      final bool isCheckedOut = controller.hasCheckedOut.value;
      final bool isLoading = controller.isLoading.value;
      final shiftStatus = controller.attendanceController.shiftStatus.value;
      final shiftMap = controller.attendanceController.shiftMap.value;

      // Debug logging
      print('🔍 Button Debug:');
      print('   - isCheckedIn: $isCheckedIn');
      print('   - isCheckedOut: $isCheckedOut');
      print('   - isLoading: $isLoading');
      print('   - shiftStatus.isActive: ${shiftStatus.isActive}');
      print('   - shiftStatus.message: ${shiftStatus.message}');
      print('   - shiftStatus.data?.checkIn: ${shiftStatus.data?.checkIn}');
      print('   - shiftStatus.data?.checkOut: ${shiftStatus.data?.checkOut}');
      print('   - shiftMap.length: ${shiftMap.length}');

      // Loading state
      if (isLoading) {
        return _buildButton(
          onPressed: null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(KtColor.neutral600),
                ),
              ),
              const SizedBox(width: 10),
              const Text('Memproses...',
                  style: TextStyle(
                      color: KtColor.neutral600,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
        );
      }

      // Cek apakah ada shift yang aktif berdasarkan data dari API /api/shifts
      bool hasActiveShift = false;
      String activeShiftName = '';
      String selectedShiftId = '';

      // Loop melalui semua shift dari API untuk mencari yang aktif
      for (final shift in shiftMap.values) {
        if (shift.isCurrentTimeInShift()) {
          hasActiveShift = true;
          activeShiftName = shift.name;
          selectedShiftId = shift.id.toString();
          print('✅ Found active shift: ${shift.name} (ID: ${shift.id})');
          break;
        }
      }

      // Jika tidak ada shift aktif dari API, cek shiftStatus sebagai fallback
      if (!hasActiveShift) {
        hasActiveShift = shiftStatus.isActive;
        print('⚠️ Using shiftStatus.isActive as fallback: $hasActiveShift');
      }

      // Cek apakah ada pesan yang menunjukkan shift aktif (seperti "Anda belum absen di shift X")
      bool hasActiveShiftFromMessage =
          shiftStatus.message.contains('belum absen di shift') &&
              !shiftStatus.message.contains('tidak ada shift');

      // Jika tidak ada shift aktif dari API tapi ada pesan shift aktif, gunakan itu
      if (!hasActiveShift && hasActiveShiftFromMessage) {
        hasActiveShift = true;
        // Extract shift number from message
        final shiftMatch =
            RegExp(r'shift (\d+)').firstMatch(shiftStatus.message);
        if (shiftMatch != null) {
          final shiftNumber = shiftMatch.group(1);
          selectedShiftId = shiftNumber!;
          // Find shift name from shiftMap
          for (final shift in shiftMap.values) {
            if (shift.id.toString() == shiftNumber) {
              activeShiftName = shift.name;
              break;
            }
          }
        }
        print('✅ Using shift from message: ${shiftStatus.message}');
      }

      // Update selectedShift outside of Obx to avoid setState during build
      if (selectedShiftId.isNotEmpty &&
          selectedShiftId != controller.selectedShift.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.selectedShift.value = selectedShiftId;
        });
      }

      print('🔍 Final hasActiveShift: $hasActiveShift');
      print('🔍 Active shift name: $activeShiftName');
      print('🔍 Selected shift ID: $selectedShiftId');

      // No active shift available
      if (!hasActiveShift) {
        return _buildButton(
          onPressed: null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.schedule, color: KtColor.neutral600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  shiftStatus.message.isNotEmpty
                      ? shiftStatus.message
                      : 'Tidak Ada Shift Saat Ini',
                  style: const TextStyle(
                      color: KtColor.neutral600,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      }

      // Check if user is outside radius - button should be grey
      if (!controller.isWithinRadius.value) {
        return _buildButton(
          onPressed: null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, color: KtColor.neutral600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Anda berada di luar jangkauan kantor',
                  style: const TextStyle(
                      color: KtColor.neutral600,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      }

      // Check if user has already completed attendance for today (both check-in and check-out)
      if (isCheckedIn && isCheckedOut) {
        print('🔍 User has completed attendance for today');
        return _buildButton(
          onPressed: null,
          child: const Text('Anda Sudah Selesai Absen Hari Ini',
              style: TextStyle(
                  color: KtColor.neutral600,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        );
      }

      // Check if user has checked out (from shiftStatus data)
      if (shiftStatus.data?.checkOut != null) {
        print('🔍 User has checked out');
        return _buildButton(
          onPressed: null,
          child: const Text('Anda Sudah Check-out',
              style: TextStyle(
                  color: KtColor.neutral600,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        );
      }

      // Checked in but not checked out - show checkout button
      if (isCheckedIn && !isCheckedOut) {
        print(
            '🔍 User is checked in but not checked out - showing checkout button');
        return _buildButton(
          // Mengakhiri shift itu tindakan harian yang normal, bukan kesalahan.
          // Merah dicadangkan untuk error; memakainya di sini membuat karyawan
          // ragu menekan tombol yang memang harus ditekan tiap hari.
          color: KtColor.primary,
          onPressed: () => controller.showCheckOutConfirmation(),
          child: const Text('Check-out',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
        );
      }

      // Check if user has already checked in today
      if (isCheckedIn) {
        print('🔍 User has already checked in today');
        return _buildButton(
          onPressed: null,
          child: const Text('Sudah Absen Hari Ini',
              style: TextStyle(
                  color: KtColor.neutral600,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        );
      }

      // Not checked in - show check-in button with photo
      print('🔍 User not checked in - showing check-in button');
      return _buildButton(
        // Hijau #16A34A dengan teks putih hanya 3,30:1 — dan ini tombol
        // terpenting di seluruh app. Ungu 5,70:1. Yang menandai "berhasil"
        // adalah tulisan dan ikonnya, bukan rona latarnya.
        color: KtColor.primary,
        onPressed: () async {
          // Verify attendance status before attempting check-in
          await controller.checkAttendanceStatus();

          if (controller.hasCheckedIn.value) {
            Get.snackbar(
              'Sudah Absen',
              'Anda sudah absen hari ini',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppTheme.lightPurple,
              colorText: AppTheme.primaryText,
            );
            return;
          }

          // Navigate to camera page for check-in with photo
          final result = await Get.to(
            () => AttendanceCameraPage(
                shiftId: selectedShiftId.isNotEmpty
                    ? selectedShiftId
                    : controller.selectedShift.value),
          );

          // Refresh attendance status if check-in was successful
          if (result == true) {
            await controller.checkAttendanceStatus();
            await controller.loadAttendanceHistory();
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Absen ${activeShiftName.isNotEmpty ? activeShiftName : 'dengan Foto'}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ],
        ),
      );
    });
  }

  /// Kartu layar ini.
  ///
  /// Dulu berkas ini menyusun kartunya sendiri — radius 16, bayangan blur 6
  /// pada abu 10%, border abu 1px — sementara sembilan berkas lain menyusun
  /// versinya masing-masing dengan angka berbeda. Sekarang satu sumber.
  Widget _buildCard({required Widget child}) => KtCard(child: child);

  /// Tombol layar ini.
  ///
  /// Tinggi 50 diganti 48: `impeccable/android.md` menetapkan 48dp sebagai
  /// minimum, dan angka bulat itu satu-satunya yang dipakai di seluruh app.
  /// `color` boleh null, dan untuk tombol nonaktif memang HARUS null.
  ///
  /// Sebelumnya tiap keadaan menimpa latarnya sendiri dengan abu #A1A1AA lalu
  /// menulis teks putih di atasnya: 2,56:1. Warna nonaktif bawaan KtBrutal
  /// (neutral200 dengan teks neutral600, 6,09:1) tidak pernah sempat berlaku
  /// karena selalu ditimpa.
  Widget _buildButton(
      {Color? color,
      required VoidCallback? onPressed,
      required Widget child}) {
    final gaya = color == null
        ? KtBrutal.action()
        : KtBrutal.action()
            .copyWith(backgroundColor: WidgetStatePropertyAll(color));
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: gaya,
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}
