import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'package:intl/intl.dart';
import '../controllers/order_controller.dart';
import '../widget/employee_selection_widget.dart';
import 'qris_payment_page.dart';

class PaymentConfirmationPage extends StatefulWidget {
  final OrderController orderController;

  const PaymentConfirmationPage({
    Key? key,
    required this.orderController,
  }) : super(key: key);

  @override
  State<PaymentConfirmationPage> createState() =>
      _PaymentConfirmationPageState();
}

class _PaymentConfirmationPageState extends State<PaymentConfirmationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Pembayaran'),
        backgroundColor: KtColor.violet700,
        foregroundColor: KtColor.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Receipt Section
            _buildReceiptSection(),
            const SizedBox(height: 24),

            // Employee Selection Section
            _buildEmployeeSection(),
            const SizedBox(height: 24),

            // Payment Method Section
            _buildPaymentMethodSection(),
            const SizedBox(height: 32),

            // Payment Button
            _buildPaymentButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.receipt_long, color: KtColor.violet700, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Struk Pembayaran',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Store Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KtColor.neutral100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'KASIR SIMOTO',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                    style: TextStyle(
                      color: KtColor.neutral500,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),

                  // Items List
                  const SizedBox(height: 12),
                  ...widget.orderController.items
                      .map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    item.displayName,
                                    style: const TextStyle(fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    '${item.quantity}x',
                                    style: const TextStyle(fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    NumberFormat.currency(
                                      locale: 'id',
                                      symbol: 'Rp ',
                                      decimalDigits: 0,
                                    ).format(
                                        item.product.price * item.quantity),
                                    style: const TextStyle(fontSize: 14),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),

                  const SizedBox(height: 12),
                  const Divider(),

                  // Total Summary
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal',
                        style: TextStyle(
                          fontSize: 14,
                          color: KtColor.neutral600,
                        ),
                      ),
                      Text(
                        NumberFormat.currency(
                          locale: 'id',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(widget.orderController.subtotal),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        NumberFormat.currency(
                          locale: 'id',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(widget.orderController.total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: KtColor.violet700, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Pilih Karyawan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            EmployeeSelectionWidget(
              orderController: widget.orderController,
              onEmployeeSelected: () {
                setState(() {});
              },
              onCodeVerified: () {
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: KtColor.violet700, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Metode Pembayaran',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: widget.orderController.selectedPaymentMethod,
              items: const [
                DropdownMenuItem(
                  value: 'cash',
                  child: Row(
                    children: [
                      Icon(Icons.money, color: KtColor.successText),
                      SizedBox(width: 8),
                      Text('Cash'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'transfer',
                  child: Row(
                    children: [
                      Icon(Icons.account_balance, color: KtColor.primary),
                      SizedBox(width: 8),
                      Text('Transfer'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'qris',
                  child: Row(
                    children: [
                      Icon(Icons.qr_code, color: KtColor.primary),
                      SizedBox(width: 8),
                      Text('QRIS'),
                    ],
                  ),
                ),
              ],
              onChanged: (val) {
                setState(() {
                  widget.orderController
                      .setSelectedPaymentMethod(val ?? 'cash');
                });
              },
              decoration: const InputDecoration(
                labelText: 'Pilih Metode Pembayaran',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: widget.orderController.items.isEmpty ||
                !widget.orderController.isEmployeeCodeVerified
            ? null
            : () async {
                debugPrint('🔘 Payment button clicked');
                debugPrint(
                    '📦 Items count: ${widget.orderController.items.length}');
                debugPrint(
                    '👤 Selected user ID: ${widget.orderController.selectedUserId}');
                debugPrint(
                    '🔐 Code verified: ${widget.orderController.isEmployeeCodeVerified}');

                // Check if payment method is QRIS
                if (widget.orderController.selectedPaymentMethod == 'qris') {
                  // Navigate to QRIS payment page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QrisPaymentPage(
                        orderController: widget.orderController,
                      ),
                    ),
                  );
                } else {
                  // Process payment directly for other methods
                  final success =
                      await widget.orderController.processPayment(context);

                  // Navigate back to home page after successful payment
                  if (mounted && success) {
                    // Clear the order and navigate back to home
                    widget.orderController.clearOrder();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                }
              },
        // Zona uang: bold, target sentuh 56px, ungu primer. Hijau di sini
        // membaca sebagai "sudah berhasil" padahal transaksinya belum jalan.
        style: KtBold.action().copyWith(
          backgroundColor: WidgetStatePropertyAll(
            widget.orderController.isEmployeeCodeVerified
                ? KtColor.primary
                : KtColor.neutral400,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!widget.orderController.isEmployeeCodeVerified)
              const Icon(Icons.lock, size: 20),
            const SizedBox(width: 8),
            Text(
              widget.orderController.isEmployeeCodeVerified
                  ? 'Proses Pembayaran'
                  : 'Verifikasi Kode Dulu',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
