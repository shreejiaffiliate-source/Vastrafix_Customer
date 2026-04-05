import 'item_model.dart';

class SubCategoryModel {
  final int id;
  final String name;
  final List<Items> items;

  SubCategoryModel({
    required this.id,
    required this.name,
    required this.items});

  factory SubCategoryModel.fromJson(Map<String, dynamic> json) {
    return SubCategoryModel(
      id: json['id'],
      name: json['name'],
      items: (json['items'] as List?)
          ?.map((i) => Items.fromJson(i))
          .toList() ?? [],
    );
  }
}