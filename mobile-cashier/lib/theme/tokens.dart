// KlikToko design tokens — neobrutalism.
//
// Kembaran tokens.css. Kalau mengubah nilai di sini, ubah juga di sana.
// Salin file ini ke lib/theme/tokens.dart di mobile-cashier dan mobile-employee.
//
// Gayanya satu, dijalani sepenuhnya: border hitam tebal, bayangan keras tanpa
// blur, tipografi tebal, dan blok warna pekat. Tidak ada mode "lembut" yang
// berdampingan — permukaan setengah-brutal terbaca sebagai kesalahan, bukan
// pilihan.
//
// Warna DIJATAH: satu blok warna per layar, dipakai untuk hal terpenting di
// layar itu. Sisanya putih, hitam, dan garis. Struktur boleh berteriak di mana
// saja; warna tidak.

import 'package:flutter/material.dart';

class KtColor {
  KtColor._();

  // Aksen tunggal
  static const violet50 = Color(0xFFF5F3FF);
  static const violet100 = Color(0xFFEDE9FE);
  static const violet200 = Color(0xFFDDD6FE);
  static const violet500 = Color(0xFF8B5CF6);
  static const violet600 = Color(0xFF7C3AED);
  static const violet700 = Color(0xFF6D28D9);

  // Tangga netral: putih ke hitam
  static const neutral0 = Color(0xFFFFFFFF);
  static const neutral50 = Color(0xFFFAFAFA);
  static const neutral100 = Color(0xFFF4F4F5);
  static const neutral200 = Color(0xFFE4E4E7);
  static const neutral300 = Color(0xFFD4D4D8);
  static const neutral400 = Color(0xFFA1A1AA);
  static const neutral500 = Color(0xFF71717A);
  static const neutral600 = Color(0xFF52525B);
  static const neutral700 = Color(0xFF3F3F46);
  static const neutral800 = Color(0xFF27272A);
  static const neutral900 = Color(0xFF18181B);
  static const black = Color(0xFF000000);

  // Status stok — sengaja bukan ungu; ini data, bukan identitas merek.
  // Dipakai untuk teks berwarna dan ikon garis, BUKAN sebagai isian blok:
  // sebagai isian, keluarga di KtBlockColor jauh lebih terbaca.
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);
  static const info = Color(0xFF0284C7);

  // Varian gelap: teks berwarna di atas putih, dan latar yang memaksa teks
  // putih (SnackBar). Di sana success hanya 3,3:1 dan warning 3,2:1 — di bawah
  // ambang. Yang ini semuanya >= 5:1 terhadap putih. Jangan tukar-tukar.
  static const successText = Color(0xFF15803D);
  static const warningText = Color(0xFFB45309);
  static const dangerText = Color(0xFFB91C1C);
  // info #0284C7 hanya 4,10:1 di atas putih — lolos hanya karena kebetulan
  // dipakai pada huruf besar. Yang ini 5,93:1, dan sama dengan --info di
  // tokens.css supaya kedua codebase tidak menyimpang.
  static const infoText = Color(0xFF0369A1);

  // Peran
  static const primary = violet600;
  static const primaryHover = violet700;
  static const surface = neutral0;
  static const background = violet50;
  static const border = black;
  static const textPrimary = neutral900;
  static const textSecondary = neutral600;
}

/// Keluarga blok neobrutal.
///
/// SELALU dengan teks hitam dan border hitam. Angka di sebelah tiap nilai
/// adalah rasio kontras terhadap teks hitam — semuanya jauh di atas ambang
/// 4,5:1, dan itu bukan kebetulan: pola sebelumnya (isian tint dari warna
/// teksnya sendiri) tidak pernah lolos 4,5:1 pada alpha berapa pun.
///
/// Terhadap PUTIH nilai-nilai ini hanya 1,3-1,9:1. Teks putih di atas blok
/// warna tidak pernah boleh.
///
/// Terhadap latar halaman (#F5F3FF) juga hanya 1,2-1,9:1 — sebagai bentuk,
/// blok warna nyaris tidak punya tepi sendiri. Border hitam di 19,15:1 adalah
/// satu-satunya yang membuatnya ada. Border di sini menanggung beban, bukan
/// hiasan; mencabutnya mencabut strukturnya.
class KtBlockColor {
  KtBlockColor._();

  static const yellow = Color(0xFFFDE047); // 15,93:1 thd hitam
  static const mint = Color(0xFF86EFAC); //   14,96:1
  static const lime = Color(0xFFA3E635); //   13,93:1
  static const sky = Color(0xFF7DD3FC); //    12,60:1
  static const orange = Color(0xFFFDBA74); // 12,45:1
  static const coral = Color(0xFFFCA5A5); //  11,06:1

  /// Blok mati: keadaan nonaktif dan baris yang sudah lewat.
  static const muted = KtColor.neutral200; // 16,55:1 thd hitam

