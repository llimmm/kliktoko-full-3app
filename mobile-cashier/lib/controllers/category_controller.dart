import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import '../service/category_service.dart';

class CategoryController with ChangeNotifier {
  final CategoryService categoryService;

  CategoryController({required this.categoryService});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  String _selectedCategory = 'Shirt';
  String get selectedCategory => _selectedCategory;

  void setSelectedCategory(String categoryName) {
    _selectedCategory = categoryName;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await categoryService.getCategories();
      // If no categories were found, use defaults
      if (_categories.isEmpty) {
        _categories = _getDefaultCategories();
      }

      // Check if the current selected category exists in the loaded categories
      // If not, select the first one
      if (!_categories.any((c) => c.name == _selectedCategory) &&
          _categories.isNotEmpty) {
        _selectedCategory = _categories.first.name;
      }

      _error = null;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading categories: $e');
      }

      _error = e.toString();
      // Use default categories as fallback
      _categories = _getDefaultCategories();
    } finally {
      _isLoading = false;
      notifyListeners();
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
}
