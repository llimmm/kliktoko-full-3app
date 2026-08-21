import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kliktoko/gudang_page/GudangModel/ProductModel.dart';
import 'package:kliktoko/theme/app_theme.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;

  ProductDetailPage({Key? key, required this.product}) : super(key: key);

  // Helper for status badge
  Widget _buildStatusBadge() {
    if (product.stock == 0) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'OUT OF STOCK',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (product.isNew) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.infoColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'NEW ARRIVAL',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'IN STOCK',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isOutOfStock = product.stock == 0;

    // Primary colors
    final Color primaryPurple = AppTheme.primaryPurple;
    final Color primaryBg = AppTheme.lightPurpleBackground;

    return Scaffold(
      backgroundColor: primaryBg,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
        title: Text(
          'Product Details',
          style: TextStyle(
            color: AppTheme.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppTheme.primaryText,
          ),
          onPressed: () => Get.back(),
        ),
        // Removed share button from actions
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Stack(
              children: [
                Container(
                  width: screenWidth,
                  height: screenHeight * 0.4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor,
                  ),
                  child: product.image != null && product.image!.isNotEmpty
                      ? Image.network(
                          product.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading image: $error');
                            return Container(
                              color: primaryPurple.withValues(alpha: 0.3),
                              child: Center(
                                child: Icon(
                                  Icons.checkroom,
                                  size: 80,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: primaryPurple,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: primaryPurple.withValues(alpha: 0.3),
                          child: Center(
                            child: Icon(
                              Icons.checkroom,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
                // Overlay for out of stock
                if (isOutOfStock)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.7),
                      child: Center(
                        child: Text(
                          'OUT OF STOCK',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Product Code
                if (product.code != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Code: ${product.code}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Product Info Box
            Container(
              width: screenWidth,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusBadge(),
                    ],
                  ),
                  SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rp ${product.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryPurple,
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.borderColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Size: ${product.size}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 16),

                  // Stock Information
                  Row(
                    children: [
                      Icon(
                        isOutOfStock
                            ? Icons.inventory_2_outlined
                            : Icons.inventory_2,
                        color: isOutOfStock ? AppTheme.errorColor : primaryPurple,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        isOutOfStock
                            ? 'Out of Stock'
                            : '${product.stock} items available',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isOutOfStock ? AppTheme.errorColor : AppTheme.primaryText,
                        ),
                      ),
                    ],
                  ),

                  // Creation time if available
                  if (product.createdAt != null) ...[
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: AppTheme.secondaryText,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Added: ${_formatDate(product.createdAt!)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Last update time if available
                  if (product.updatedAt != null) ...[
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.update,
                          color: AppTheme.secondaryText,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Updated: ${_formatDate(product.updatedAt!)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Description Section
            if (product.description != null && product.description!.isNotEmpty)
              Container(
                width: screenWidth,
                margin: EdgeInsets.only(top: 16),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      product.description!,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.primaryText,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

            // Bottom padding
            SizedBox(height: 100),
          ],
        ),
      ),
      // Removed bottom navigation bar with edit and update stock actions
    );
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Removed _showUpdateStockDialog method
}
