import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kliktoko/gudang_page/GudangServices/CategoryService.dart';
import 'package:kliktoko/navigation/NavController.dart';
import 'package:kliktoko/APIService/ApiService.dart';
import 'package:kliktoko/gudang_page/GudangModel/ProductModel.dart';
import 'package:kliktoko/gudang_page/GudangModel/CategoryModel.dart';
import 'package:kliktoko/home_page/HomeController/HomeController.dart';
import 'package:kliktoko/storage/storage_service.dart';
import 'package:kliktoko/config/api_config.dart';

// Size Mapping Utility class for dynamic size mapping
class SizeMappingUtility {
  static final SizeMappingUtility _instance = SizeMappingUtility._internal();
  factory SizeMappingUtility() => _instance;
  SizeMappingUtility._internal();

  static const String baseUrl = ApiConfig.baseUrl;

  final StorageService _storageService = StorageService();
  final http.Client _client = http.Client();

  // Map to store size ID to size name mapping
  Map<int, String> _sizeMapping = {};
  bool _isMappingInitialized = false;

  // Method to initialize the size mapping from API
  Future<void> initializeSizeMapping() async {
    if (_isMappingInitialized) return;

    try {
      // Get token for authentication
      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      // Create headers for the request
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      };

      // Fetch sizes from API directly with http client
      final response = await _client.get(
        Uri.parse('$baseUrl/api/sizes'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Parse the response
        final jsonData = json.decode(response.body);

        List<dynamic> sizesJson = [];

        // Extract sizes data based on response structure
        if (jsonData is List) {
          sizesJson = jsonData;
        } else if (jsonData is Map &&
            jsonData.containsKey('data') &&
            jsonData['data'] is List) {
          sizesJson = jsonData['data'];
        } else if (jsonData is Map &&
            jsonData.containsKey('sizes') &&
            jsonData['sizes'] is List) {
          sizesJson = jsonData['sizes'];
        }

        // Build the mapping
        _sizeMapping.clear();
        for (var size in sizesJson) {
          if (size is Map<String, dynamic>) {
            final id = size['id'] is int
                ? size['id']
                : int.parse(size['id'].toString());
            final name = size['name'] as String? ?? 'Size $id';
            _sizeMapping[id] = name;
          }
        }

        print('Size mapping initialized: $_sizeMapping');
        _isMappingInitialized = true;
      }
    } catch (e) {
      print('Error initializing size mapping: $e');
      // Set some basic fallback mappings
      _sizeMapping = {
        0: 'S', // Added 0 as possible mapping
        1: 'S',
        2: 'M',
        3: 'L',
        4: 'XL',
        5: 'XXL',
        6: 'XXXL',
        7: '3L'
      };
      _isMappingInitialized = true;
    }
  }

  // Method to get size name from size ID
  String getSizeNameFromId(int sizeId) {
    return _sizeMapping[sizeId] ?? 'Size $sizeId';
  }

  // Method to check if mapping is initialized
  bool get isMappingInitialized => _isMappingInitialized;

  // Get the mapping
  Map<int, String> get sizeMapping => _sizeMapping;
}

class GudangController extends GetxController {
  // Non-reactive state (no .obs)
  bool isLoading = false;
  bool hasError = false;
  String errorMessage = '';
  List<Product> inventoryItems = [];
  List<Product> filteredItems = [];
  List<Product> outOfStockItems = []; // To display in the Out Of Stock section
  List<Category> categories = []; // Added for categories from API
  bool isCategoriesLoading = false; // Track categories loading state

  final ApiService _apiService = ApiService();
  final CategoryService _categoryService = CategoryService();
  final StorageService _storageService = StorageService();
  final SizeMappingUtility _sizeMappingUtility = SizeMappingUtility();

  // Make searchQuery reactive to properly track its state
  final RxString searchQuery = RxString('');

  // Only keep reactive state for the filter and current route
  final selectedFilter = 'Semua'.obs;
  final List<String> filterOptions = [
    'Semua',
    'Baru Datang',
    'Ukuran S',
    'Ukuran M',
    'Ukuran L',
    'Ukuran XL',
    'Ukuran XXL',
    'Ukuran XXXL',
    'Ukuran 3L',
  ];

