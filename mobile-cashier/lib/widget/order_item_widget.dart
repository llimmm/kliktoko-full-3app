import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../models/order_item.dart';

class OrderItemWidget extends StatelessWidget {
  final OrderItem item;
  final Function() onIncrement;
  final Function() onDecrement;

  const OrderItemWidget({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: KtColor.neutral200,
              ),
              child: item.product.image != null &&
                      item.product.image!.isNotEmpty
                  ? Image.network(
                      item.product.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        if (kDebugMode) {
                          print('Error loading image in order item: $error');
                        }
                        return const Icon(Icons.image_not_supported_outlined,
                            color: KtColor.neutral400);
                      },
                    )
                  : const Icon(Icons.fastfood, color: KtColor.neutral400),
            ),
          ),

          const SizedBox(width: 10),

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.variant != null)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: KtColor.violet100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.variant!.size,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: KtColor.violet700,
                      ),
                    ),
                  ),
                Text(
                  formatter.format(item.product.price),
                  style: TextStyle(
                    color: KtColor.neutral600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls with circular buttons - always horizontal
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decrement button
              InkWell(
                onTap: onDecrement,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: KtColor.neutral400,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.remove,
                    size: 18,
                    color: KtColor.textSecondary,
                  ),
                ),
              ),

              // Quantity number
              Container(
                width: 25,
                alignment: Alignment.center,
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

              // Increment button
              InkWell(
                onTap: onIncrement,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: KtColor.primary,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 18,
                    color: KtColor.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
