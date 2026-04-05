class CartItem {
  final int id;
  final String name;
  final String service;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.service,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;
}