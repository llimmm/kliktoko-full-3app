import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:math' as math;

import 'package:kliktoko/login_page/LoginModel/LoginModel.dart';
import 'package:kliktoko/gudang_page/GudangModel/ProductModel.dart';
import 'package:kliktoko/storage/storage_service.dart';
import 'package:kliktoko/config/api_config.dart';

class ApiService {
  static const String baseUrl = ApiConfig.baseUrl;
  static const String imageBaseUrl = ApiConfig.imageBaseUrl;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();
  final StorageService _storageService = StorageService();

  // Helper to get full image URL
  static String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return ''; // Return empty string for null or empty paths
    }

    // If already a full URL, return as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // Otherwise, prepend the base URL
    return '$imageBaseUrl$imagePath';
  }

  Future<LoginResponse> login(LoginModel loginData) async {
    try {
      print('Sending login request for user: ${loginData.name}');

      final response = await _client.post(
        Uri.parse('$baseUrl/api/login'),
        headers: await _getHeaders(),
        body: json.encode(loginData.toJson()),
      );

      print('API Response Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final responseData = json.decode(response.body);
          return LoginResponse.fromJson(responseData);
        } catch (e) {
          print('Error parsing login response: $e');
          // Even if parsing fails but status code is successful, create a basic success response
          if (response.body.contains('token')) {
            // Try to extract token using regex as a last resort
            final RegExp tokenRegex = RegExp(r'"token"\s*:\s*"([^"]+)"');
            final match = tokenRegex.firstMatch(response.body);
            final token = match?.group(1) ?? '';

            return LoginResponse(
              token: token,
              message: 'Login berhasil',
              success: true,
              user: {'name': loginData.name},
            );
          }
          throw Exception('Gagal memproses respons login: $e');
        }
      } else {
        // Convert status code to Indonesian error message
        String errorMessage = _getIndonesianErrorMessage(response.statusCode);
        throw HttpException(errorMessage, response.statusCode);
      }
    } catch (e) {
      print('Error during login API call: $e');
      throw _handleError(e);
    }
  }

  Future<Map<String, String>> _getHeaders([String? token]) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    try {
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        print('Using provided token for request');
      } else {
        // Try to get token from storage if not provided
        final storedToken = await _storageService.getToken();
        if (storedToken != null && storedToken.isNotEmpty) {
          headers['Authorization'] = 'Bearer $storedToken';
          print('Using stored token for request');
        } else {
          print('No token available for request');
        }
      }
    } catch (e) {
      print('Error setting auth headers: $e');
    }

    return headers;
  }

  Exception _handleError(dynamic error) {
    if (error is HttpException) return error;
    return Exception('Terjadi kesalahan yang tidak terduga: $error');
  }

  // Helper method to convert status codes to Indonesian error messages
  String _getIndonesianErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Permintaan tidak valid. Silakan periksa data yang dimasukkan.';
      case 401:
        return 'Username atau password salah.';
      case 403:
        return 'Akses ditolak. Hanya karyawan yang dapat mengakses aplikasi ini.';
      case 404:
        return 'Data tidak ditemukan.';
      case 500:
        return 'Terjadi kesalahan pada server. Silakan coba lagi nanti.';
      case 502:
        return 'Server sedang dalam pemeliharaan. Silakan coba lagi nanti.';
      case 503:
        return 'Layanan tidak tersedia saat ini. Silakan coba lagi nanti.';
      default:
        return 'Terjadi kesalahan dengan kode status: $statusCode';
    }
  }

  Future<Map<String, dynamic>> getUserData(String token) async {
    try {
      if (token.isEmpty) {
        throw HttpException('Token kosong', 401);
      }

      print(
          'Fetching user data with token: ${token.substring(0, math.min(token.length, 10))}...');
      final response = await _client.get(
        Uri.parse('$baseUrl/api/user'),
        headers: await _getHeaders(token),
      );

      print('User data API response status: ${response.statusCode}');
      print('User data API response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);

          // Extract user data from the response
          Map<String, dynamic> userData = {};

          // Handle different API response structures
          if (responseData.containsKey('data') &&
              responseData['data'] is Map<String, dynamic>) {
            userData = responseData['data'];
          } else if (responseData.containsKey('user') &&
              responseData['user'] is Map<String, dynamic>) {
            userData = responseData['user'];
          } else {
            // If no structured data, use the entire response
            userData = responseData;
          }

          print('Parsed user data: $userData');
          return userData;
        } catch (e) {
          print('Error parsing user data: $e');
          throw Exception('Gagal memproses data pengguna: $e');
        }
      } else {
        // Convert status code to Indonesian error message
        String errorMessage = _getIndonesianErrorMessage(response.statusCode);
        throw HttpException(errorMessage, response.statusCode);
      }
    } catch (e) {
      print('Error fetching user data: $e');
      throw _handleError(e);
    }
  }

  // Get all products - with token verification
  Future<List<Product>> getProducts() async {
    try {
      // Make sure to check if token exists first
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) {
        throw HttpException(
            'Token autentikasi tidak tersedia. Silakan login terlebih dahulu.',
            401);
      }

      final headers = await _getHeaders(token);
      print(
          'Fetching products with token: ${token.substring(0, math.min(token.length, 10))}...');

      final response = await _client.get(
        Uri.parse('$baseUrl/api/products'),
        headers: headers,
      );

      print('Products API response status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = json.decode(response.body);
        print(
            'Products API response body: ${response.body.substring(0, math.min(response.body.length, 200))}...');

        List<dynamic> productsJson = [];

        // Handle different API response structures
        if (jsonData is List) {
          productsJson = jsonData;
        } else if (jsonData is Map &&
            jsonData.containsKey('data') &&
            jsonData['data'] is List) {
          productsJson = jsonData['data'];
        } else if (jsonData is Map &&
            jsonData.containsKey('products') &&
            jsonData['products'] is List) {
          productsJson = jsonData['products'];
        }

        print('Parsed ${productsJson.length} products from API');
        return productsJson.map((item) => Product.fromJson(item)).toList();
      } else {
        // Convert status code to Indonesian error message
        String errorMessage = _getIndonesianErrorMessage(response.statusCode);
        throw HttpException(errorMessage, response.statusCode);
      }
    } catch (e) {
      print('Error fetching products: $e');
      throw _handleError(e);
    }
  }

  // Get a specific product by ID
  Future<Product> getProduct(int id) async {
    try {
      // Make sure to check if token exists first
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) {
        throw HttpException(
            'No authentication token available. Please login first.', 401);
      }

      final response = await _client.get(
        Uri.parse('$baseUrl/api/products/$id'),
        headers: await _getHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = json.decode(response.body);

        // Handle different API response structures
        Map<String, dynamic> productJson;
        if (jsonData is Map && jsonData.containsKey('data')) {
          productJson = jsonData['data'];
        } else {
          productJson = jsonData;
        }

        return Product.fromJson(productJson);
      } else {
        throw HttpException(
            'Request failed with status: ${response.statusCode}',
            response.statusCode);
      }
    } catch (e) {
      print('Error fetching product details: $e');
      throw _handleError(e);
    }
  }

  // Create a new product
  Future<Product> createProduct(Product product) async {
    try {
      // Make sure to check if token exists first
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) {
        throw HttpException(
            'No authentication token available. Please login first.', 401);
      }

      final response = await _client.post(
        Uri.parse('$baseUrl/api/products'),
        headers: await _getHeaders(token),
        body: json.encode(product.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = json.decode(response.body);

        Map<String, dynamic> productJson;
        if (jsonData is Map && jsonData.containsKey('data')) {
          productJson = jsonData['data'];
        } else {
          productJson = jsonData;
        }

        return Product.fromJson(productJson);
      } else {
        throw HttpException(
            'Request failed with status: ${response.statusCode}',
            response.statusCode);
      }
    } catch (e) {
      print('Error creating product: $e');
      throw _handleError(e);
    }
  }

  // Update an existing product
  Future<Product> updateProduct(int id, Product product) async {
    try {
      // Make sure to check if token exists first
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) {
        throw HttpException(
            'No authentication token available. Please login first.', 401);
      }

      final response = await _client.put(
        Uri.parse('$baseUrl/api/products/$id'),
        headers: await _getHeaders(token),
        body: json.encode(product.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = json.decode(response.body);

        Map<String, dynamic> productJson;
        if (jsonData is Map && jsonData.containsKey('data')) {
          productJson = jsonData['data'];
        } else {
          productJson = jsonData;
        }

        return Product.fromJson(productJson);
      } else {
        throw HttpException(
            'Request failed with status: ${response.statusCode}',
            response.statusCode);
      }
    } catch (e) {
      print('Error updating product: $e');
      throw _handleError(e);
    }
  }

  // Delete a product
  Future<bool> deleteProduct(int id) async {
    try {
      // Make sure to check if token exists first
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) {
        throw HttpException(
            'No authentication token available. Please login first.', 401);
      }

      final response = await _client.delete(
        Uri.parse('$baseUrl/api/products/$id'),
        headers: await _getHeaders(token),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error deleting product: $e');
      throw _handleError(e);
    }
  }

  // Check in - UPDATED VERSION FOR BETTER RELIABILITY
  Future<Map<String, dynamic>> checkIn(String shiftId) async {
    try {
      // Make sure to check if token exists first
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) {
        throw HttpException(
            'No authentication token available. Please login first.', 401);
      }

      // Uncomment the line below for testing if your API isn't ready
      // return {'success': true, 'message': 'Check-in successful'};

      final response = await _client.post(
        Uri.parse('$baseUrl/api/attendance/check-in'),
        headers: await _getHeaders(token),
        body: json.encode({
          'shift_id': shiftId,
        }),
      );

      print('Check-in API response status: ${response.statusCode}');
      print('Check-in API response body: ${response.body}');

      // Handle different API response structures
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final jsonData = json.decode(response.body);
          return jsonData is Map<String, dynamic>
              ? jsonData
              : {'success': true};
        } catch (e) {
          // If response can't be parsed as JSON but status is still success
          return {'success': true};
        }
      } else {
        throw HttpException(
            'Request failed with status: ${response.statusCode}',
            response.statusCode);
      }
    } catch (e) {
      print('Error during check-in: $e');
      // Return failure response rather than throwing to handle in UI
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Check out
  Future<Map<String, dynamic>> checkOut() async {
    try {
      // Make sure to check if token exists first
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) {
        throw HttpException(
            'No authentication token available. Please login first.', 401);
      }

      final response = await _client.post(
        Uri.parse('$baseUrl/api/attendance/check-out'),
        headers: await _getHeaders(token),
      );

      print('Check-out API response status: ${response.statusCode}');
      print('Check-out API response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          return json.decode(response.body);
        } catch (e) {
          // If response can't be parsed as JSON but status is still success
          return {'success': true};
        }
      } else {
        throw HttpException(
            'Request failed with status: ${response.statusCode}',
            response.statusCode);
      }
    } catch (e) {
      print('Error during check-out: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get shifts
  Future<List<Map<String, dynamic>>> getShifts() async {
    try {
      // Make sure to check if token exists first
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) {
        throw HttpException(
            'No authentication token available. Please login first.', 401);
      }

      final response = await _client.get(
        Uri.parse('$baseUrl/api/shifts'),
        headers: await _getHeaders(token),
      );

      print('Get shifts API response status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = json.decode(response.body);

        List<dynamic> shiftsJson = [];

        // Handle different API response structures
        if (jsonData is List) {
          shiftsJson = jsonData;
        } else if (jsonData is Map &&
            jsonData.containsKey('data') &&
            jsonData['data'] is List) {
          shiftsJson = jsonData['data'];
        } else if (jsonData is Map &&
            jsonData.containsKey('shifts') &&
            jsonData['shifts'] is List) {
          shiftsJson = jsonData['shifts'];
        }

        return shiftsJson.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw HttpException(
            'Request failed with status: ${response.statusCode}',
            response.statusCode);
      }
    } catch (e) {
      print('Error fetching shifts: $e');
      throw _handleError(e);
    }
  }

  // Get attendance history
  Future<List<Map<String, dynamic>>> getAttendanceHistory() async {
    try {
      // Make sure to check if token exists first
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) {
        throw HttpException(
            'No authentication token available. Please login first.', 401);
      }

      final response = await _client.get(
        Uri.parse('$baseUrl/api/attendance/history'),
        headers: await _getHeaders(token),
      );

      print('Attendance history API response status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = json.decode(response.body);

        List<dynamic> historyJson = [];

        // Handle different API response structures
        if (jsonData is List) {
          historyJson = jsonData;
        } else if (jsonData is Map &&
            jsonData.containsKey('data') &&
            jsonData['data'] is List) {
          historyJson = jsonData['data'];
        } else if (jsonData is Map &&
            jsonData.containsKey('history') &&
            jsonData['history'] is List) {
          historyJson = jsonData['history'];
        }

        return historyJson.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw HttpException(
            'Request failed with status: ${response.statusCode}',
            response.statusCode);
      }
    } catch (e) {
      print('Error fetching attendance history: $e');
      // Return empty list instead of throwing to avoid breaking UI
      return [];
    }
  }

  // Request leave
  Future<Map<String, dynamic>> requestLeave(
      Map<String, dynamic> leaveData) async {
    try {
      // Make sure to check if token exists first
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) {
        throw HttpException(
            'No authentication token available. Please login first.', 401);
      }

      final response = await _client.post(
        Uri.parse('$baseUrl/api/leave/request'),
        headers: await _getHeaders(token),
        body: json.encode(leaveData),
      );

      print('Leave request API response status: ${response.statusCode}');
      print('Leave request API response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        throw HttpException(
            'Request failed with status: ${response.statusCode}',
            response.statusCode);
      }
    } catch (e) {
      print('Error requesting leave: $e');
      throw _handleError(e);
    }
  }

  // Get leave history
  Future<List<Map<String, dynamic>>> getLeaveHistory() async {
    try {
      // Make sure to check if token exists first
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) {
        throw HttpException(
            'No authentication token available. Please login first.', 401);
      }

      final response = await _client.get(
        Uri.parse('$baseUrl/api/leave/history'),
        headers: await _getHeaders(token),
      );

      print('Leave history API response status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = json.decode(response.body);

        List<dynamic> historyJson = [];

        // Handle different API response structures
        if (jsonData is List) {
          historyJson = jsonData;
        } else if (jsonData is Map &&
            jsonData.containsKey('data') &&
            jsonData['data'] is List) {
          historyJson = jsonData['data'];
        } else if (jsonData is Map &&
            jsonData.containsKey('history') &&
            jsonData['history'] is List) {
          historyJson = jsonData['history'];
        }

        return historyJson.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw HttpException(
            'Request failed with status: ${response.statusCode}',
            response.statusCode);
      }
    } catch (e) {
      print('Error fetching leave history: $e');
      // Return empty list instead of throwing to avoid breaking UI
      return [];
    }
  }

  // Riwayat cuti BESERTA sisa kuota bulan ini.
  //
  // getLeaveHistory() di atas hanya mengembalikan daftarnya dan membuang
  // 'sisa_cuti_bulan_ini' yang ikut dikirim backend. Kuota itu dihitung di
  // server (App\Models\Leave::getRemainingLeaves); menghitungnya ulang di app
  // berarti menyalin aturan bisnis ke dua tempat, dan itu persis yang membuat
  // jam shift di app sempat berbeda dari database.
  Future<Map<String, dynamic>> getLeaveData() async {
    try {
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) {
        throw HttpException(
            'No authentication token available. Please login first.', 401);
      }

      final response = await _client.get(
        Uri.parse('$baseUrl/api/leave/history'),
        headers: await _getHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = json.decode(response.body);
        if (jsonData is Map<String, dynamic>) {
          return {
            'sisa_cuti': jsonData['sisa_cuti_bulan_ini'],
            'data': (jsonData['data'] is List) ? jsonData['data'] : <dynamic>[],
          };
        }
        if (jsonData is List) {
          return {'sisa_cuti': null, 'data': jsonData};
        }
      }

      throw HttpException(
          'Request failed with status: ${response.statusCode}',
          response.statusCode);
    } catch (e) {
      print('Error fetching leave data: $e');
      return {'sisa_cuti': null, 'data': <dynamic>[]};
    }
  }

  // Riwayat slip gaji milik karyawan yang sedang login.
  //
  // Backend membalas {message, total_slip, data: [...]} — parser di bawah juga
  // menerima array top-level dan {history: [...]} supaya tidak pecah kalau
  // bentuknya berubah, mengikuti pola getLeaveHistory di atas.
  Future<List<Map<String, dynamic>>> getPayrollHistory() async {
    try {
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) {
        throw HttpException(
            'No authentication token available. Please login first.', 401);
      }

      final response = await _client.get(
        Uri.parse('$baseUrl/api/payroll/history'),
        headers: await _getHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = json.decode(response.body);

        List<dynamic> slipJson = [];
        if (jsonData is List) {
          slipJson = jsonData;
        } else if (jsonData is Map &&
            jsonData.containsKey('data') &&
            jsonData['data'] is List) {
          slipJson = jsonData['data'];
        } else if (jsonData is Map &&
            jsonData.containsKey('history') &&
            jsonData['history'] is List) {
          slipJson = jsonData['history'];
        }

        return slipJson.map((item) => item as Map<String, dynamic>).toList();
      }

      throw HttpException(
          'Request failed with status: ${response.statusCode}',
          response.statusCode);
    } catch (e) {
      print('Error fetching payroll history: $e');
      return [];
    }
  }

  // Get today's attendance status
  Future<Map<String, dynamic>> getAttendanceStatus() async {
    try {
      // Make sure to check if token exists first
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) {
        throw HttpException(
            'No authentication token available. Please login first.', 401);
      }

      // Get current date in API expected format
      final today = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(today);

      final response = await _client.get(
        Uri.parse('$baseUrl/api/attendance/status?date=$todayStr'),
        headers: await _getHeaders(token),
      );

      print('Attendance status API response status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final jsonData = json.decode(response.body);
          print('Attendance status response: $jsonData');
          return jsonData is Map<String, dynamic>
              ? jsonData
              : {'is_checked_in': false};
        } catch (e) {
          print('Error parsing attendance status response: $e');
          return {'is_checked_in': false};
        }
      } else {
        // Try getting from history as fallback
        return await _getAttendanceStatusFromHistory(todayStr);
      }
    } catch (e) {
      print('Error checking attendance status: $e');
      return {'is_checked_in': false, 'error': e.toString()};
    }
  }

  // Helper method to extract attendance status from history
  Future<Map<String, dynamic>> _getAttendanceStatusFromHistory(
      String dateStr) async {
    try {
      final history = await getAttendanceHistory();

      // Find entry for specified date
      final todayEntry = history.where((item) {
        final itemDate = item['date'] ?? item['created_at'] ?? '';
        return itemDate.toString().contains(dateStr);
      }).toList();

      if (todayEntry.isNotEmpty) {
        return {'is_checked_in': true, 'data': todayEntry.first};
      } else {
        return {'is_checked_in': false};
      }
    } catch (e) {
      print('Error getting attendance from history: $e');
      return {'is_checked_in': false, 'error': e.toString()};
    }
  }

  // Get products by category ID
  Future<List<Product>> getProductsByCategory(int categoryId) async {
    try {
      // Make sure to check if token exists first
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) {
        throw HttpException(
            'No authentication token available. Please login first.', 401);
      }

      // Use query parameter to filter by category_id
      final response = await _client.get(
        Uri.parse('$baseUrl/api/products?category_id=$categoryId'),
        headers: await _getHeaders(token),
      );

      print('Products by category API response status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = json.decode(response.body);
        print(
            'Products by category API response body: ${response.body.substring(0, math.min(response.body.length, 200))}...');

        List<dynamic> productsJson = [];

        // Handle different API response structures
        if (jsonData is List) {
          productsJson = jsonData;
        } else if (jsonData is Map &&
            jsonData.containsKey('data') &&
            jsonData['data'] is List) {
          productsJson = jsonData['data'];
        } else if (jsonData is Map &&
            jsonData.containsKey('products') &&
            jsonData['products'] is List) {
          productsJson = jsonData['products'];
        }

        print(
            'Parsed ${productsJson.length} products for category $categoryId from API');
        return productsJson.map((item) => Product.fromJson(item)).toList();
      } else {
        throw HttpException(
            'Request failed with status: ${response.statusCode}',
            response.statusCode);
      }
    } catch (e) {
      print('Error fetching products by category: $e');
      throw _handleError(e);
    }
  }

  // Get current timezone information
  Future<Map<String, dynamic>> getCurrentTimezone() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/timezone/current'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Timezone API response status: ${response.statusCode}');
      print('Timezone API response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final jsonData = json.decode(response.body);
          return jsonData is Map<String, dynamic>
              ? jsonData
              : {'success': false, 'error': 'Invalid response format'};
        } catch (e) {
          print('Error parsing timezone response: $e');
          return {'success': false, 'error': 'Failed to parse response'};
        }
      } else {
        return {
          'success': false,
          'error': 'Request failed with status: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Error fetching timezone: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get active location information
  Future<Map<String, dynamic>> getActiveLocation() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/location/active'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Location API response status: ${response.statusCode}');
      print('Location API response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final jsonData = json.decode(response.body);
          return jsonData is Map<String, dynamic>
              ? jsonData
              : {'success': false, 'error': 'Invalid response format'};
        } catch (e) {
          print('Error parsing location response: $e');
          return {'success': false, 'error': 'Failed to parse response'};
        }
      } else {
        return {
          'success': false,
          'error': 'Request failed with status: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Error fetching location: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}

class HttpException implements Exception {
  final String message;
  final int statusCode;

  HttpException(this.message, this.statusCode);

  @override
  String toString() => message;
}
