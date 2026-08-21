import 'package:flutter/material.dart';

class Category {
  final int id;
  final String name;
  final String? description;
  final String? iconName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.iconName,
    this.createdAt,
    this.updatedAt,
  });

  // Getter for icon code string needed for CategoryItem
  String get icon => getIconCode();

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] as String,
      description: json['description'] as String?,
      iconName: json['icon_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  // Helper method to get appropriate icon
  IconData getIcon() {
    // Map category names or icon_name field to appropriate Flutter icons
    switch (iconName?.toLowerCase() ?? name.toLowerCase()) {
      case 't-shirt':
      case 'tshirt':
      case 'shirt':
        return Icons.shopping_bag_outlined;
      case 'pants':
      case 'trousers':
        return Icons.format_color_reset_outlined;
      case 'hot':
      case 'hot food':
        return Icons.local_fire_department_outlined;
      case 'drink':
      case 'beverages':
        return Icons.coffee_outlined;
      case 'snack':
      case 'snacks':
      case 'food':
        return Icons.restaurant_outlined;
      case 'accessories':
        return Icons.watch_outlined;
      case 'shoes':
        return Icons.trending_up_outlined;
      default:
        return Icons.category_outlined; // Default icon
    }
  }

  // Convert icon name to IconData code for display
  String getIconCode() {
    final iconData = getIcon();
    return iconData.codePoint.toRadixString(16);
  }

  @override
  String toString() => name;
}
