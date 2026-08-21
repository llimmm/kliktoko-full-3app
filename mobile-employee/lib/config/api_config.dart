/// Satu-satunya tempat alamat backend ditulis.
///
/// Sebelumnya `baseUrl` di-hardcode di enam file terpisah (ApiService,
/// AttendanceApiService, SharedAttendanceController, GudangController,
/// CategoryService, SizeService), semuanya menunjuk ke server produksi yang
/// belum pernah di-deploy — sehingga app tidak bisa dipakai ke backend lokal
/// tanpa menyunting enam tempat dan pasti ada yang terlewat.
///
/// Ganti target tanpa menyentuh kode:
///   flutter run --dart-define=KLIKTOKO_API=http://192.168.1.10:8000
///
/// Bawaannya 10.0.2.2 — itu alamat "localhost milik host" dari emulator
/// Android. Untuk perangkat fisik, pakai IP LAN komputer Anda.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'KLIKTOKO_API',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const String imageBaseUrl = '$baseUrl/storage/';
}
