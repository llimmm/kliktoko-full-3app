import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kliktoko/gudang_page/GudangModel/ProductModel.dart';
import 'package:kliktoko/gudang_page/GudangModel/CategoryModel.dart';
import 'package:kliktoko/gudang_page/GudangControllers/GudangController.dart';
import 'package:kliktoko/ReusablePage/detailpage.dart';
import 'package:kliktoko/gudang_page/GudangServices/CategoryService.dart';
import 'package:kliktoko/attendance_page/AttendanceController.dart';
import 'package:kliktoko/theme/app_theme.dart';

class CategoryPage extends StatefulWidget {
  final String categoryName;

  const CategoryPage({Key? key, required this.categoryName}) : super(key: key);

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final GudangController controller = Get.find<GudangController>();
  final CategoryService _categoryService = CategoryService();

  bool isLoading = true;
  List<Product> categoryProducts = [];
  String errorMessage = '';
  Category? category;

  @override
  void initState() {
    super.initState();
    // Load products for this specific category
    loadCategoryProducts();
  }

  // Load products by category name
  Future<void> loadCategoryProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Refresh radius location check first (if attendance controller is available)
      try {
        if (Get.isRegistered<AttendanceController>()) {
          final attendanceController = Get.find<AttendanceController>();
          await attendanceController.refreshLocation();
        }
      } catch (e) {
        print('Error refreshing location: $e');
      }

      // First get the category object by name
      category = await _categoryService.getCategoryByName(widget.categoryName);

      if (category != null && category!.id > 0) {
        // Now get products for this category ID
        categoryProducts =
            await _categoryService.getProductsByCategory(category!.id);
        print(
            'Loaded ${categoryProducts.length} products for category ${category!.name}');
      } else {
        // If category not found by exact name, try using controller's filter as fallback
        controller.filterByCategory(widget.categoryName);
        categoryProducts = controller.filteredItems;
        print(
            'Using filtered items. Found ${categoryProducts.length} products');
      }
    } catch (e) {
      print('Error loading category products: $e');
      errorMessage = 'Failed to load products: $e';
      // Fallback to local filtering as last resort
      controller.filterByCategory(widget.categoryName);
      categoryProducts = controller.filteredItems;
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Method to navigate to product detail page
  void _navigateToProductDetail(Product product) {
    Get.to(() => ProductDetailPage(product: product));
  }

  @override
  Widget build(BuildContext context) {
    // Purple color constant
    final Color primaryPurple = AppTheme.primaryPurple;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive paddings and sizes
    final horizontalPadding = screenWidth * 0.04;
    final verticalPadding = screenHeight * 0.02;

    // Calculate responsive grid items for different screen sizes
    final crossAxisCount = screenWidth < 360 ? 1 : 2;
    final childAspectRatio = screenWidth < 360 ? 0.8 : 0.7;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
        title: Text(
          widget.categoryName,
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
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: primaryPurple,
              ),
            )
          : errorMessage.isNotEmpty && categoryProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppTheme.errorColor,
                      ),
                      SizedBox(height: 16),
                      Text(
                        errorMessage,
                        style: TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: loadCategoryProducts,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Try Again',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              : categoryProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: AppTheme.lightText,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No products found in this category',
                            style: TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadCategoryProducts,
                      color: primaryPurple,
                      child: Padding(
                        padding: EdgeInsets.all(horizontalPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category title and count
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: verticalPadding),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Products in ${widget.categoryName}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${categoryProducts.length} items',
                                    style: TextStyle(
                                      color: AppTheme.secondaryText,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Products grid
                            Expanded(
                              child: GridView.builder(
                                padding: EdgeInsets.only(bottom: 20),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: childAspectRatio,
                                  crossAxisSpacing: horizontalPadding,
                                  mainAxisSpacing: verticalPadding,
                                ),
                                itemCount: categoryProducts.length,
                                itemBuilder: (context, index) {
                                  final item = categoryProducts[index];
                                  return _buildProductItem(item);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildProductItem(Product item) {
    final bool isOutOfStock = item.stock == 0;
    final bool isNew = item.isNew;
    final Color primaryPurple = AppTheme.primaryPurple;

    return GestureDetector(
      onTap: () => _navigateToProductDetail(item),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppTheme.borderColor,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: item.image != null && item.image!.isNotEmpty
                          ? Image.network(
                              item.image!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: primaryPurple,
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading image: $error');
                                return Container(
                                  color: primaryPurple.withValues(alpha: 0.7),
                                  child: Center(
                                    child: Icon(
                                      Icons.checkroom,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            )
                          // Dulu Image.asset('assets/images/clothes.jpg'),
                          // padahal berkas itu tidak pernah ada di assets/ —
                          // tiap render melempar exception yang lalu ditelan
                          // errorBuilder. Placeholder-nya dipakai langsung.
                          : Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: primaryPurple.withValues(alpha: 0.7),
                              child: const Center(
                                child: Icon(
                                  Icons.checkroom,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  ),
                  if (isOutOfStock)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.black.withValues(alpha: 0.7),
                        ),
                        child: Center(
                          child: Text(
                            'SOLD OUT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (!isOutOfStock && item.stock > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          // Badge ini muncul justru saat stok ADA, jadi merah
                          // di sini menyampaikan hal yang keliru. Warna status
                          // hanya untuk keadaan, bukan hiasan.
                          color: AppTheme.primaryPurple,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${item.stock}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (isNew)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCardBackground,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (item.code != null)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.code!,
                          style: TextStyle(
                            color: AppTheme.primaryText,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${item.name} / ${item.size}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Rp.${item.price.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
