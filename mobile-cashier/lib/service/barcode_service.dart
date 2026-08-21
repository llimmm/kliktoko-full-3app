import 'package:flutter/material.dart';
import '../models/product.dart';

class BarcodeService {
  static final BarcodeService _instance = BarcodeService._internal();
  factory BarcodeService() => _instance;
  BarcodeService._internal();

  // Find product by barcode
  Product? findProductByBarcode(String barcode, List<Product> products) {
    try {
      debugPrint('🔍 Searching for barcode: $barcode');
      debugPrint('📦 Available products: ${products.length}');

      // Clean barcode (remove spaces, dashes, etc.)
      String cleanBarcode = barcode.trim().replaceAll(RegExp(r'[-\s]'), '');
      debugPrint('🧹 Cleaned barcode: $cleanBarcode');

      // First try exact match with barcode field
      for (Product product in products) {
        if (product.barcode == barcode || product.barcode == cleanBarcode) {
          debugPrint('✅ Found by barcode field: ${product.name}');
          return product;
        }
      }

      // Then try ISBN barcode match
      for (Product product in products) {
        if (product.isbnBarcode == barcode ||
            product.isbnBarcode == cleanBarcode) {
          debugPrint('✅ Found by ISBN barcode: ${product.name}');
          return product;
        }
      }

      // Then try product ID match (in case barcode is just the ID)
      for (Product product in products) {
        if (product.id == barcode || product.id == cleanBarcode) {
          debugPrint('✅ Found by product ID: ${product.name}');
          return product;
        }
      }

      // Then try code field match (for PRD-71232 format)
      for (Product product in products) {
        if (product.code == barcode || product.code == cleanBarcode) {
          debugPrint('✅ Found by code field: ${product.name}');
          return product;
        }
      }

      // Try partial match for code field (in case of format differences)
      for (Product product in products) {
        if (product.code.isNotEmpty) {
          // Try matching without prefix (e.g., "71232" from "PRD-71232")
          String codeWithoutPrefix =
              product.code.replaceAll(RegExp(r'^[A-Z]+-'), '');
          if (codeWithoutPrefix == cleanBarcode ||
              codeWithoutPrefix == barcode) {
            debugPrint(
                '✅ Found by code field (partial match): ${product.name}');
            return product;
          }

          // Try matching with prefix
          if (product.code.contains(cleanBarcode) ||
              product.code.contains(barcode)) {
            debugPrint(
                '✅ Found by code field (contains match): ${product.name}');
            return product;
          }
        }
      }

      // Debug: Print all product barcodes for troubleshooting
      debugPrint('🔍 Debug - All product barcodes:');
      for (Product product in products) {
        debugPrint(
            '  ${product.name}: ID=${product.id}, Code=${product.code}, Barcode=${product.barcode}, ISBN=${product.isbnBarcode}');
      }

      debugPrint('❌ Product not found for barcode: $barcode');
      return null;
    } catch (e) {
      debugPrint('Error finding product by barcode: $e');
      return null;
    }
  }

  // Validate barcode format
  bool isValidBarcode(String barcode) {
    if (barcode.isEmpty) return false;

    // Accept alphanumeric codes (for PRD-71232 format)
    if (RegExp(r'^[A-Z0-9\-]+$').hasMatch(barcode)) {
      return true;
    }

    // Check if it's numeric (most barcodes are)
    if (RegExp(r'^\d+$').hasMatch(barcode)) {
      // Check length (ISBN-13 = 13 digits, EAN-13 = 13 digits, etc.)
      if (barcode.length < 8 || barcode.length > 13) return false;
      return true;
    }

    return false;
  }

  // Generate barcode for product
  String generateBarcodeForProduct(Product product) {
    return product.isbnBarcode;
  }

  // Get barcode type
  String getBarcodeType(String barcode) {
    if (barcode.length == 13) return 'ISBN-13/EAN-13';
    if (barcode.length == 12) return 'UPC-A';
    if (barcode.length == 8) return 'EAN-8';
    return 'Unknown';
  }

  // Validate ISBN-13 barcode
  bool isValidISBN13(String barcode) {
    if (barcode.length != 13) return false;

    try {
      int sum = 0;
      for (int i = 0; i < 12; i++) {
        int digit = int.parse(barcode[i]);
        sum += digit * (i % 2 == 0 ? 1 : 3);
      }

      int checkDigit = (10 - (sum % 10)) % 10;
      return checkDigit == int.parse(barcode[12]);
    } catch (e) {
      return false;
    }
  }
}
