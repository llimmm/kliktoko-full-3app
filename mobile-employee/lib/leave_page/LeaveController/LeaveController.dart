import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kliktoko/APIService/ApiService.dart';
import 'package:kliktoko/theme/app_theme.dart';

/// Pengajuan dan riwayat cuti.
///
/// Endpoint /api/leave/* sudah lama terdaftar tapi metodenya tidak pernah
/// ditulis, jadi selalu membalas 500 dan layarnya tidak pernah dibuat.
/// Keduanya kini hidup.
class LeaveController extends GetxController {
  final ApiService _apiService = ApiService();

  final RxList<Map<String, dynamic>> riwayat = <Map<String, dynamic>>[].obs;
  final RxBool sedangMemuat = false.obs;
  final RxBool sedangMengirim = false.obs;
  final RxnInt sisaCuti = RxnInt();
  final RxString pesanError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    muatRiwayat();
  }

  Future<void> muatRiwayat() async {
    sedangMemuat.value = true;
    pesanError.value = '';

    try {
      final hasil = await _apiService.getLeaveData();

      sisaCuti.value = hasil['sisa_cuti'] is int
          ? hasil['sisa_cuti'] as int
          : int.tryParse('${hasil['sisa_cuti']}');

      riwayat.value = (hasil['data'] as List)
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      pesanError.value = 'Gagal memuat riwayat cuti';
    } finally {
      sedangMemuat.value = false;
    }
  }

  /// Mengirim pengajuan untuk satu tanggal.
  ///
  /// Status tidak pernah dikirim dari sini — server yang menetapkannya
  /// 'pending'. Mengirimnya dari klien akan diabaikan backend, dan memang
  /// begitu seharusnya: karyawan tidak boleh menyetujui cutinya sendiri.
  Future<bool> ajukanCuti({required DateTime tanggal, String? alasan}) async {
    sedangMengirim.value = true;

    try {
      await _apiService.requestLeave({
        'date':
            '${tanggal.year.toString().padLeft(4, '0')}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}',
        if (alasan != null && alasan.trim().isNotEmpty) 'reason': alasan.trim(),
      });

      await muatRiwayat();

      Get.snackbar(
        'Berhasil',
        'Pengajuan cuti sudah dikirim dan menunggu persetujuan',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.successText,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      // Backend menolak dengan 400 bila tanggalnya sudah pernah diajukan.
      final pesan = e.toString().contains('400')
          ? 'Anda sudah mengajukan cuti untuk tanggal itu'
          : 'Pengajuan gagal dikirim. Coba lagi.';

      Get.snackbar(
        'Gagal',
        pesan,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.dangerText,
        colorText: Colors.white,
      );
      return false;
    } finally {
      sedangMengirim.value = false;
    }
  }
}
