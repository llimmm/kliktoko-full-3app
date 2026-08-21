import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/product.dart';
import 'api_service.dart';

class CategoryService {
  final String baseUrl;
  final http.Client _client;
  final ApiService apiService;

  CategoryService({
    required this.baseUrl,
    required this.apiService,
  }) : _client = http.Client();

  // Get all categories
  Future<List<Category>> getCategories() async {
    try {
      // Get the token from the ApiService
      final token = apiService.token;
      if (token == null) {
        print('No authentication token available. Using default categories.');
        return _getDefaultCategories();
      }

      final response = await _client.get(
        Uri.parse('$baseUrl/api/categories'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Categories API response status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = json.decode(response.body);
        print('Categories API response received');

        List<dynamic> categoriesJson = [];

        // Handle different API response structures
        if (jsonData is List) {
          categoriesJson = jsonData;
        } else if (jsonData is Map &&
            jsonData.containsKey('data') &&
            jsonData['data'] is List) {
          categoriesJson = jsonData['data'];
        } else if (jsonData is Map &&
            jsonData.containsKey('categories') &&
            jsonData['categories'] is List) {
          categoriesJson = jsonData['categories'];
        }

        print('Parsed ${categoriesJson.length} categories from API');
        return categoriesJson.map((item) => Category.fromJson(item)).toList();
      } else {
        // If API fails, return default categories as fallback
        print(
            'Failed to fetch categories. Using default categories instead. Status: ${response.statusCode}');
        return _getDefaultCategories();
      }
    } catch (e) {
      print('Error fetching categories: $e');
      // Return default categories in case of error
      return _getDefaultCategories();
    }
  }

  // Default categories as fallback if API fails
  List<Category> _getDefaultCategories() {
    return [
      Category(id: 1, name: 'Shirt', iconName: 'checkroom'),
      Category(id: 2, name: 'Drink', iconName: 'local_drink'),
      Category(id: 3, name: 'Snack', iconName: 'fastfood'),
      Category(id: 4, name: 'Pants', iconName: 'accessibility_new'),
      Category(id: 5, name: 'Hot', iconName: 'whatshot'),
    ];
  }

  // Get products by category name
  Future<List<Product>> getProductsByCategory(String categoryName) async {
    try {
      // First attempt to get the category by name
      final categories = await getCategories();
      final category = categories.firstWhere(
          (c) => c.name.toLowerCase() == categoryName.toLowerCase(),
          orElse: () => Category(id: -1, name: categoryName));

      if (category.id == -1) {
        // If we couldn't find the category by name, just use the name to fetch products
        return await apiService.getProductsByCategory(categoryName);
      }

      // Otherwise use the category ID
      // The API might support a different endpoint for fetching by category ID
      return await apiService.getProductsByCategory(categoryName);
    } catch (e) {
      print('Error fetching products by category name: $e');
      return [];
    }
  }
}
