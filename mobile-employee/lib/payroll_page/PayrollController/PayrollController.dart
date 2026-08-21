import 'package:get/get.dart';
import 'package:kliktoko/APIService/ApiService.dart';

/// Riwayat slip gaji.
///
/// Tabel `payrolls` sudah ada sejak awal lengkap dengan komponen gaji, tapi
/// tidak pernah punya controller maupun rute di backend — jadi slip gaji tidak
/// mungkin ditampilkan di mana pun. Keduanya dibuat di Fase 2.
class PayrollController extends GetxController {
  final ApiService _apiService = ApiService();

  final RxList<Map<String, dynamic>> slip = <Map<String, dynamic>>[].obs;
  final RxBool sedangMemuat = false.obs;
  final RxString pesanError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    muatSlip();
  }

  Future<void> muatSlip() async {
    sedangMemuat.value = true;
    pesanError.value = '';

    try {
      slip.value = await _apiService.getPayrollHistory();
    } catch (e) {
      pesanError.value = 'Gagal memuat slip gaji';
    } finally {
      sedangMemuat.value = false;
    }
  }

  /// Nilai uang dari API bisa datang sebagai int, double, atau String.
  static double angka(dynamic nilai) {
    if (nilai is num) return nilai.toDouble();
    return double.tryParse('$nilai') ?? 0;
  }

  /// "Rp 2.600.000" — pemisah ribuan titik, gaya Indonesia.
  ///
  /// Backend sudah mengirim total_salary_formatted, tapi komponen lain
  /// (pokok, lembur, potongan) dikirim sebagai angka mentah supaya app bebas
  /// menampilkannya. Ini formatter untuk yang mentah itu.
  static String rupiah(dynamic nilai) {
    final bulat = angka(nilai).round();
    final teks = bulat.abs().toString();
    final buf = StringBuffer();

    for (var i = 0; i < teks.length; i++) {
      if (i > 0 && (teks.length - i) % 3 == 0) buf.write('.');
      buf.write(teks[i]);
    }

    return '${bulat < 0 ? '-' : ''}Rp ${buf.toString()}';
  }
}
