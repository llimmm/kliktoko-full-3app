import 'order_item.dart';

enum OrderStatus {
  completed,
  cancelled,
}

// Map from controller's OrderStatus to model's OrderStatus
OrderStatus mapFromControllerStatus(dynamic controllerStatus) {
  if (controllerStatus.toString().contains('completed')) {
    return OrderStatus.completed;
  } else {
    return OrderStatus.cancelled;
  }
}

class Order {
  final String id;
  final DateTime date;
  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final OrderStatus status;
  final String? karyawan;

  Order({
    required this.id,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.status,
    this.karyawan,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  // Factory method to create a new order
  factory Order.create({
    required List<OrderItem> items,
    required double subtotal,
    required double discount,
    required double total,
    required dynamic status,
  }) {
    // Generate a unique ID
    final now = DateTime.now();
    final id = 'ORD-${now.millisecondsSinceEpoch.toString().substring(6)}';

    return Order(
      id: id,
      date: now,
      items: List<OrderItem>.from(items),
      subtotal: subtotal,
      discount: discount,
      total: total,
      status: mapFromControllerStatus(status),
    );
  }

  // Convert to a JSON representation for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'items': items
          .map((item) => {
                'productId': item.product.id,
                'productName': item.product.name,
                'productPrice': item.product.price,
                'quantity': item.quantity,
                'totalPrice': item.totalPrice,
                'imagePath': item.product.imagePath,
                'imageUrl': item.product.imageUrl,
                'category': item.product.category,
              })
          .toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'status': status == OrderStatus.completed ? 'Completed' : 'Cancelled',
      'karyawan': karyawan,
    };
  }
}
