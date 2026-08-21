import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../service/api_service.dart';
import '../controllers/order_controller.dart';

class EmployeeSelectionWidget extends StatefulWidget {
  final OrderController orderController;
  final VoidCallback? onEmployeeSelected;
  final VoidCallback? onCodeVerified;

  const EmployeeSelectionWidget({
    Key? key,
    required this.orderController,
    this.onEmployeeSelected,
    this.onCodeVerified,
  }) : super(key: key);

  @override
  State<EmployeeSelectionWidget> createState() =>
      _EmployeeSelectionWidgetState();
}

class _EmployeeSelectionWidgetState extends State<EmployeeSelectionWidget> {
  List<User> _karyawan = [];
  bool _loading = false;
  String? _error;
  User? _selectedEmployee;
  final TextEditingController _codeController = TextEditingController();
  bool _isCodeVerified = false;
  bool _isVerifyingCode = false;
  String? _codeError;

  @override
  void initState() {
    super.initState();
    _fetchKaryawan();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _fetchKaryawan() async {
    debugPrint('🚀 Starting _fetchKaryawan...');
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      debugPrint('📞 Calling api.fetchKaryawan()...');
      final data = await api.fetchKaryawan();
      debugPrint('✅ Received ${data.length} karyawan from API');

      setState(() {
        _karyawan = data.where((user) => user.isActive == 1).toList();
      });
    } catch (e) {
      debugPrint('❌ Error in _fetchKaryawan: $e');
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _selectEmployee(User employee) {
    setState(() {
      _selectedEmployee = employee;
      _isCodeVerified = false;
      _codeController.clear();
      _codeError = null;
    });

    widget.orderController.setSelectedUserId(employee.id);
    widget.orderController.setSelectedUserName(employee.name);
    widget.orderController.setEmployeeCodeVerified(false);

    // Show code verification dialog
    _showCodeVerificationDialog(employee);

    if (widget.onEmployeeSelected != null) {
      widget.onEmployeeSelected!();
    }
  }

  void _showCodeVerificationDialog(User employee) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.security, color: KtColor.violet700, size: 24),
              const SizedBox(width: 8),
              const Text('Verifikasi Kode'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan kode untuk ${employee.name}:',
                style: TextStyle(
                  fontSize: 14,
                  color: KtColor.neutral600,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  hintText: 'Masukkan kode (4 digit)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  counterText: '', // Hide character counter
                ),
                onSubmitted: (_) => _verifyCodeFromDialog(context),
                onChanged: (value) {
                  // Auto-submit when 4 digits are entered
                  if (value.length == 4) {
                    _verifyCodeFromDialog(context);
                  }
                },
              ),
              if (_codeError != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: KtColor.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: KtColor.danger.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: KtColor.dangerText, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _codeError!,
                          style: TextStyle(
                            color: KtColor.dangerText,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _selectedEmployee = null;
                  _codeError = null;
                });
                widget.orderController.setSelectedUserId(null);
                widget.orderController.setSelectedUserName(null);
                widget.orderController.setEmployeeCodeVerified(false);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: _isVerifyingCode
                  ? null
                  : () => _verifyCodeFromDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: KtColor.primary,
                foregroundColor: KtColor.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isVerifyingCode
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(KtColor.surface),
                      ),
                    )
                  : const Text('Verifikasi'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _verifyCodeFromDialog(BuildContext dialogContext) async {
    if (_selectedEmployee == null || _codeController.text.isEmpty) {
      setState(() {
        _codeError = 'Masukkan kode terlebih dahulu';
      });
      return;
    }

    if (_codeController.text.length != 4) {
      setState(() {
        _codeError = 'Kode harus terdiri dari 4 digit angka';
      });
      return;
    }

    setState(() {
      _isVerifyingCode = true;
      _codeError = null;
    });

    // Simulate verification delay for better UX
    await Future.delayed(const Duration(milliseconds: 500));

    if (_codeController.text == _selectedEmployee!.code) {
      setState(() {
        _isCodeVerified = true;
        _codeError = null;
      });

      widget.orderController.setEmployeeCodeVerified(true);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: KtColor.surface),
              const SizedBox(width: 8),
              Text(
                  'Kode berhasil diverifikasi untuk ${_selectedEmployee!.name}'),
            ],
          ),
          backgroundColor: KtColor.successText,
          duration: const Duration(seconds: 2),
        ),
      );

      // Close dialog
      Navigator.of(dialogContext).pop();

      if (widget.onCodeVerified != null) {
        widget.onCodeVerified!();
      }
    } else {
      setState(() {
        _isCodeVerified = false;
        _codeError = 'Kode tidak valid. Silakan coba lagi.';
      });

      widget.orderController.setEmployeeCodeVerified(false);
    }

    setState(() {
      _isVerifyingCode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const SizedBox(height: 12),

        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_error != null)
          _buildErrorWidget()
        else if (_karyawan.isEmpty)
          _buildEmptyWidget()
        else
          _buildEmployeeSelection(),

        // Show verification status if employee is selected and verified
        if (_selectedEmployee != null && _isCodeVerified) ...[
          const SizedBox(height: 16),
          _buildVerificationStatus(),
        ],
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KtColor.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KtColor.danger.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: KtColor.dangerText, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gagal memuat data karyawan',
                  style: TextStyle(
                    color: KtColor.dangerText,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: KtColor.dangerText, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _fetchKaryawan,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: KtColor.danger.withValues(alpha: 0.12),
              foregroundColor: KtColor.dangerText,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KtColor.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KtColor.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.warning_outlined, color: KtColor.warningText, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tidak ada karyawan aktif',
                  style: TextStyle(
                    color: KtColor.warningText,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada data karyawan aktif yang ditemukan.',
            style: TextStyle(color: KtColor.warningText, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KtColor.neutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KtColor.neutral300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih karyawan yang bertanggung jawab:',
            style: TextStyle(
              fontSize: 14,
              color: KtColor.neutral600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Employee List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _karyawan.length,
            itemBuilder: (context, index) {
              final employee = _karyawan[index];
              final isSelected = _selectedEmployee?.id == employee.id;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => _selectEmployee(employee),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? KtColor.violet100 : KtColor.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected ? KtColor.violet500 : KtColor.neutral300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: KtColor.neutral400.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? KtColor.violet100
                                : KtColor.neutral200,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            Icons.person,
                            color: isSelected
                                ? KtColor.violet700
                                : KtColor.neutral500,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                employee.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? KtColor.violet700
                                      : KtColor.neutral800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${employee.id}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected
                                      ? KtColor.violet700
                                      : KtColor.neutral500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: KtColor.violet100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.check_circle,
                              color: KtColor.violet700,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KtColor.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KtColor.success.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: KtColor.successText, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Kode berhasil diverifikasi untuk ${_selectedEmployee!.name}',
              style: TextStyle(
                color: KtColor.successText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
