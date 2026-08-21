import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../service/api_service.dart';

class ProductController with ChangeNotifier {
  final ApiService apiService;
  ProductController({required this.apiService});

  List<Product> _products = [];
  List<Product> _allProducts =
      []; // Store all products for "All" category search

  List<Product> get products =>
      _filteredProducts.isNotEmpty || _searchQuery.isNotEmpty
          ? _filteredProducts
          : _products;

  List<Product> _filteredProducts = [];
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _selectedCategory = 'Shirt';
  String get selectedCategory => _selectedCategory;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  void setCategory(String category) {
    if (category == _selectedCategory) return;

    _selectedCategory = category;

    // Handle the special "All" category case
    if (category == 'All') {
      // Use all products but maintain search filter
      _products = _allProducts;
      if (_searchQuery.isNotEmpty) {
        _filterProducts();
      }
      notifyListeners();
    } else {
      // Load products for the selected category
      loadProductsByCategory(category);
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    _filterProducts();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredProducts = [];
    notifyListeners();

    // If we were in "All" mode, return to the last specific category
    if (_selectedCategory == 'All') {
      loadProductsByCategory('Shirt'); // Default back to Shirt category
    }
  }

  void _filterProducts() {
    if (_searchQuery.isEmpty) {
      _filteredProducts = [];
      return;
    }

    final query = _searchQuery.toLowerCase();

    // When searching across all products for "All" category
    if (_selectedCategory == 'All') {
      _filteredProducts = _allProducts.where((product) {
        return product.name.toLowerCase().contains(query) ||
            product.category.toLowerCase().contains(query);
      }).toList();
    } else {
      // When searching within a specific category
      _filteredProducts = _products.where((product) {
        return product.name.toLowerCase().contains(query);
      }).toList();
    }
  }

  Future<void> loadProductsByCategory(String category) async {
    if (category == 'All') {
      // Special case - load all products
      _selectedCategory = 'All';
      if (_allProducts.isEmpty) {
        _isLoading = true;
        _error = null;
        notifyListeners();

        try {
          // Fetch all products from API or load them from cached categories
          _allProducts = await apiService.getAllProducts();
          _products = _allProducts;

          if (_searchQuery.isNotEmpty) {
            _filterProducts();
          }
        } catch (e) {
          _handleError(e);
        } finally {
          _isLoading = false;
          notifyListeners();
        }
      } else {
        // Use cached all products
        _products = _allProducts;
        if (_searchQuery.isNotEmpty) {
          _filterProducts();
        }
        notifyListeners();
      }
      return;
    }

    // Regular category loading
    _selectedCategory = category;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('Loading products for category: $category');
      }

      _products = await apiService.getProductsByCategory(category);

      // Add these products to our all products cache if not already there
      _updateAllProductsCache(_products);

      // If there was an active search, update filtered results
      if (_searchQuery.isNotEmpty) {
        _filterProducts();
      }

      if (kDebugMode) {
        print('Successfully loaded ${_products.length} products');
      }
    } catch (e) {
      _handleError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateAllProductsCache(List<Product> newProducts) {
    // Add new products to the all products cache if they don't exist
    for (final product in newProducts) {
      if (!_allProducts.any((p) => p.name == product.name)) {
        _allProducts.add(product);
      }
    }
  }

  void _handleError(dynamic e) {
    final errorMsg = e.toString();
    _error = errorMsg.startsWith('Exception: ')
        ? errorMsg.substring('Exception: '.length)
        : errorMsg;
    _products = [];
    _filteredProducts = [];

    if (kDebugMode) {
      print('Error loading products: $_error');
    }

    // Handle specific network/TLS errors
    if (_error!.contains('TLSV1_ALERT_INTERNAL_ERROR') ||
        _error!.contains('TLS') ||
        _error!.contains('SSL') ||
        _error!.contains('CERTIFICATE') ||
        _error!.contains('HANDSHAKE')) {
      _error =
          'Network security error. Please check your internet connection and try again.';
      if (kDebugMode) {
        print('TLS/SSL Error detected: $_error');
      }
    }

    // Handle connection timeout
    else if (_error!.contains('TIMEOUT') ||
        _error!.contains('CONNECTION') ||
        _error!.contains('SOCKET')) {
      _error =
          'Connection timeout. Please check your internet connection and try again.';
      if (kDebugMode) {
        print('Connection Error detected: $_error');
      }
    }

    // Handle specific cases
    else if (_error!.contains('Unauthorized') || _error!.contains('401')) {
      if (kDebugMode) {
        print('Unauthorized access - token may be expired');
      }
      _error = 'Unauthorized access. Please login again.';
    } else if (_error!.contains('404') || _error!.contains('Not Found')) {
      if (kDebugMode) {
        print('API endpoint not found');
      }
      _error = 'API endpoint not found. Please contact administrator.';
    } else if (_error!.contains('500') ||
        _error!.contains('Internal Server Error')) {
      if (kDebugMode) {
        print('Server error');
      }
      _error = 'Server error. Please try again later.';
    }

    notifyListeners();
  }
}
