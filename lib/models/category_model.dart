import 'package:vastrafix/models/sub_category_model.dart';

class CategoryModel {
  final int id;
  final String name;
  final String description;
  final String icon;
  final String slug;
  final List<SubCategoryModel> subcategories;

  CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.subcategories,
    required this.slug,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? "",
      icon: json['icon'] ?? "",
      slug: json['slug'] ?? "",
      subcategories: (json['subcategories'] as List)
          .map((i) => SubCategoryModel.fromJson(i))
          .toList(),
    );
  }
}