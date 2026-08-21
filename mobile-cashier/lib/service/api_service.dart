import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../models/product.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../config/api_config.dart';

class ApiService {
  final String baseUrl;
  String? _token;
  late final http.Client _client;

  static const String imageBaseUrl = ApiConfig.imageBaseUrl;
  static const String TOKEN_KEY = 'auth_token';
  static const String USER_DATA_KEY = 'user_data';

  ApiService({required this.baseUrl}) {
    // Configure HTTP client with better timeout and TLS settings
    _client = http.Client();
    _loadSavedToken();
  }

  Future<void> _loadSavedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(TOKEN_KEY);

      if (savedToken != null && savedToken.isNotEmpty) {
        _token = savedToken;
        if (kDebugMode) {
          print(
              'ApiService: Token loaded from storage: ${_getRedactedToken()}');
        }
      } else if (kDebugMode) {
        print('ApiService: No saved token found');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiService: Error loading saved token: $e');
      }
    }
  }

  // Helper method to safely show token in logs
  String _getRedactedToken() {
    if (_token == null) return 'null';
    if (_token!.length <= 10) return '${_token!}...';
    return '${_token!.substring(0, 10)}...';
  }

  // Menyimpan token ke penyimpanan lokal
  Future<void> _saveToken(String token,
      {Map<String, dynamic>? userData}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(TOKEN_KEY, token);

      // Save user data if provided
      if (userData != null) {
        await prefs.setString(USER_DATA_KEY, jsonEncode(userData));
      }

      if (kDebugMode) {
        print('ApiService: Token saved to storage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiService: Error saving token: $e');
      }
    }
  }

  // Menghapus token dari penyimpanan lokal
  Future<void> logout() async {
    _token = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(TOKEN_KEY);
      await prefs.remove(USER_DATA_KEY);

      if (kDebugMode) {
        print('ApiService: Token and user data removed from storage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiService: Error removing token: $e');
      }
    }
  }

  String? get token => _token;

  static String getFullImageUrl(String? imagePath) {
    if (kDebugMode) {
      print('Getting full image URL for path: $imagePath');
    }

    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }

    // If already a full URL, return as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      if (kDebugMode) {
        print('  → Already a full URL: $imagePath');
      }
      return imagePath;
    }

    // Handle paths that start with /storage/
    if (imagePath.startsWith('/storage/')) {
      final fullUrl = '${ApiConfig.baseUrl}$imagePath';
      if (kDebugMode) {
        print('  → Converting /storage/ path to: $fullUrl');
      }
      return fullUrl;
    }

    // If not already prefixed with 'storage/', add it
    String cleanPath = imagePath;
    if (!cleanPath.startsWith('storage/') &&
        !cleanPath.startsWith('/storage/')) {
      // First remove any leading slash
      cleanPath =
          cleanPath.startsWith('/') ? cleanPath.substring(1) : cleanPath;

      // Then add 'storage/' prefix if needed
      if (!cleanPath.contains('storage/')) {
        cleanPath = 'storage/$cleanPath';
      }
    }

    // Use the static base URL, not the instance one
    final baseUrl = ApiConfig.baseUrl;
    final baseWithoutTrailingSlash = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final pathWithLeadingSlash =
        cleanPath.startsWith('/') ? cleanPath : '/$cleanPath';
    final fullUrl = '$baseWithoutTrailingSlash$pathWithLeadingSlash';

    if (kDebugMode) {
      print('  → Created full URL: $fullUrl');
    }

    return fullUrl;
  }

  Future<Map<String, String>> _getHeaders() async {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) h['Authorization'] = 'Bearer $_token';
    return h;
  }

  Future<void> login(String username, String password) async {
    if (kDebugMode) {
      print('Attempting login for user: $username');
      print('Login URL: $baseUrl/api/login');
    }

    final uri = Uri.parse('$baseUrl/api/login');

    // Logout terlebih dahulu untuk memastikan token baru
    await logout();

    try {
      // Coba berbagai kemungkinan format body request untuk login

      // Format 1: Menggunakan name sebagai username
      final bodyFormat1 = {
        'name': username,
        'password': password,
      };

      // Format 2: Menggunakan username sebagai field name
      final bodyFormat2 = {
        'username': username,
        'password': password,
      };

      // Format 3: Menggunakan email sebagai field name
      final bodyFormat3 = {
        'email': username, // Jika username mungkin sebenarnya adalah email
        'password': password,
      };

      if (kDebugMode) {
        print('Trying login with format 1: $bodyFormat1');
      }

      // Coba format pertama
      var resp = await _client.post(
        uri,
        headers: await _getHeaders(),
        body: jsonEncode(bodyFormat1),
      );

      // Jika format pertama gagal dengan 401 atau 422, coba format kedua
      if (resp.statusCode != 200 &&
          (resp.statusCode == 401 || resp.statusCode == 422)) {
        if (kDebugMode) {
          print('Format 1 failed, trying format 2: $bodyFormat2');
        }

        resp = await _client.post(
          uri,
          headers: await _getHeaders(),
          body: jsonEncode(bodyFormat2),
        );
      }

      // Jika format kedua juga gagal, coba format ketiga
      if (resp.statusCode != 200 &&
          (resp.statusCode == 401 || resp.statusCode == 422)) {
        if (kDebugMode) {
          print('Format 2 failed, trying format 3: $bodyFormat3');
        }

        resp = await _client.post(
          uri,
          headers: await _getHeaders(),
          body: jsonEncode(bodyFormat3),
        );
      }

      // Jika format ketiga juga gagal, coba format keempat (tanpa wrapper data)
      if (resp.statusCode != 200 &&
          (resp.statusCode == 401 || resp.statusCode == 422)) {
        if (kDebugMode) {
          print(
              'Format 3 failed, trying direct format with all possible fields');
        }

        // Format 4: Mencoba semua field sekaligus tanpa wrapper
        final bodyFormat4 = {
          'name': username,
          'username': username,
          'email': username,
          'password': password,
        };

        resp = await _client.post(
          uri,
          headers: await _getHeaders(),
          body: jsonEncode(bodyFormat4),
        );
      }

      // Jika format keempat juga gagal, coba format kelima dengan basic authentication
      if (resp.statusCode != 200 &&
          (resp.statusCode == 401 || resp.statusCode == 422)) {
        if (kDebugMode) {
          print('Format 4 failed, trying with basic authentication');
        }

        // Encode username:password for Basic Auth
        final basicAuth =
            'Basic ${base64Encode(utf8.encode('$username:$password'))}';

        final headers = await _getHeaders();
        headers['Authorization'] = basicAuth;

        resp = await _client.post(
          uri,
          headers: headers,
          body: jsonEncode(bodyFormat1), // Still include body data
        );
      }

      if (kDebugMode) {
        print('Login response status: ${resp.statusCode}');
        print('Login response body: ${resp.body}');
      }

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;

        if (kDebugMode) {
          print('Login response data structure: ${data.keys.join(', ')}');
        }

        // Coba temukan token di berbagai kemungkinan lokasi dalam response
        String? newToken = data['access_token'] ??
            data['token'] ??
            data['data']?['token'] ??
            data['data']?['access_token'];

        // Cek juga untuk format non-standar
        if (newToken == null) {
          // Coba parse dari struktur data yang berbeda
          if (data.containsKey('data') && data['data'] is Map) {
            final dataObj = data['data'] as Map<String, dynamic>;
            if (kDebugMode) {
              print(
                  'Trying to extract token from data object: ${dataObj.keys.join(', ')}');
            }
            newToken = dataObj['access_token'] ??
                dataObj['token'] ??
                dataObj['auth_token'];
          }

          // Cek semua key di response untuk menemukan token
          for (final key in data.keys) {
            if (key.toLowerCase().contains('token') && data[key] is String) {
              if (kDebugMode) {
                print('Found potential token in field: $key');
              }
              newToken = data[key] as String;
              break;
            }
          }

          // Coba cek apakah respons berisi string token langsung
          if (newToken == null &&
              resp.body.length < 500 &&
              resp.body.startsWith('"') &&
              resp.body.endsWith('"')) {
            // Mungkin respons API langsung mengembalikan token dalam bentuk string
            newToken = resp.body.substring(1, resp.body.length - 1);
            if (kDebugMode) {
              print('Using direct response string as token');
            }
          }
        }

        if (newToken == null || newToken.isEmpty) {
          throw Exception('Token tidak ditemukan dalam respons');
        }

        // Extract user data if available in the response
        Map<String, dynamic>? userData;
        if (data.containsKey('user') && data['user'] is Map) {
          userData = Map<String, dynamic>.from(data['user']);
        } else if (data.containsKey('data') &&
            data['data'] is Map &&
            data['data'].containsKey('user') &&
            data['data']['user'] is Map) {
          userData = Map<String, dynamic>.from(data['data']['user']);
        }

        // Simpan token
        _token = newToken;
        await _saveToken(newToken, userData: userData);

        if (kDebugMode) {
          print(
              'Login successful, token received: ${newToken.substring(0, min(10, newToken.length))}...');
          if (userData != null) {
            print(
                'User data saved: ${userData.containsKey('name') ? userData['name'] : 'unknown user'}');
          }
        }
      } else if (resp.statusCode == 401) {
        if (kDebugMode) {
          print('Login failed with 401 Unauthorized');
          print('Response body: ${resp.body}');
        }
        throw Exception('Login gagal: Username atau password salah');
      } else if (resp.statusCode == 422) {
        // Coba parse pesan error
        try {
          final errorData = json.decode(resp.body);
          if (kDebugMode) {
            print('Login failed with 422 Validation Error');
            print('Error data: $errorData');
          }
          final errorMsg = errorData['message'] ??
              errorData['error'] ??
              (errorData['errors'] != null
                  ? errorData['errors'].toString()
                  : null) ??
              'Data tidak valid';
          throw Exception('Login gagal: $errorMsg');
        } catch (_) {
          throw Exception('Login gagal: Data tidak valid');
        }
      } else {
        if (kDebugMode) {
          print('Login failed with status code: ${resp.statusCode}');
          print('Response body: ${resp.body}');
        }
        throw Exception('Login gagal: Error ${resp.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Login exception: $e');
      }
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Login gagal: $e');
      }
    }
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    if (_token == null) {
      throw Exception('Unauthorized: Token tidak tersedia');
    }

    final uri = Uri.parse('$baseUrl/api/products?category=$category');

    if (kDebugMode) {
      print('Loading products for category: $category');
      print('Request URL: $uri');
    }

    try {
      final headers = await _getHeaders();
      final resp = await _client.get(uri, headers: headers);

      if (kDebugMode) {
        print('Product response status: ${resp.statusCode}');
      }

      if (resp.statusCode == 200) {
        try {
          final dynamic decodedResponse = json.decode(resp.body);
          List<dynamic> arr = [];

          if (decodedResponse is Map<String, dynamic>) {
            if (decodedResponse.containsKey('data') &&
                decodedResponse['data'] is List) {
              arr = decodedResponse['data'] as List<dynamic>;
            } else if (decodedResponse.containsKey('products') &&
                decodedResponse['products'] is List) {
              arr = decodedResponse['products'] as List<dynamic>;
            }
          } else if (decodedResponse is List) {
            arr = decodedResponse;
          }

          if (kDebugMode) {
            print('Found ${arr.length} products in response');
            if (arr.isNotEmpty) {
              // Print the first item to debug
              print('First product raw data: ${json.encode(arr.first)}');

              // Check if the image_path field exists in the response
              final firstItem = arr.first as Map<String, dynamic>;
              if (firstItem.containsKey('image_path')) {
                print('API response contains image_path field!');
              }
              if (firstItem.containsKey('image')) {
                print('API response contains image field!');
              }
              if (firstItem.containsKey('image_url')) {
                print('API response contains image_url field!');
              }
            }
          }

          final products = arr.map((item) {
            // Convert item to Product model
            final Map<String, dynamic> productJson =
                item as Map<String, dynamic>;

            // Create product from the JSON data
            final product = Product.fromJson(productJson);

            if (kDebugMode) {
              print('Processed product: ${product.name}');
              print('  - Raw image path: ${product.imagePath}');
              print('  - Raw imageUrl: ${product.imageUrl}');
              print('  - Final image URL: ${product.image}');
            }

            return product;
          }).toList();

          return products;
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing product response: $e');
          }
          return [];
        }
      }

      if (resp.statusCode == 401) {
        // Token tidak valid, hapus token dan arahkan ke login
        await logout();
        throw Exception('Unauthorized: Silakan login kembali');
      }

      throw Exception('Request gagal: ${resp.statusCode}');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Gagal mengambil produk: $e');
      }
    }
  }

  Future<List<Product>> getAllProducts() async {
    if (_token == null) {
      throw Exception('Unauthorized: Token tidak tersedia');
    }

    final uri = Uri.parse('$baseUrl/api/products');

    if (kDebugMode) {
      print('Loading all products');
      print('Request URL: $uri');
    }

    try {
      final headers = await _getHeaders();
      final resp = await _client.get(uri, headers: headers);

      if (kDebugMode) {
        print('All products response status: ${resp.statusCode}');
      }

      if (resp.statusCode == 200) {
        try {
          final dynamic decodedResponse = json.decode(resp.body);
          List<dynamic> arr = [];

          if (decodedResponse is Map<String, dynamic>) {
            if (decodedResponse.containsKey('data') &&
                decodedResponse['data'] is List) {
              arr = decodedResponse['data'] as List<dynamic>;
            } else if (decodedResponse.containsKey('products') &&
                decodedResponse['products'] is List) {
              arr = decodedResponse['products'] as List<dynamic>;
            }
          } else if (decodedResponse is List) {
            arr = decodedResponse;
          }

          if (kDebugMode) {
            print('Found ${arr.length} products in response');
          }

          final products = arr.map((item) {
            final Map<String, dynamic> productJson =
                item as Map<String, dynamic>;
            return Product.fromJson(productJson);
          }).toList();

          return products;
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing all products response: $e');
          }
          return [];
        }
      }

      if (resp.statusCode == 401) {
        await logout();
        throw Exception('Unauthorized: Silakan login kembali');
      }

      throw Exception('Request gagal: ${resp.statusCode}');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Gagal mengambil semua produk: $e');
      }
    }
  }

  // Update product stock after order
  Future<bool> updateProductStock(Product product, int newStock) async {
    if (_token == null) {
      throw Exception('Unauthorized: Token tidak tersedia');
    }

    final uri = Uri.parse('$baseUrl/api/products/${product.id}');

    final body = {
      'name': product.name,
      'price': product.price,
      'stock_quantity': newStock,
      'image_path': product.imagePath,
      'category_id': product.categoryId,
      'size_id': product.sizeId,
      'code': product.code,
    };

    final headers = await _getHeaders();
    final response = await _client.put(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
          'Gagal update stock: \\${response.statusCode} - \\${response.body}');
    }
  }

  // Fetch all karyawan (users with role karyawan)
  Future<List<User>> fetchKaryawan() async {
    // Check if token is available
    if (_token == null) {
      throw Exception(
          'Unauthorized: Token tidak tersedia. Silakan login terlebih dahulu.');
    }

    try {
      final uri = Uri.parse('$baseUrl/api/users');
      final headers = await _getHeaders();
      debugPrint('🔍 Fetching karyawan from: $uri');
      debugPrint('🔑 Headers: $headers');

      final resp = await _client.get(uri, headers: headers);
      debugPrint('📡 Response status: ${resp.statusCode}');
      debugPrint(
          '📄 Response body (first 500 chars): ${resp.body.length > 500 ? resp.body.substring(0, 500) + "..." : resp.body}');

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        debugPrint('📊 Parsed data: $data');

        // Parse response structure based on the API response format
        List<dynamic> usersJson = [];
        if (data['data'] != null && data['data']['data'] != null) {
          usersJson = data['data']['data'];
        } else if (data['data'] != null && data['data'] is List) {
          usersJson = data['data'];
        } else if (data is List) {
          usersJson = data;
        }

        debugPrint('👥 Users JSON count: ${usersJson.length}');

        if (usersJson.isNotEmpty) {
          final allUsers = usersJson.map((e) => User.fromJson(e)).toList();
          debugPrint(
              '👤 All users: ${allUsers.map((u) => '${u.name} (${u.role})').toList()}');

          // Filter users with role 'karyawan'
          final karyawanUsers =
              allUsers.where((u) => u.role == 'karyawan').toList();
          debugPrint(
              '💼 Karyawan users: ${karyawanUsers.map((u) => '${u.name} (ID: ${u.id})').toList()}');

          if (karyawanUsers.isNotEmpty) {
            debugPrint(
                '✅ Successfully found ${karyawanUsers.length} karyawan from API');
            return karyawanUsers;
          } else {
            debugPrint('⚠️ No users with role "karyawan" found in response');
            // Return all users if no specific karyawan role found
            return allUsers;
          }
        } else {
          debugPrint('⚠️ Empty users list from API');
          throw Exception('Tidak ada data karyawan yang ditemukan');
        }
      } else if (resp.statusCode == 401) {
        debugPrint('❌ Unauthorized: Token mungkin expired atau tidak valid');
        throw Exception(
            'Unauthorized: Token tidak valid. Silakan login kembali.');
      } else {
        debugPrint('❌ API error: ${resp.statusCode}');
        throw Exception('Gagal mengambil data karyawan: ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching karyawan: $e');
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Gagal mengambil data karyawan: $e');
      }
    }
  }

  // Post sales transaksi
  Future<bool> postSales({
    required int userId,
    required String paymentMethod,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final uri = Uri.parse('$baseUrl/api/sales');
    final headers = await _getHeaders();
    final body = {
      'user_id': userId,
      'payment_method': paymentMethod,
      'notes': notes ?? '',
      'items': items,
    };
    final resp =
        await _client.post(uri, headers: headers, body: jsonEncode(body));
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return true;
    } else {
      throw Exception('Gagal transaksi: \\${resp.statusCode} - \\${resp.body}');
    }
  }

  // Get sales history
  Future<List<Map<String, dynamic>>> getSalesHistory() async {
    if (_token == null) {
      throw Exception('Unauthorized: Token tidak tersedia');
    }

    final uri = Uri.parse('$baseUrl/api/sales-data');

    if (kDebugMode) {
      print('Loading sales history');
      print('Request URL: $uri');
    }

    try {
      final headers = await _getHeaders();
      final resp = await _client.get(uri, headers: headers);

      if (kDebugMode) {
        print('Sales history response status: ${resp.statusCode}');
      }

      if (resp.statusCode == 200) {
        final decodedResponse = json.decode(resp.body);
        if (decodedResponse['data'] != null &&
            decodedResponse['data'] is List) {
          return List<Map<String, dynamic>>.from(decodedResponse['data']);
        }
        return [];
      }

      if (resp.statusCode == 401) {
        await logout();
        throw Exception('Unauthorized: Silakan login kembali');
      }

      throw Exception('Request gagal: ${resp.statusCode}');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Gagal mengambil riwayat penjualan: $e');
      }
    }
  }
}
