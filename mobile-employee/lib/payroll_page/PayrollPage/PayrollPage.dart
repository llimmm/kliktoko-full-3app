import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kliktoko/payroll_page/PayrollController/PayrollController.dart';
import 'package:kliktoko/theme/app_theme.dart';
import 'package:kliktoko/theme/kt_components.dart';

/// Daftar slip gaji per periode.
class PayrollPage extends StatelessWidget {
  const PayrollPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PayrollController());

    return KtScreen(
      title: 'Slip Gaji',
      child: Obx(() {
        if (controller.sedangMemuat.value && controller.slip.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: KtSpace.xxl),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (controller.slip.isEmpty) {
          return const KtEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Belum ada slip gaji',
            description:
                'Slip gaji akan muncul di sini setelah admin menerbitkannya.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: controller.slip.map(_kartuSlip).toList(),
        );
      }),
    );
  }

  Widget _kartuSlip(Map<String, dynamic> slip) {
    final catatan = (slip['notes'] ?? '').toString();

    return KtCard(
      margin: const EdgeInsets.only(bottom: KtSpace.md),
      onTap: () => Get.to(() => PayrollDetailPage(slip: slip)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (slip['periode'] ?? slip['date'] ?? '-').toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${slip['total_hours'] ?? 0} jam kerja',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppTheme.lightText),
            ],
          ),
          const SizedBox(height: KtSpace.md),
          Text(
            // Backend sudah memformatnya; app tidak perlu mengulang aturannya.
            (slip['total_salary_formatted'] ??
                    PayrollController.rupiah(slip['total_salary']))
                .toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryPurple,
            ),
          ),
          if (catatan.isNotEmpty) ...[
            const SizedBox(height: KtSpace.sm),
            // Catatan slip adalah kalimat utuh, bukan label status. Chip
            // memaksanya satu baris dan membuatnya meluber keluar kartu.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    size: 14, color: AppTheme.warningText),
                const SizedBox(width: KtSpace.sm),
                Expanded(
                  child: Text(
                    catatan,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.warningText,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Rincian satu slip.
///
/// Datanya sudah lengkap di daftar, jadi tidak perlu memanggil
/// /api/payroll/{id} lagi hanya untuk membuka rincian.
class PayrollDetailPage extends StatelessWidget {
  final Map<String, dynamic> slip;

  const PayrollDetailPage({super.key, required this.slip});

  @override
  Widget build(BuildContext context) {
    final catatan = (slip['notes'] ?? '').toString();

    return KtScreen(
      title: (slip['periode'] ?? 'Slip Gaji').toString(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KtCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gaji dibawa pulang',
                  style: TextStyle(fontSize: 13, color: AppTheme.secondaryText),
                ),
                const SizedBox(height: KtSpace.xs),
                Text(
                  (slip['total_salary_formatted'] ??
                          PayrollController.rupiah(slip['total_salary']))
                      .toString(),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryPurple,
                  ),
                ),
              ],
            ),
          ),
          const KtSectionHeader(title: 'Rincian'),
          KtCard(
            child: Column(
              children: [
                _baris('Gaji pokok', slip['base_salary']),
                _baris('Lembur', slip['overtime_pay'], tambah: true),
                _baris('Bonus', slip['bonus'], tambah: true),
                // Potongan ditandai merah dan diberi tanda minus supaya tidak
                // terbaca sebagai tambahan seperti dua baris di atasnya.
                _baris('Potongan', slip['deductions'], kurang: true),
                const Divider(height: KtSpace.xl),
                _baris(
                  'Total',
                  slip['total_salary'],
                  tebal: true,
                  teksSiap: slip['total_salary_formatted']?.toString(),
                ),
              ],
            ),
          ),
          const KtSectionHeader(title: 'Lain-lain'),
          KtCard(
            child: Column(
              children: [
                _barisTeks('Periode', (slip['periode'] ?? '-').toString()),
                _barisTeks('Tanggal terbit', (slip['date'] ?? '-').toString()),
                _barisTeks('Jam kerja', '${slip['total_hours'] ?? 0} jam'),
                if (catatan.isNotEmpty) _barisTeks('Catatan', catatan),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _baris(
    String label,
    dynamic nilai, {
    bool tambah = false,
    bool kurang = false,
    bool tebal = false,
    String? teksSiap,
  }) {
    final angka = PayrollController.angka(nilai);
    final teks = teksSiap ?? PayrollController.rupiah(angka);

    final warna =
        kurang && angka > 0 ? AppTheme.dangerText : AppTheme.primaryText;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KtSpace.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: tebal ? 16 : 14,
              fontWeight: tebal ? FontWeight.w800 : FontWeight.normal,
              color: tebal ? AppTheme.primaryText : AppTheme.secondaryText,
            ),
          ),
          Text(
            '${kurang && angka > 0 ? '−' : (tambah && angka > 0 ? '+' : '')}$teks',
            style: TextStyle(
              fontSize: tebal ? 18 : 14,
              fontWeight: tebal ? FontWeight.w800 : FontWeight.w600,
              color: warna,
            ),
          ),
        ],
      ),
    );
  }

  Widget _barisTeks(String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KtSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.secondaryText),
            ),
          ),
          Expanded(
            child: Text(
              nilai,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
