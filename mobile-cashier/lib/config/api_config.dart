/// Satu-satunya tempat alamat backend ditulis.
///
/// Sebelumnya alamat produksi `https://adminkliktoko.my.id` di-hardcode di
/// enam tempat (tiga di main.dart, tiga di ApiService) — padahal server itu
/// belum pernah di-deploy. Akibatnya kasir tidak bisa diarahkan ke backend
/// lokal tanpa menyunting enam baris, dan pasti ada yang terlewat.
///
/// Ganti target tanpa menyentuh kode:
///   flutter run --dart-define=KLIKTOKO_API=http://192.168.1.10:8000
///
/// Bawaannya 10.0.2.2 — alamat "localhost milik host" dari emulator Android,
/// sama dengan app employee supaya keduanya berperilaku serupa.
///
/// Untuk tablet fisik lewat kabel USB, pasangkan `adb reverse` dengan
/// localhost — tidak bergantung Wi-Fi sekamar maupun firewall:
///   adb reverse tcp:8000 tcp:8000
///   flutter run --dart-define=KLIKTOKO_API=http://localhost:8000
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'KLIKTOKO_API',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const String imageBaseUrl = '$baseUrl/storage/';
}
