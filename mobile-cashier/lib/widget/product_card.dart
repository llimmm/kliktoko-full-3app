import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final bool isSmallSize;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.isSmallSize = false,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Debug print image information
    if (kDebugMode) {
      print('Product: ${product.name}');
      print('  - imageUrl: ${product.imageUrl}');
      print('  - imagePath: ${product.imagePath}');
      print('  - image getter result: ${product.image}');
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias, // Clip any overflowing content
        margin: EdgeInsets.all(isSmallSize ? 4 : 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Product Image
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: KtColor.neutral100,
                ),
                child: _buildProductImage(),
              ),
            ),

            // Product Info
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isSmallSize ? 6.0 : 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallSize ? 12 : 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isSmallSize ? 2 : 4),
                  Text(
                    formatter.format(product.price),
                    style: TextStyle(
                      color: KtColor.neutral600,
                      fontSize: isSmallSize ? 10 : 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    // If we have no image URL at all, show a placeholder
    if (product.image == null || product.image!.isEmpty) {
      return _buildPlaceholderImage();
    }

    // Try to load the image
    return AspectRatio(
      aspectRatio: 1.0, // Square aspect ratio
      child: ClipRRect(
        child: Image.network(
          product.image!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Log the error details in debug mode only
            if (kDebugMode) {
              print('Error loading image for ${product.name}: $error');
            }

            // Show a better error state with more information
            return _buildImageErrorWidget();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;

            // Show a progress indicator while loading
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: AlwaysStoppedAnimation<Color>(KtColor.primary),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 40,
              color: KtColor.neutral400,
            ),
            const SizedBox(height: 4),
            Text(
              'No Image',
              style: TextStyle(
                fontSize: 12,
                color: KtColor.neutral500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 40,
              color: KtColor.neutral400,
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: KtColor.neutral600,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