  // Pemetaan makna. Dipakai lewat nama ini, bukan lewat nama warnanya, supaya
  // "stok habis" bisa berganti rona tanpa menyisir seluruh kode.
  static const aman = mint;
  static const menipis = yellow;
  static const habis = coral;
  static const catatan = sky;
}

/// Skala radius. Hanya dua nilai.
///
/// Neobrutalism menahan radius tetap kecil: sudut yang terlalu bulat melunakkan
/// border tebalnya dan mengembalikan kesan kartu lembut yang justru dibuang.
/// Catatan soal ungu, karena tempatnya paling sering dicari: ungu BUKAN anggota
/// KtBlockColor. Terhadap teks hitam ia hanya 3,69:1 — gagal; terhadap teks
/// putih 5,70:1 — lulus. Jadi ungu adalah isian teks-putih untuk aksi utama,
/// persis kebalikan dari keluarga blok.
class KtRadius {
  KtRadius._();

  /// Chip, tombol, kolom isian, blok kecil.
  static const sm = 8.0;

  /// Kartu dan panel.
  static const md = 12.0;
}

/// Skala jarak. Kelipatan 4, supaya tidak ada lagi angka acak seperti 13 atau 18.
class KtSpace {
  KtSpace._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Tipografi.
///
/// Huruf sistem adalah salah satu ciri tampilan hasil AI yang generik, dan
/// karakter neobrutalism sebagian besar datang dari beratnya huruf. Kalau
/// berkas fontnya belum terpasang, Flutter jatuh ke huruf bawaan tanpa error —
/// tampilannya menjadi netral, bukan rusak.
class KtType {
  KtType._();

  static const String family = 'PlusJakartaSans';

  /// Angka besar dan judul layar. Rapat, karena huruf tebal butuh ruang lebih
  /// sedikit di antara hurufnya, bukan lebih banyak.
  static const TextStyle display = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w800,
    fontSize: 32,
    letterSpacing: -0.8,
    height: 1.1,
    color: KtColor.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w800,
    fontSize: 20,
    letterSpacing: -0.3,
    color: KtColor.textPrimary,
  );

  static const TextStyle section = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w800,
    fontSize: 16,
    letterSpacing: -0.2,
    color: KtColor.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1.45,
    color: KtColor.textPrimary,
  );

  /// Keterangan kecil. neutral600 (#52525B), bukan neutral400 — yang terakhir
  /// hanya 2,56:1 di atas putih dan tidak boleh membawa kata sama sekali.
  static const TextStyle caption = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 1.4,
    color: KtColor.textSecondary,
  );

  /// Label di dalam blok warna. Huruf besar dan renggang — satu-satunya tempat
  /// letter-spacing positif dipakai.
  static const TextStyle label = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w700,
    fontSize: 12,
    letterSpacing: 0.4,
    color: KtColor.black,
  );

  static const TextStyle button = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w700,
    fontSize: 15,
    letterSpacing: 0.2,
  );
}

/// Neobrutalism: border hitam tebal, bayangan keras, target sentuh besar.
///
/// Ini bukan mode khusus lagi. Sampai commit sebelumnya `KtBold` hanya dipakai
/// di zona uang app kasir sementara sisanya memakai kartu putih berbayang
/// lembut — dan hasilnya justru tidak terbaca sebagai rancangan apa pun. Kartu
/// putih #FFFFFF di atas latar #F5F3FF hanya berbeda 1,10:1; tepinya ditopang
/// sepenuhnya oleh bayangan hitam 8% dengan blur 12px, yaitu sesuatu di ambang
/// terlihat. Border hitam 3px menaruh tepi yang sama di 19,15:1.
class KtBrutal {
  KtBrutal._();

  static const double borderWidth = 3;

  /// Bayangan bergeser tanpa blur. Angka 4 dipertahankan karena sudah dipakai
  /// di `.u-bold-surface` pada tokens.css dan keduanya harus sepakat.
  static const Offset shadowOffset = Offset(4, 4);

  /// impeccable/android.md: 48x48dp minimum, jarak antar target >= 8dp.
  static const double minTapTarget = 48;

  /// Zona uang di kasir dipakai cepat dan salah pencet berarti salah uang.
  static const double minTapTargetMoney = 56;

  static const List<BoxShadow> shadow = [
    BoxShadow(color: KtColor.black, offset: shadowOffset, blurRadius: 0),
  ];

  /// Saat ditekan: permukaan bergeser ke tempat bayangannya dan bayangannya
  /// hilang, jadi tombolnya terasa benar-benar tertekan ke bawah.
  static const List<BoxShadow> shadowPressed = [];

  static Border get outline =>
      Border.all(color: KtColor.black, width: borderWidth);

  /// Permukaan putih: kartu, panel, baris daftar.
  static BoxDecoration surface({
    Color background = KtColor.surface,
    double radius = KtRadius.md,
    bool raised = true,
  }) {
    return BoxDecoration(
      color: background,
      border: outline,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: raised ? shadow : shadowPressed,
    );
  }

