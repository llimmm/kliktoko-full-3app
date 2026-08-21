import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kliktoko/login_page/LoginController/LoginController.dart';
import 'package:kliktoko/login_page/Loginpage/LoginBottomSheet.dart';
import 'package:kliktoko/theme/app_theme.dart';
import 'package:kliktoko/theme/kt_components.dart';

/// Layar pembuka.
///
/// Dulu seluruh tampilannya berasal dari tiga PNG (`ssstart.png`,
/// `kliktokos.png`, `ayomulai.png`) yang membawa palet lama gelap-hijau-limau.
/// Warnanya ada di dalam berkas gambar, jadi tidak bisa ikut disapu bersama
/// warna lain — satu-satunya cara menyelaraskannya adalah membangun layar ini
/// dari token. Sekalian menghapus 1,4 MB aset dan membuat layar ini ikut
/// berubah otomatis kalau palet berubah.
///
/// Gerakan geser-untuk-mulai dipertahankan apa adanya: itu bagian yang memang
/// bekerja dengan baik.
class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage>
    with SingleTickerProviderStateMixin {
  double _dragValue = 0.0;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isBottomSheetShowing = false;

  static const double _thumbSize = 52;
  static const double _trackHeight = 62;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 270),
      value: 0.0,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _animation.addListener(() {
      setState(() => _dragValue = _animation.value);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double _trackWidth(BuildContext context) =>
      MediaQuery.of(context).size.width * 0.8;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      final dragDistance = _trackWidth(context) - _thumbSize - 10;
      _dragValue += details.primaryDelta! / dragDistance;
      _dragValue = _dragValue.clamp(0.0, 1.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    HapticFeedback.mediumImpact();

    if (_dragValue > 0.5 || velocity > 600) {
      _animationController.value = _dragValue;
      _animationController.animateTo(1.0).then((_) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!mounted) return;
          _showLoginBottomSheet(context);
          _animationController.value = 0.0;
          setState(() => _dragValue = 0.0);
        });
      });
    } else {
      _animationController.value = _dragValue;
      _animationController.animateTo(0.0);
    }
  }

  void _showLoginBottomSheet(BuildContext context) {
    if (_isBottomSheetShowing) return;
    _isBottomSheetShowing = true;

    if (!Get.isRegistered<LoginController>()) {
      Get.put(LoginController());
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      enableDrag: true,
      builder: (context) => const LoginBottomSheet(),
    ).then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _isBottomSheetShowing = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppTheme.lightPurpleBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                // Spacer di bawah memakai Expanded, yang butuh tinggi terbatas.
                // Di dalam SingleChildScrollView tinggi Column tidak terbatas,
                // sehingga tanpa IntrinsicHeight layar ini gagal layout dan
                // tampil kosong sama sekali.
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: KtSpace.xl, vertical: KtSpace.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(flex: 2),
                        _buildHero(),
                        const SizedBox(height: KtSpace.xxl),
                        _buildWordmark(),
                        const Spacer(flex: 3),
                        Center(child: _buildSlider(context)),
                        const SizedBox(height: KtSpace.lg),
                        const Center(
                          child: Text(
                            'Geser untuk masuk',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.secondaryText,
                            ),
                          ),
                        ),
                        const SizedBox(height: KtSpace.xl),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Panel ungu dengan ikon toko — menggantikan ilustrasi hijau yang dulu
  /// datang sebagai PNG 92 KB.
  Widget _buildHero() {
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(48),
          boxShadow: ktCardShadow,
        ),
        child: const Icon(
          Icons.storefront_outlined,
          size: 92,
          color: Colors.white,
        ),
      ),
    );
  }

  /// "KlikToko" sebagai teks, bukan gambar: ikut palet, tajam di segala
  /// kerapatan layar, dan tidak menambah berat APK.
  Widget _buildWordmark() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Klik',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryText,
                  letterSpacing: -1,
                ),
              ),
              TextSpan(
                text: 'Toko',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryPurple,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: KtSpace.xs),
        const Text(
          'Untuk karyawan',
          style: TextStyle(fontSize: 15, color: AppTheme.secondaryText),
        ),
      ],
    );
  }

  Widget _buildSlider(BuildContext context) {
    final trackWidth = _trackWidth(context);
    final travel = trackWidth - _thumbSize - 10;

    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Container(
        width: trackWidth,
        height: _trackHeight,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(_trackHeight / 2),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: ktCardShadow,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Label memudar saat digeser, supaya tidak bertumpuk dengan thumb.
            Opacity(
              opacity: (1 - _dragValue * 1.6).clamp(0.0, 1.0),
              child: const Text(
                'Ayo mulai',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.secondaryText,
                ),
              ),
            ),
            // Isian yang tumbuh mengikuti geseran.
            Positioned(
              left: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutQuart,
                width: (_thumbSize + 10) + travel * _dragValue,
                height: _trackHeight,
                decoration: BoxDecoration(
                  color: AppTheme.lightPurple,
                  borderRadius: BorderRadius.circular(_trackHeight / 2),
                ),
              ),
            ),
            Positioned(
              left: 5 + travel * _dragValue,
              child: Container(
                alignment: Alignment.center,
                width: _thumbSize,
                height: _thumbSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryPurple,
                  boxShadow: ktCardShadow,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
