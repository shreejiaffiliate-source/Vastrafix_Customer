class Items {
  final int id;
  final String name;
  final double price;
  final bool is_active;

  Items({
    required this.id,
    required this.name,
    required this.price,
    required this.is_active,
  });

  factory Items.fromJson(Map<String, dynamic> json) {
    return Items(
      id: json['id'],
      name: json['name'], // Changed 'title' to 'name' to match Django
      price: double.parse(json['price'].toString()),
      is_active: json['is_active'] == true,
    );
  }
}