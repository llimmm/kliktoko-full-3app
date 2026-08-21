import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kliktoko/leave_page/LeaveController/LeaveController.dart';
import 'package:kliktoko/theme/app_theme.dart';
import 'package:kliktoko/theme/kt_components.dart';

/// Layar pengajuan cuti.
///
/// Seluruh permukaannya memakai komponen bersama dari kt_components.dart,
/// jadi kalau palet atau radius berubah, layar ini ikut tanpa disentuh.
class LeavePage extends StatelessWidget {
  const LeavePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LeaveController());

    return KtScreen(
      title: 'Pengajuan Cuti',
      child: Obx(() {
        if (controller.sedangMemuat.value && controller.riwayat.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: KtSpace.xxl),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kartuKuota(controller),
            const SizedBox(height: KtSpace.lg),
            KtButton(
              label: 'Ajukan cuti',
              icon: Icons.add,
              onPressed: () => _bukaFormPengajuan(context, controller),
            ),
            const KtSectionHeader(title: 'Riwayat'),
            if (controller.riwayat.isEmpty)
              const KtEmptyState(
                icon: Icons.event_available_outlined,
                title: 'Belum ada pengajuan cuti',
                description:
                    'Pengajuan yang Anda kirim akan muncul di sini beserta statusnya.',
              )
            else
              ...controller.riwayat.map(_kartuCuti),
          ],
        );
      }),
    );
  }

  Widget _kartuKuota(LeaveController controller) {
    final sisa = controller.sisaCuti.value;

    return KtCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.lightPurple,
              borderRadius: BorderRadius.circular(KtRadii.control),
            ),
            child: const Icon(Icons.beach_access_outlined,
                color: AppTheme.primaryPurple),
          ),
          const SizedBox(width: KtSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sisa cuti bulan ini',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.secondaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  // Angkanya dihitung server, bukan di sini — aturan kuota
                  // hanya boleh hidup di satu tempat.
                  sisa == null ? '—' : '$sisa hari',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kartuCuti(Map<String, dynamic> cuti) {
    final status = (cuti['status'] ?? '').toString();

    // Warna status: kuning menunggu, hijau disetujui, merah ditolak. Ketiganya
    // memakai varian teks gelap yang lolos kontras di atas isian mudanya.
    final peran = switch (status) {
      'approved' => KtStatus.success,
      'rejected' => KtStatus.danger,
      _ => KtStatus.warning,
    };

    final ikon = switch (status) {
      'approved' => Icons.check_circle_outline,
      'rejected' => Icons.cancel_outlined,
      _ => Icons.schedule,
    };

    final alasan = (cuti['reason'] ?? '').toString();

    return KtCard(
      margin: const EdgeInsets.only(bottom: KtSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  // 'tanggal' sudah diformat dd-mm-yyyy oleh backend.
                  (cuti['tanggal'] ?? cuti['date'] ?? '-').toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryText,
                  ),
                ),
              ),
              KtStatusChip(
                label: (cuti['status_label'] ?? status).toString(),
                status: peran,
                icon: ikon,
              ),
            ],
          ),
          if (alasan.isNotEmpty) ...[
            const SizedBox(height: KtSpace.sm),
            Text(
              alasan,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.secondaryText,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _bukaFormPengajuan(BuildContext context, LeaveController controller) {
    DateTime? dipilih;
    final alasanCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(KtRadii.surface)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: KtSpace.xl,
                right: KtSpace.xl,
                top: KtSpace.xl,
                // Tanpa ini form tertutup keyboard saat mengetik alasan.
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + KtSpace.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ajukan cuti',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: KtSpace.xs),
                  const Text(
                    'Satu pengajuan untuk satu tanggal.',
                    style: TextStyle(fontSize: 13, color: AppTheme.secondaryText),
                  ),
                  const SizedBox(height: KtSpace.lg),
                  InkWell(
                    onTap: () async {
                      final sekarang = DateTime.now();
                      final hasil = await showDatePicker(
                        context: sheetContext,
                        initialDate: dipilih ?? sekarang,
                        firstDate: sekarang.subtract(const Duration(days: 30)),
                        lastDate: sekarang.add(const Duration(days: 365)),
                      );
                      if (hasil != null) {
                        setSheetState(() => dipilih = hasil);
                      }
                    },
                    borderRadius: BorderRadius.circular(KtRadii.control),
                    child: Container(
                      padding: const EdgeInsets.all(KtSpace.lg),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(KtRadii.control),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 18, color: AppTheme.primaryPurple),
                          const SizedBox(width: KtSpace.md),
                          Text(
                            dipilih == null
                                ? 'Pilih tanggal'
                                : '${dipilih!.day.toString().padLeft(2, '0')}-${dipilih!.month.toString().padLeft(2, '0')}-${dipilih!.year}',
                            style: TextStyle(
                              fontSize: 15,
                              color: dipilih == null
                                  ? AppTheme.secondaryText
                                  : AppTheme.primaryText,
                              fontWeight: dipilih == null
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: KtSpace.md),
                  TextField(
                    controller: alasanCtrl,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Alasan (opsional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(KtRadii.control),
                      ),
                    ),
                  ),
                  const SizedBox(height: KtSpace.sm),
                  Obx(() => KtButton(
                        label: controller.sedangMengirim.value
                            ? 'Mengirim…'
                            : 'Kirim pengajuan',
                        // Tombol mati sampai tanggal dipilih: tanpa tanggal
                        // backend membalas 422 dan kasir hanya melihat error.
                        onPressed: (dipilih == null ||
                                controller.sedangMengirim.value)
                            ? null
                            : () async {
                                final berhasil = await controller.ajukanCuti(
                                  tanggal: dipilih!,
                                  alasan: alasanCtrl.text,
                                );
                                if (berhasil && sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                              },
                      )),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
