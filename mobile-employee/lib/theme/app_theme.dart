import 'package:flutter/material.dart';

import 'tokens.dart';

export 'tokens.dart';

/// Fasad di atas `tokens.dart`.
///
/// Ada 420-an rujukan `AppTheme.*` yang tersebar di 16.767 baris app ini.
/// Mengganti namanya sekaligus berarti satu commit raksasa yang tidak bisa
/// diperiksa; membiarkannya menyalin nilai dengan tangan berarti palet ini
/// menyimpang lagi seperti sebelumnya — CLAUDE.md menyatakan `tokens.dart`
/// disalin ke kedua app Flutter, padahal app ini tidak pernah punya salinannya
/// dan nilainya dicocokkan manual.
///
/// Jadi: nama lama dipertahankan, nilainya ditarik dari `KtColor`. Tiap layar
/// yang disapu di Fase B menukar `AppTheme.x` dengan `KtColor.x` di tempat, dan
/// berkas ini menyusut sendiri.
class AppTheme {
  AppTheme._();

  // ---- Ungu ----
  static const Color primaryPurple = KtColor.violet600;
  static const Color lightPurple = KtColor.violet100;
  static const Color lightPurpleBackground = KtColor.violet50;
  static const Color darkPurple = KtColor.violet700;
  static const Color darkerPurple = Color(0xFF5B21B6);
  static const Color accentPurple = KtColor.violet500;
  static const Color lightAccentPurple = KtColor.violet200;

  // ---- Latar ----
  /// Satu tanah untuk seluruh app. Sebelumnya #FAFAFA di sini dan #F5F3FF di
  /// `lightPurpleBackground`, jadi layar bertetangga berdiri di atas dua latar
  /// yang berbeda 1,05:1 — perbedaan yang tidak pernah terbaca sebagai maksud,
  /// hanya sebagai ketidakrapian.
  static const Color backgroundColor = KtColor.violet50;
  static const Color cardBackground = KtColor.surface;
  static const Color darkCardBackground = KtColor.neutral900;

  // ---- Teks ----
  static const Color primaryText = KtColor.neutral900;

  /// Naik dari #71717A ke #52525B. Yang lama lulus di atas putih (4,83:1) tapi
  /// gagal di atas latar halaman #F5F3FF (4,41:1) — dan 70 pemakaiannya
  /// tersebar di kedua latar tanpa pola. Yang baru 7,05:1 di atas latar ungu.
  static const Color secondaryText = KtColor.neutral600;

  /// JANGAN dipakai untuk teks: 2,56:1 di atas putih, 2,33:1 di atas latar
  /// ungu. Hanya untuk ikon dekoratif. Masih ada 22 pemakaian yang disisir
  /// per layar di Fase B — tidak disapu sekaligus, karena sebagian adalah ikon
  /// yang memang boleh pudar dan sebagian membawa kata.
  @Deprecated('Untuk teks pakai secondaryText; untuk garis pakai KtBrutal.outline')
  static const Color lightText = KtColor.neutral400;

  static const Color strongText = KtColor.neutral600;

  // ---- Status ----
  static const Color successColor = KtColor.success;
  static const Color warningColor = KtColor.warning;
  static const Color errorColor = KtColor.danger;
  static const Color infoColor = KtColor.info;

  static const Color successText = KtColor.successText;
  static const Color warningText = KtColor.warningText;
  static const Color dangerText = KtColor.dangerText;

  // ---- Garis dan bayangan ----
  /// Border neobrutal itu hitam pekat 3px, bukan abu 1px. Nilai ini dibiarkan
  /// abu karena 24 pemakaiannya bukan semuanya border — ada yang isian dan
  /// pembatas. Untuk border baru pakai `KtBrutal.outline`.
  static const Color borderColor = KtColor.neutral200;
  static const Color lightBorderColor = KtColor.neutral100;
  static const Color shadowColor = KtColor.black;

  /// Gradien bertentangan dengan gaya ini: neobrutalism memakai bidang warna
  /// rata dengan tepi tegas. Satu pemakaian tersisa di `start.dart:175`,
  /// dicabut saat layar itu disapu.
  @Deprecated('Neobrutalism memakai bidang rata; pakai KtColor.primary')
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [KtColor.violet600, KtColor.violet500],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme => ktTheme();
}
