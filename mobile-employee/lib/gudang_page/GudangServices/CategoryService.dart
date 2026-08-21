import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kliktoko/gudang_page/GudangModel/CategoryModel.dart';
import 'package:kliktoko/gudang_page/GudangModel/ProductModel.dart';
import 'package:kliktoko/storage/storage_service.dart';
import 'package:kliktoko/config/api_config.dart';

class CategoryService {
  static const String baseUrl = ApiConfig.baseUrl;
  
  // Singleton pattern
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final http.Client _client = http.Client();
  final StorageService _storageService = StorageService();

  // Get all categories
  Future<List<Category>> getCategories() async {
    try {
      // Make sure to check if token exists first
      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('No authentication token available. Please login first.');
      }
      
      final response = await _client.get(
        Uri.parse('$baseUrl/api/categories'),
        headers: await _getHeaders(token),
      );

      print('Categories API response status: ${response.statusCode}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = json.decode(response.body);
        print('Categories API response body: ${response.body.substring(0, response.body.length < 200 ? response.body.length : 200)}...');
        
        List<dynamic> categoriesJson = [];
        
        // Handle different API response structures
        if (jsonData is List) {
          categoriesJson = jsonData;
        } else if (jsonData is Map && jsonData.containsKey('data') && jsonData['data'] is List) {
          categoriesJson = jsonData['data'];
        } else if (jsonData is Map && jsonData.containsKey('categories') && jsonData['categories'] is List) {
          categoriesJson = jsonData['categories'];
        }
        
        print('Parsed ${categoriesJson.length} categories from API');
        return categoriesJson.map((item) => Category.fromJson(item)).toList();
      } else {
        // If API fails, return default categories as fallback
        print('Failed to fetch categories. Using default categories instead.');
        return _getDefaultCategories();
      }
    } catch (e) {
      print('Error fetching categories: $e');
      // Return default categories in case of error
      return _getDefaultCategories();
    }
  }

  // Get a specific category by name
  Future<Category?> getCategoryByName(String name) async {
    try {
      final categories = await getCategories();
      
      // Find the category with matching name (case insensitive)
      return categories.firstWhere(
        (category) => category.name.toLowerCase() == name.toLowerCase(),
        orElse: () => Category(id: -1, name: name), // Return a default category if not found
      );
    } catch (e) {
      print('Error finding category by name: $e');
      return null;
    }
  }

  // Get products by category ID
  Future<List<Product>> getProductsByCategory(int categoryId) async {
    try {
      // Make sure to check if token exists first
      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('No authentication token available. Please login first.');
      }
      
      // Get all products first - we'll filter by category on the client side
      // since the API may not support direct category filtering
      final response = await _client.get(
        Uri.parse('$baseUrl/api/products'),
        headers: await _getHeaders(token),
      );

      print('Products API response status: ${response.statusCode}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = json.decode(response.body);
        
        List<dynamic> productsJson = [];
        
        // Handle different API response structures
        if (jsonData is List) {
          productsJson = jsonData;
        } else if (jsonData is Map && jsonData.containsKey('data') && jsonData['data'] is List) {
          productsJson = jsonData['data'];
        } else if (jsonData is Map && jsonData.containsKey('products') && jsonData['products'] is List) {
          productsJson = jsonData['products'];
        }
        
        // Convert all products to Product objects
        final allProducts = productsJson.map((item) => Product.fromJson(item)).toList();
        
        // Filter by category ID
        final categoryProducts = allProducts.where((product) => 
          product.categoryId == categoryId).toList();
        
        print('Found ${categoryProducts.length} products for category $categoryId');
        return categoryProducts;
      } else {
        throw Exception('Failed to fetch products. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching products by category: $e');
      return [];
    }
  }

  // Default categories as fallback if API fails
  List<Category> _getDefaultCategories() {
    return [
      Category(id: 1, name: 'T-Shirt', iconName: 'checkroom'),
      Category(id: 2, name: 'Pants', iconName: 'accessibility_new'),
      Category(id: 3, name: 'Kids', iconName: 'child_care'),
      Category(id: 4, name: 'Adults', iconName: 'person'),
      Category(id: 5, name: 'Uniform', iconName: 'school'),
    ];
  }

  Future<Map<String, String>> _getHeaders([String? token]) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    } else {
      // Try to get token from storage if not provided
      final storedToken = await _storageService.getToken();
      if (storedToken != null) {
        headers['Authorization'] = 'Bearer $storedToken';
      }
    }

    return headers;
  }
}