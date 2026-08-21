import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kliktoko/storage/storage_service.dart';
import 'package:kliktoko/config/api_config.dart';

class SizeService {
  static const String baseUrl = ApiConfig.baseUrl;
  
  // Singleton pattern
  static final SizeService _instance = SizeService._internal();
  factory SizeService() => _instance;
  SizeService._internal();

  final http.Client _client = http.Client();
  final StorageService _storageService = StorageService();

  // Get all sizes from the API to check the correct mapping
  Future<List<Map<String, dynamic>>> getSizes() async {
    try {
      // Make sure to check if token exists first
      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('No authentication token available. Please login first.');
      }
      
      final response = await _client.get(
        Uri.parse('$baseUrl/api/sizes'),
        headers: await _getHeaders(token),
      );

      print('Sizes API response status: ${response.statusCode}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = json.decode(response.body);
        print('Sizes API response body: ${response.body.substring(0, response.body.length < 200 ? response.body.length : 200)}...');
        
        List<dynamic> sizesJson = [];
        
        // Handle different API response structures
        if (jsonData is List) {
          sizesJson = jsonData;
        } else if (jsonData is Map && jsonData.containsKey('data') && jsonData['data'] is List) {
          sizesJson = jsonData['data'];
        } else if (jsonData is Map && jsonData.containsKey('sizes') && jsonData['sizes'] is List) {
          sizesJson = jsonData['sizes'];
        }
        
        print('Parsed ${sizesJson.length} sizes from API');
        
        // Convert to a list of maps
        return sizesJson.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to fetch sizes. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching sizes: $e');
      return [];
    }
  }
  
  // Method to get a size name by ID - useful for debugging
  Future<String?> getSizeNameById(int sizeId) async {
    try {
      final sizes = await getSizes();
      
      // Find the size with matching ID
      for (var size in sizes) {
        if (size['id'] == sizeId) {
          return size['name'] as String?;
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting size name: $e');
      return null;
    }
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