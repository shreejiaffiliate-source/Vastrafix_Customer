// models/order_model.dart

class OrderItem {
  final String name;
  final int quantity;
  final double price;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      // Agar backend 'item_name' bhej raha hai toh wo use karein
      name: json['item_name'] ?? "Item",
      quantity: json['quantity'] ?? 0,
      price: double.tryParse(json['item_price']?.toString() ?? "0") ?? 0,
    );
  }
}

class OrderModel {
  final String orderId;
  final String service;
  final String status;
  final List<OrderItem> items;
  final double total;

  OrderModel({
    required this.orderId,
    required this.service,
    required this.status,
    required this.items,
    required this.total,
    required DateTime date,
  });
}