  // Signal to close dropdown
  final shouldCloseDropdown = false.obs;

  // Flag to track if search field is active
  final isSearchFieldActive = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Initialize the size mapping utility before loading data
    _initializeSizeMappingAndLoadData();

    // Set up listener for the filter changes
    ever(selectedFilter, (_) => applyFilter());

    // Set up listener for search query changes
    debounce(searchQuery, (_) => applyFilter(),
        time: Duration(milliseconds: 300));

    // Listen to tab changes from NavController - using a simpler approach
    if (Get.isRegistered<NavController>()) {
      try {
        final navController = Get.find<NavController>();

        // Use custom worker to observe changes in NavController's selectedIndex
        ever(
          navController
              .selectedIndex.obs, // This monitors changes to selectedIndex
          (_) {
            // When tab changes, reset search and close dropdown
            closeDropdown();
            isSearchFieldActive.value = false;
          },
        );
      } catch (e) {
        print('Error setting up NavController listener: $e');
      }
    }

    // Add a simpler route change listener
    _setupRouteChangeListener();
  }

  // Simpler route change listener
  void _setupRouteChangeListener() {
    // Listen for route changes
    Get.rootDelegate.addListener(_onRouteChanged);
  }

  void _onRouteChanged() {
    // Close dropdown and reset search field state when route changes
    closeDropdown();
    isSearchFieldActive.value = false;
  }

  // Initialize size mapping and then load data
  Future<void> _initializeSizeMappingAndLoadData() async {
    await _sizeMappingUtility.initializeSizeMapping();
    await checkAuthAndLoadData();
    await loadCategories();
  }

  // Method to be called when search field gets unfocused
  void onSearchFieldUnfocused() {
    isSearchFieldActive.value = false;
  }

  // Method to be called when search field gets focused
  void onSearchFieldFocused() {
    isSearchFieldActive.value = true;
  }

  // Load categories from API
  Future<void> loadCategories() async {
    try {
      isCategoriesLoading = true;
      update();

      categories = await _categoryService.getCategories();
      print('Loaded ${categories.length} categories');
    } catch (e) {
      print('Error loading categories: $e');
      // Categories will remain as default values
    } finally {
      isCategoriesLoading = false;
      update();
    }
  }

  // Method to find a category ID by name
  int? findCategoryIdByName(String categoryName) {
    // Try to find a category with matching name (case insensitive)
    for (var category in categories) {
      if (category.name.toLowerCase() == categoryName.toLowerCase()) {
        return category.id;
      }
    }

    return null; // Return null if no matching category
  }

  // Improved method to filter products by category name
  void filterByCategory(String categoryName) {
    // Try to find a category ID first
    int? categoryId = findCategoryIdByName(categoryName);

    if (categoryId != null) {
      // If category ID is found, filter by category_id
      filteredItems = inventoryItems
          .where((item) => item.categoryId == categoryId)
          .toList();

      print(
          'Filtered by category ID: $categoryId. Found ${filteredItems.length} items');
    } else {
      // If no category ID is found, fall back to text-based filtering
      print(
          'No category ID found for "$categoryName", using text-based filtering');
      searchQuery.value = categoryName;
      applyFilter();
    }

    update();
  }

  // Add new method to find a product by code
  Product? findProductByCode(String code) {
    // First check if code is empty
    if (code.isEmpty) return null;

    // Search in all inventory items
    for (var product in inventoryItems) {
      // Check if product has a code and it matches the scanned code
      if (product.code != null &&
          product.code!.toLowerCase() == code.toLowerCase()) {
        return product;
      }
    }

    // No match found
    return null;
  }

  Future<void> checkAuthAndLoadData() async {
    try {
      // Check if user is logged in
      bool isLoggedIn = await _storageService.isLoggedIn();
      if (isLoggedIn) {
        await loadInventoryData();
      } else {
        // User is not logged in, redirect to login
        hasError = true;
        errorMessage = 'You need to login first to view inventory.';
        update();

        // Delay the navigation to allow the error message to be seen
        Future.delayed(Duration(seconds: 2), () {
          Get.offAllNamed('/login');
        });
      }
    } catch (e) {
      print('Error checking auth status: $e');
      hasError = true;
      errorMessage = 'Error checking authentication status';
      update();
    }
  }

  // Method to fix product sizes based on size_id
  List<Product> correctProductSizes(List<Product> products) {
    if (!_sizeMappingUtility.isMappingInitialized) return products;

    final correctedProducts = <Product>[];

    for (var product in products) {
      if (product.sizeId != null) {
        final correctSize =
            _sizeMappingUtility.getSizeNameFromId(product.sizeId!);

        // Only create a new product if the size is different
        if (correctSize != product.size) {
          correctedProducts.add(Product(
            id: product.id,
            name: product.name,
            size: correctSize,
            stock: product.stock,
            isNew: product.isNew,
            price: product.price,
            imagePath: product.imagePath,
            description: product.description,
            code: product.code,
            createdAt: product.createdAt,
            updatedAt: product.updatedAt,
            categoryId: product.categoryId,
            sizeId: product.sizeId,
          ));
        } else {
          correctedProducts.add(product);
        }
      } else {
        correctedProducts.add(product);
      }
    }

    return correctedProducts;
  }

  Future<void> loadInventoryData() async {
    try {
      isLoading = true;
      hasError = false;
      errorMessage = '';
      update();

      // Check if token exists
      final token = await _storageService.getToken();
      if (token == null) {
        hasError = true;
        errorMessage = 'Authentication token not found. Please log in again.';
        update();

        // Redirect to login after showing error message
        Future.delayed(Duration(seconds: 2), () {
          Get.offAllNamed('/login');
        });
        return;
      }

      // Fetch products from API
      List<Product> products = await _apiService.getProducts();

      // Apply size correction
      inventoryItems = correctProductSizes(products);

      // Extract out of stock items for special display
      outOfStockItems =
          inventoryItems.where((item) => item.hasOutOfStockSize).toList();

      // Update the HomeController if it's registered
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.outOfStockProducts.value = outOfStockItems;
      }

      applyFilter();

      print('Loaded ${inventoryItems.length} products from API');
      print('Found ${outOfStockItems.length} out of stock items');
    } catch (e) {
      print('Error loading inventory data: $e');
      hasError = true;

      // Check if it's an auth error
      if (e.toString().contains('401')) {
        errorMessage = 'Your session has expired. Please log in again.';
        // Clear login data and redirect to login
        await _storageService.clearLoginData();

        // Delay navigation to allow error message to be seen
        Future.delayed(Duration(seconds: 2), () {
          Get.offAllNamed('/login');
        });
      } else {
        errorMessage = 'Gagal memuat produk. Silakan coba lagi nanti.';
      }

      inventoryItems = [];
      outOfStockItems = [];
      filteredItems = [];
    } finally {
      isLoading = false;
      update();
    }
  }

  // Method to get products by category ID directly from API
  Future<List<Product>> getProductsByCategory(int categoryId) async {
    try {
      isLoading = true;
      update();

      // Use the API service to get products filtered by category
      final List<Product> products =
          await _apiService.getProductsByCategory(categoryId);

      // Apply size correction
      return correctProductSizes(products);
    } catch (e) {
      print('Error fetching products by category: $e');
      // If API fetch fails, fall back to local filtering
      return inventoryItems
          .where((item) => item.categoryId == categoryId)
          .toList();
    } finally {
      isLoading = false;
      update();
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    // Filtering will be triggered by the reaction
  }

  void updateFilter(String filter) {
    selectedFilter.value = filter;
    // Filtering will be triggered by the reaction
  }

  void applyFilter() {
    // Start with all items
    var result = [...inventoryItems];

    // Apply search query filter if any
    if (searchQuery.value.isNotEmpty) {
      final lowerCaseQuery = searchQuery.value.toLowerCase();
      result = result
          .where((item) =>
              item.name.toLowerCase().contains(lowerCaseQuery) ||
              item.size.toLowerCase().contains(lowerCaseQuery) ||
              (item.code != null &&
                  item.code!.toLowerCase().contains(lowerCaseQuery)))
          .toList();
    }

    // Apply category filter if not "Semua"
    if (selectedFilter.value != 'Semua') {
      switch (selectedFilter.value) {
        case 'Baru Datang':
          result = result.where((item) => item.isNew).toList();
          break;
        case 'Ukuran S':
          result =
              result.where((item) => item.size.toLowerCase() == 's').toList();
          break;
        case 'Ukuran M':
          result =
              result.where((item) => item.size.toLowerCase() == 'm').toList();
          break;
        case 'Ukuran L':
          result =
              result.where((item) => item.size.toLowerCase() == 'l').toList();
          break;
        case 'Ukuran XL':
          result =
              result.where((item) => item.size.toLowerCase() == 'xl').toList();
          break;
        case 'Ukuran XXL':
          result =
              result.where((item) => item.size.toLowerCase() == 'xxl').toList();
          break;
        case 'Ukuran XXXL':
          result = result
              .where((item) => item.size.toLowerCase() == 'xxxl')
              .toList();
          break;
        case 'Ukuran 3L':
          result =
              result.where((item) => item.size.toLowerCase() == '3l').toList();
          break;
      }
    }

    // Update the filtered items
    filteredItems = result;
    update();
  }

  // Method to get limited out of stock items for display
  List<Product> getOutOfStockItemsForDisplay(int limit) {
    return outOfStockItems.take(limit).toList();
  }

  // Method to create a product
  Future<bool> createProduct(Product product) async {
    try {
      isLoading = true;
      update();

      await _apiService.createProduct(product);
      await loadInventoryData(); // Reload the data after creation

      return true;
    } catch (e) {
      print('Error creating product: $e');

      // Check if it's an auth error
      if (e.toString().contains('401')) {
        errorMessage = 'Sesi Anda telah berakhir. Silakan login kembali.';
        // Handle auth error
        await _storageService.clearLoginData();
        Future.delayed(Duration(seconds: 1), () {
          Get.offAllNamed('/login');
        });
      }

      return false;
    } finally {
      isLoading = false;
      update();
    }
  }

  // Method to update a product
  Future<bool> updateProduct(int id, Product product) async {
    try {
      isLoading = true;
      update();

      await _apiService.updateProduct(id, product);
      await loadInventoryData(); // Reload the data after update

      return true;
    } catch (e) {
      print('Error updating product: $e');

      // Check if it's an auth error
      if (e.toString().contains('401')) {
        errorMessage = 'Sesi Anda telah berakhir. Silakan login kembali.';
        // Handle auth error
        await _storageService.clearLoginData();
        Future.delayed(Duration(seconds: 1), () {
          Get.offAllNamed('/login');
        });
      }

      return false;
    } finally {
      isLoading = false;
      update();
    }
  }

  // Method to delete a product
  Future<bool> deleteProduct(int id) async {
    try {
      isLoading = true;
      update();

      final result = await _apiService.deleteProduct(id);
      await loadInventoryData(); // Reload the data after deletion

      return result;
    } catch (e) {
      print('Error deleting product: $e');

      // Check if it's an auth error
      if (e.toString().contains('401')) {
        errorMessage = 'Sesi Anda telah berakhir. Silakan login kembali.';
        // Handle auth error
        await _storageService.clearLoginData();
        Future.delayed(Duration(seconds: 1), () {
          Get.offAllNamed('/login');
        });
      }

      return false;
    } finally {
      isLoading = false;
      update();
    }
  }

  void refreshInventory() {
    loadInventoryData();
  }

  // Helper methods for dropdown
  void resetDropdownFlag() {
    shouldCloseDropdown.value = false;
  }

  void closeDropdown() {
    shouldCloseDropdown.value = true;
  }

  // Manually trigger this when pages change to close dropdown
  void onPageChanged() {
    shouldCloseDropdown.value = true;
    isSearchFieldActive.value = false; // Also reset search field state
  }

  // Add this method to handle outside clicks
  void handleOutsideClick() {
    shouldCloseDropdown.value = true;
    isSearchFieldActive.value = false; // Also reset search field state
  }

  @override
  void dispose() {
    // Remove route change listener
    Get.rootDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }
}
