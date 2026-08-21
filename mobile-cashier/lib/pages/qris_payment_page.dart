import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'package:intl/intl.dart';
import '../controllers/order_controller.dart';

class QrisPaymentPage extends StatelessWidget {
  final OrderController orderController;

  const QrisPaymentPage({
    Key? key,
    required this.orderController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KtColor.neutral50,
      appBar: AppBar(
        title: const Text(
          'Pembayaran QRIS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: KtColor.surface,
          ),
        ),
        backgroundColor: KtColor.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: KtColor.surface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Row(
        children: [
          // Left side - Simple Receipt/Struk
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Combined Receipt & Total Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: KtColor.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: KtColor.neutral200,
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header Struk
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: KtColor.violet100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.receipt_long,
                                color: KtColor.primary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'STRUK PEMBAYARAN',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: KtColor.primary,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    DateFormat('dd MMM yyyy, HH:mm')
                                        .format(DateTime.now()),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: KtColor.neutral500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Divider
                        Container(
                          height: 1,
                          color: KtColor.neutral200,
                        ),

                        const SizedBox(height: 32),

                        // Total Pembayaran
                        Column(
                          children: [
                            Text(
                              'Total Pembayaran',
                              style: TextStyle(
                                fontSize: 18,
                                color: KtColor.neutral600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              NumberFormat.currency(
                                locale: 'id',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(orderController.total),
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: KtColor.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Konfirmasi Button
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ElevatedButton(
                      onPressed: () async {
                        final success =
                            await orderController.processPayment(context);

                        // Navigate back to home page after successful payment
                        if (success) {
                          // Clear the order and navigate back to home
                          orderController.clearOrder();
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KtColor.successText,
                        foregroundColor: KtColor.surface,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: KtColor.successText.withOpacity(0.3),
                      ),
                      child: const Text(
                        'Konfirmasi Pembayaran',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right side - QR Code Only (Focus on scanning)
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: KtColor.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: KtColor.neutral200,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'images/qris.png',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: KtColor.neutral100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: KtColor.neutral300),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code,
                              size: 200,
                              color: KtColor.neutral400,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'QR Code QRIS',
                              style: TextStyle(
                                color: KtColor.neutral400,
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