  /// Blok warna: penanda keadaan, angka yang ditonjolkan, chip.
  /// Isinya wajib teks hitam — lihat catatan di KtBlockColor.
  static BoxDecoration block(
    Color fill, {
    double radius = KtRadius.sm,
    bool raised = false,
  }) {
    return BoxDecoration(
      color: fill,
      border: outline,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: raised ? shadow : shadowPressed,
    );
  }

  /// Aksi utama: ungu dengan teks putih (5,70:1).
  ///
  /// Nonaktif memakai neutral600 di atas neutral200 = 6,09:1. Sebelumnya
  /// neutral500 dipakai di sini dan hanya mencapai 3,81:1 — di bawah ambang —
  /// dan di `KtButton` app employee bahkan neutral400, yang cuma 2,02:1:
  /// labelnya praktis tidak terlihat sama sekali saat tombolnya mati.
  static ButtonStyle action({double minHeight = minTapTarget}) {
    return ElevatedButton.styleFrom(
      backgroundColor: KtColor.primary,
      foregroundColor: KtColor.neutral0,
      disabledBackgroundColor: KtColor.neutral200,
      disabledForegroundColor: KtColor.neutral600,
      minimumSize: Size(0, minHeight),
      elevation: 0,
      shadowColor: Colors.transparent,
      textStyle: KtType.button,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KtRadius.sm),
        side: const BorderSide(color: KtColor.black, width: borderWidth),
      ),
    );
  }

  /// Aksi sekunder: putih dengan teks hitam. Bentuknya sama persis dengan aksi
  /// utama — yang membedakan hanya isian, bukan bobot bordernya.
  static ButtonStyle neutralAction({double minHeight = minTapTarget}) {
    return ElevatedButton.styleFrom(
      backgroundColor: KtColor.surface,
      foregroundColor: KtColor.black,
      disabledBackgroundColor: KtColor.neutral200,
      disabledForegroundColor: KtColor.neutral600,
      minimumSize: Size(0, minHeight),
      elevation: 0,
      shadowColor: Colors.transparent,
      textStyle: KtType.button,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KtRadius.sm),
        side: const BorderSide(color: KtColor.black, width: borderWidth),
      ),
    );
  }
}

/// Nama lama, dipertahankan supaya tiga layar kasir yang memakainya tetap
/// terbangun sampai Fase E menyapunya. Jangan dipakai di kode baru.
@Deprecated('Pakai KtBrutal')
class KtBold {
  KtBold._();

  static const double minTapTarget = KtBrutal.minTapTargetMoney;

  static BoxDecoration surface({Color background = KtColor.surface}) =>
      KtBrutal.surface(background: background, radius: KtRadius.sm);

  static ButtonStyle action() =>
      KtBrutal.action(minHeight: KtBrutal.minTapTargetMoney);
}

/// Tema dasar. Warnanya ditarik ke hitam dan bordernya ditebalkan di satu
/// tempat, supaya widget Material bawaan tidak menyelundupkan sudut membulat
/// dan elevasi lembutnya sendiri ke dalam layar.
ThemeData ktTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: KtColor.primary,
    primary: KtColor.primary,
    surface: KtColor.surface,
    onSurface: KtColor.textPrimary,
  );

  const brutalBorder =
      BorderSide(color: KtColor.black, width: KtBrutal.borderWidth);

  return ThemeData(
    useMaterial3: true,
    fontFamily: KtType.family,
    colorScheme: scheme,
    scaffoldBackgroundColor: KtColor.background,
    dividerColor: KtColor.black,
    dividerTheme: const DividerThemeData(
      color: KtColor.black,
      thickness: 2,
      space: 2,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: KtColor.background,
      foregroundColor: KtColor.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: KtType.title,
    ),
    cardTheme: CardTheme(
      color: KtColor.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KtRadius.md),
        side: brutalBorder,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: KtBrutal.action()),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: KtColor.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: KtSpace.md,
        vertical: KtSpace.md,
      ),
      hintStyle: KtType.body.copyWith(color: KtColor.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KtRadius.sm),
        borderSide: brutalBorder,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KtRadius.sm),
        borderSide: brutalBorder,
      ),
      // Fokus tidak boleh hanya berganti rona. Bordernya sudah setebal 3px di
      // semua keadaan, jadi yang berubah adalah warnanya ke ungu — bentuknya
      // tetap, sehingga tidak ada pergeseran tata letak saat kolom difokus.
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KtRadius.sm),
        borderSide: const BorderSide(
          color: KtColor.primary,
          width: KtBrutal.borderWidth,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KtRadius.sm),
        borderSide: const BorderSide(
          color: KtColor.dangerText,
          width: KtBrutal.borderWidth,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KtRadius.sm),
        borderSide: const BorderSide(
          color: KtColor.dangerText,
          width: KtBrutal.borderWidth,
        ),
      ),
    ),
  );
}
