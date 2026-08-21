import 'package:flutter/material.dart';

import 'tokens.dart';

/// Komponen bersama app employee, neobrutalism.
///
/// Aturannya sederhana: kalau sebuah pola muncul di lebih dari satu layar,
/// tempatnya di sini — bukan disalin.
///
/// Sampai commit sebelumnya aturan itu ditulis tapi tidak dijalankan. Berkas
/// ini hanya menjangkau empat berkas (LeavePage, PayrollPage, start.dart,
/// LoginBottomSheet) sementara sisa app menyusun 107 `BoxDecoration`, 36
/// `BoxShadow`, dan 120 `borderRadius` sendiri-sendiri. Itu sebab app-nya tidak
/// terlihat dirancang: tidak ada satu bahasa visual yang sampai ke beranda,
/// absensi, dan gudang — layar yang justru dibuka tiap hari.

/// Nama lama untuk radius. `KtRadius` di tokens.dart adalah sumbernya.
///
/// Nilainya mengetat: kontrol 12 -> 8, permukaan 16 -> 12. Sudut yang terlalu
/// bulat melunakkan border tebal dan mengembalikan kesan kartu lembut yang
/// justru dibuang.
@Deprecated('Pakai KtRadius')
class KtRadii {
  KtRadii._();

  static const double control = KtRadius.sm;
  static const double surface = KtRadius.md;
}

/// Bayangan tunggal untuk seluruh permukaan yang terangkat.
///
/// Dulu blur 12px pada hitam 8%. Kartu putih di atas latar #F5F3FF hanya
/// berbeda 1,10:1, jadi tepi kartu ditopang sepenuhnya oleh bayangan itu —
/// sesuatu di ambang terlihat. Sekarang bergeser 4px tanpa blur, dan tepinya
/// dipikul border hitam di 19,15:1.
const List<BoxShadow> ktCardShadow = KtBrutal.shadow;

/// Permukaan putih: kartu, panel, baris daftar.
class KtCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;

  /// Baris yang sudah lewat atau tidak aktif: rata dengan halaman, tanpa
  /// bayangan. Bordernya tetap — yang hilang hanya ketinggiannya.
  final bool raised;

  const KtCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(KtSpace.lg),
    this.margin,
    this.color,
    this.onTap,
    this.raised = true,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: KtBrutal.surface(
        background: color ?? KtColor.surface,
        raised: raised,
      ),
      child: child,
    );

    if (onTap == null) return Container(margin: margin, child: card);

    return Container(
      margin: margin,
      child: KtPressable(onTap: onTap!, child: card),
    );
  }
}

/// Blok warna: penanda keadaan, angka yang ditonjolkan, label.
///
/// Isinya selalu teks hitam. Lihat `KtBlockColor` untuk alasannya — singkatnya,
/// keluarga ini 11-16:1 terhadap hitam tapi hanya 1,3-1,9:1 terhadap putih.
class KtBlock extends StatelessWidget {
  final Widget child;
  final Color fill;
  final EdgeInsetsGeometry padding;
  final bool raised;
  final double radius;

  const KtBlock({
    super.key,
    required this.child,
    required this.fill,
    this.padding = const EdgeInsets.all(KtSpace.md),
    this.raised = false,
    this.radius = KtRadius.sm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: KtBrutal.block(fill, radius: radius, raised: raised),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: KtColor.black),
        child: child,
      ),
    );
  }
}

/// Permukaan yang benar-benar tertekan saat disentuh: bergeser 4px ke tempat
/// bayangannya, lalu bayangannya hilang.
///
/// Ini bukan hiasan. Neobrutalism membuang ripple dan elevasi Material, jadi
/// tanpa ini sebuah kartu yang bisa diketuk tidak memberi umpan balik apa pun.
class KtPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const KtPressable({super.key, required this.child, required this.onTap});

  @override
  State<KtPressable> createState() => _KtPressableState();
}

class _KtPressableState extends State<KtPressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          _down ? KtBrutal.shadowOffset.dx : 0,
          _down ? KtBrutal.shadowOffset.dy : 0,
          0,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Judul bagian, dengan aksi opsional di kanan.
class KtSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const KtSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    // craft-floor: ruang di atas judul lebih lega daripada di bawahnya, supaya
    // judul menempel pada isinya sendiri dan bukan mengambang di antara dua
    // bagian yang berjarak sama.
    return Padding(
      padding: const EdgeInsets.only(top: KtSpace.xl, bottom: KtSpace.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: KtType.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: KtColor.primary,
                // android.md: target sentuh 48x48dp.
                minimumSize: const Size(0, KtBrutal.minTapTarget),
                padding: const EdgeInsets.symmetric(horizontal: KtSpace.sm),
                textStyle: KtType.button.copyWith(fontSize: 13),
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

enum KtButtonKind { primary, secondary, ghost }

/// Tombol dengan tiga peran tetap.
///
/// Merah tidak disediakan: dalam app ini merah berarti stok habis atau keadaan
/// gagal, bukan sekadar tombol yang terasa berbahaya. Keluar dari sesi atau
/// membatalkan adalah tindakan rutin — pakai `secondary`.
class KtButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final KtButtonKind kind;
  final IconData? icon;
  final bool expand;

  const KtButton({
    super.key,
    required this.label,
    this.onPressed,
    this.kind = KtButtonKind.primary,
    this.icon,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: KtSpace.sm),
        ],
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );

    switch (kind) {
      case KtButtonKind.primary:
        return ElevatedButton(
          onPressed: onPressed,
          style: KtBrutal.action(),
          child: child,
        );
      case KtButtonKind.secondary:
        return ElevatedButton(
          onPressed: onPressed,
          style: KtBrutal.neutralAction(),
          child: child,
        );
      case KtButtonKind.ghost:
        // Satu-satunya kontrol tanpa border. Dipakai untuk aksi tersier yang
        // tidak boleh bersaing dengan dua di atasnya.
        return TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: KtColor.primary,
            disabledForegroundColor: KtColor.neutral600,
            minimumSize: const Size(0, KtBrutal.minTapTarget),
            textStyle: KtType.button,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(KtRadius.sm),
            ),
          ),
          child: child,
        );
    }
  }
}

