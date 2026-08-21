import 'package:flutter/material.dart'; // Added import for Icons

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
        return Icons.checkroom;
      case 'pants':
      case 'trousers':
        return Icons.accessibility_new;
      case 'kids':
      case 'children':
        return Icons.child_care;
      case 'adults':
      case 'men':
      case 'women':
        return Icons.person;
      case 'uniform':
      case 'school':
        return Icons.school;
      case 'accessories':
        return Icons.watch;
      case 'shoes':
        return Icons.shopping_bag;
      default:
        return Icons.category; // Default icon
    }
  }

  @override
  String toString() => name;
}
