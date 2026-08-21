import 'package:flutter/material.dart';
import 'package:kliktoko/theme/app_theme.dart';

class FormLaporanKerjaPage extends StatefulWidget {
  @override
  _FormLaporanKerjaPageState createState() => _FormLaporanKerjaPageState();
}

class _FormLaporanKerjaPageState extends State<FormLaporanKerjaPage> with TickerProviderStateMixin {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();
  DateTime? _tanggalDipilih;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: Duration(seconds: 1));
  }

  Future<void> _pilihTanggal(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _tanggalDipilih) {
      setState(() {
        _tanggalDipilih = picked;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _withShadow({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppTheme.borderColor,
            blurRadius: 4, // dikecilkan
            offset: Offset(0, 2), // dikecilkan
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppTheme.lightPurpleBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: AppTheme.primaryText),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    'Form Laporan Cuti',
                    style: TextStyle(color: AppTheme.primaryText),
                  ),
                  centerTitle: true,
                ),
                _withShadow(
                  child: Image.asset(
                    'assets/images/org.jpg',
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create cuti',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText,
                  ),
                ),
                _withShadow(
                  child: _buildInputField(
                    label: 'Masukan Nama',
                    controller: _namaController,
                    hintText: 'Masukkan nama',
                    icon: Icons.man,
                  ),
                ),
                _withShadow(
                  child: _buildInputField(
                    label: 'Masukkan keterangan',
                    controller: _keteranganController,
                    hintText: 'Masukkan keterangan',
                    icon: Icons.add_alert,
                  ),
                ),
                _withShadow(child: _buildDatePickerField()),
                const SizedBox(height: 16),
                _withShadow(
                  child: ElevatedButton(
                    onPressed: () {
                      final nama = _namaController.text;
                      final ket = _keteranganController.text;
                      final tanggal = _tanggalDipilih;

                      if (nama.isNotEmpty && ket.isNotEmpty && tanggal != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Data berhasil disubmit')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Harap lengkapi semua data')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      minimumSize: Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Send ',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _withShadow(
                  child: const Text.rich(
                    TextSpan(
                      text: 'By creating an account or signing you agree to our ',
                      children: [
                        TextSpan(
                          text: 'Terms and Conditions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    style: TextStyle(fontSize: 12, color: AppTheme.secondaryText),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    IconData? icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
        suffixIcon: isPassword ? Icon(Icons.visibility_off_outlined) : null,
        filled: true,
        fillColor: AppTheme.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
    );
  }

  Widget _buildDatePickerField() {
    return GestureDetector(
      onTap: () => _pilihTanggal(context),
      child: AbsorbPointer(
        child: TextField(
          decoration: InputDecoration(
            labelText: 'Tanggal',
            hintText: _tanggalDipilih == null
                ? 'Pilih tanggal'
                : '${_tanggalDipilih!.day}-${_tanggalDipilih!.month}-${_tanggalDipilih!.year}',
            prefixIcon: Icon(Icons.calendar_today),
            filled: true,
            fillColor: AppTheme.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          ),
        ),
      ),
    );
  }
}