/// Peran warna untuk penanda keadaan.
enum KtStatus { neutral, success, warning, danger, info }

/// Chip keadaan: cuti disetujui, stok menipis, terlambat.
///
/// **Pengecualian sadar terhadap penjatahan warna.** Aturan umumnya satu blok
/// warna per layar, tapi chip keadaan adalah data — menyatukan seluruh status
/// ke satu rona menghapus justru keterangan yang jadi alasan chip itu ada.
/// Penjatahan berlaku untuk warna struktural dan dekoratif; chip keadaan
/// dikecualikan, dan hanya chip keadaan.
///
/// Isiannya blok pekat dengan teks hitam, bukan tint dari warna teksnya
/// sendiri. Pola tint itu terlihat rapi tapi tidak pernah lolos 4,5:1 pada
/// alpha berapa pun: hijau 4,27:1, kuning 4,25:1, dan di atas baris berlatar
/// ungu turun sampai 3,91:1. Bahkan pada alpha 0,05 hanya mencapai 4,28:1.
/// Blok pekat memutus ketergantungan itu sepenuhnya — yang terburuk di keluarga
/// ini 11,06:1.
class KtStatusChip extends StatelessWidget {
  final String label;
  final KtStatus status;
  final IconData? icon;

  const KtStatusChip({
    super.key,
    required this.label,
    this.status = KtStatus.neutral,
    this.icon,
  });

  Color get _fill {
    switch (status) {
      case KtStatus.success:
        return KtBlockColor.aman; //     14,96:1 thd hitam
      case KtStatus.warning:
        return KtBlockColor.menipis; //  15,93:1
      case KtStatus.danger:
        return KtBlockColor.habis; //    11,06:1
      case KtStatus.info:
        return KtBlockColor.catatan; //  12,60:1
      case KtStatus.neutral:
        return KtBlockColor.muted; //    16,55:1
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KtSpace.sm,
        vertical: KtSpace.xs + 2,
      ),
      decoration: KtBrutal.block(_fill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: KtColor.black),
            const SizedBox(width: KtSpace.xs + 2),
          ],
          // Chip dipakai untuk label pendek, tapi kalau suatu saat diberi teks
          // panjang ia harus memotong, bukan meluber keluar kartu.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KtType.label,
            ),
          ),
        ],
      ),
    );
  }
}

/// Keadaan kosong yang menjelaskan, bukan sekadar ruang kosong.
class KtEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;

  const KtEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KtSpace.xl,
        vertical: KtSpace.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ikon dalam kotak berborder, bukan ikon pudar mengambang: keadaan
          // kosong tetap harus terlihat seperti bagian dari app yang sama.
          Container(
            padding: const EdgeInsets.all(KtSpace.lg),
            decoration: KtBrutal.block(KtBlockColor.muted),
            child: Icon(icon, size: 32, color: KtColor.black),
          ),
          const SizedBox(height: KtSpace.lg),
          Text(title, textAlign: TextAlign.center, style: KtType.section),
          if (description != null) ...[
            const SizedBox(height: KtSpace.xs),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: KtType.caption,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: KtSpace.lg),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Kerangka layar: latar seragam, judul, dan ruang bawah untuk navigasi
/// mengambang yang menutupi konten kalau tidak diberi kelonggaran.
class KtScreen extends StatelessWidget {
  final String? title;
  final Widget child;
  final List<Widget>? actions;
  final bool scrollable;

  /// Navigasi bawah mengambang setinggi ~90px; tanpa ruang ini baris terakhir
  /// tiap daftar tertutup dan tidak pernah bisa dibaca sampai habis.
  static const double bottomNavClearance = 110;

  const KtScreen({
    super.key,
    this.title,
    required this.child,
    this.actions,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(
        KtSpace.lg,
        KtSpace.lg,
        KtSpace.lg,
        bottomNavClearance,
      ),
      child: child,
    );

    return Scaffold(
      backgroundColor: KtColor.background,
      appBar: title == null
          ? null
          : AppBar(
              backgroundColor: KtColor.background,
              foregroundColor: KtColor.textPrimary,
              elevation: 0,
              scrolledUnderElevation: 0,
              titleTextStyle: KtType.title,
              title: Text(title!),
              actions: actions,
            ),
      body: SafeArea(
        child: scrollable ? SingleChildScrollView(child: body) : body,
      ),
    );
  }
}
