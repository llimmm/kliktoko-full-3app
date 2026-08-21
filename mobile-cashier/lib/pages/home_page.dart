import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'package:provider/provider.dart';
import '../widget/size_picker_sheet.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:scan_gun/scan_gun.dart';
import '../controllers/product_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/category_controller.dart';

import '../widget/product_card.dart';
import '../widget/order_item_widget.dart';
import '../service/barcode_service.dart';
import 'payment_confirmation_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Add view type state variable at class level to persist it
  bool _isGridView = true;
  // Add a focus node to control the search field focus
  final FocusNode _searchFocusNode = FocusNode();
  // Add scanner variables
  bool _scannerActive = true;
  final BarcodeService _barcodeService = BarcodeService();

  @override
  void initState() {
    super.initState();

    // Scanner works in background only - no focus management needed

    // Ensure focus is properly managed
    _searchFocusNode.addListener(() {
      if (kDebugMode) {
        print('Search focus changed: ${_searchFocusNode.hasFocus}');
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    // Dispose the focus node when the page is disposed
    _searchFocusNode.dispose();
    // No focus management needed - scanner works in background
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    final authController = Provider.of<AuthController>(context, listen: false);

    if (!authController.isLoggedIn) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    if (!mounted) return;
    final categoryController =
        Provider.of<CategoryController>(context, listen: false);
    await categoryController.loadCategories();

    if (!mounted) return;
    final productController =
        Provider.of<ProductController>(context, listen: false);
    try {
      if (kDebugMode) {
        print('Loading initial products data...');
      }

      await productController
          .loadProductsByCategory(categoryController.selectedCategory);

      if (!mounted) return;

      if (productController.error != null &&
          productController.error!.contains('Unauthorized')) {
        _handleUnauthorized();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading initial data: $e');
      }

      if (!mounted) return;

      if (e.toString().contains('Unauthorized')) {
        _handleUnauthorized();
      }
    }
  }

  void _handleUnauthorized() {
    if (!mounted) return;
    // Handle unauthorized access
  }

  void _onScanResult(String result) {
    if (result.isNotEmpty) {
      debugPrint('🔍 Homepage Scanner detected: $result');

      try {
        final orderController =
            Provider.of<OrderController>(context, listen: false);
        final productController =
            Provider.of<ProductController>(context, listen: false);

        // Get available products
        final products = productController.products;
        debugPrint('📦 Available products count: ${products.length}');

        // Barcode menempel pada produk, bukan pada ukuran. Untuk produk
        // multi-ukuran, memindai saja tidak cukup — ukurannya tetap harus
        // dipilih, kalau tidak backend menolak transaksinya.
        final product = _barcodeService.findProductByBarcode(result, products);
        if (product != null) {
          addProductWithSize(context, orderController, product);
          debugPrint('✅ Product found and added: ${product.name}');
          // Removed snackbar notification as requested
        } else {
          debugPrint('❌ Product not found after successful add');
          // Removed snackbar notification as requested
        }
      } catch (e) {
        debugPrint('❌ Error adding product to order: $e');
        // Removed snackbar notification as requested
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productController = Provider.of<ProductController>(context);
    final orderController = Provider.of<OrderController>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final orderPanelWidth =
        screenWidth > 1100 ? 300.0 : (screenWidth > 800 ? 250.0 : 0.0);
    final showOrderPanel = screenWidth > 800;

    return ScanMonitorWidget(
      textFiledNode: null,
      focusLooper: _scannerActive,
      onSubmit: _onScanResult,
      childBuilder: (context) {
        return GestureDetector(
          // Add gesture detector to dismiss keyboard when tapping anywhere else
          onTap: () {
            // Dismiss keyboard when tapping outside the text field
            _searchFocusNode.unfocus();
          },
          child: Scaffold(
            // Add resizeToAvoidBottomInset: false to prevent layout shifting when keyboard appears
            resizeToAvoidBottomInset: false,
            body: SafeArea(
              // Wrap the main content in SingleChildScrollView to handle potential overflow
              child: Row(
                children: [
                  // Main Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search bar (doesn't scroll with content)
                        _buildTopBar(),

                        // REMOVED Hidden TextField - causes black TextField
                        // Using RawKeyboardListener for clean scanner input
                        SizedBox.shrink(),

                        // Make the remaining content scrollable
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight:
                                    MediaQuery.of(context).size.height - 200,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildCategoryHeader(orderController),

                                  // Content area that should not have its own scroll
                                  productController.isLoading
                                      ? const Center(
                                          child: Padding(
                                          padding: EdgeInsets.all(40.0),
                                          child: CircularProgressIndicator(),
                                        ))
                                      : productController.error != null
                                          ? Center(
                                              child: Padding(
                                              padding:
                                                  const EdgeInsets.all(40.0),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Error: ${productController.error}',
                                                    style: const TextStyle(
                                                        color: KtColor.danger),
                                                  ),
                                                  if (productController.error!
                                                      .contains('Unauthorized'))
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        Navigator
                                                            .pushReplacementNamed(
                                                                context,
                                                                '/login');
                                                      },
                                                      child: const Text(
                                                          'Login Again'),
                                                    )
                                                ],
                                              ),
                                            ))
                                          : productController
                                                      .searchQuery.isNotEmpty &&
                                                  productController
                                                      .products.isEmpty
                                              ? Center(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            40.0),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(Icons.search_off,
                                                            size: 48,
                                                            color: Colors
                                                                .grey[400]),
                                                        const SizedBox(
                                                            height: 16),
                                                        Text(
                                                          'No results found for "${productController.searchQuery}"',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                        const SizedBox(
                                                            height: 16),
                                                        TextButton.icon(
                                                          onPressed: () =>
                                                              productController
                                                                  .clearSearch(),
                                                          icon: const Icon(
                                                              Icons.clear),
                                                          label: const Text(
                                                              'Clear Search'),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                )
                                              : _isGridView
                                                  ? _buildNonScrollableGridView(
                                                      context,
                                                      productController,
                                                      orderController,
                                                      showOrderPanel)
                                                  : _buildNonScrollableListView(
                                                      context,
                                                      productController,
                                                      orderController,
                                                      showOrderPanel),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Order Panel (Right Side) - only shown on larger screens
                  if (showOrderPanel)
                    SizedBox(
                      width: orderPanelWidth,
                      child: Card(
                        margin: EdgeInsets.zero,
                        elevation: 4,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildOrderHeader(),
                            _buildOrderTableHeader(),
                            Expanded(
                              child: orderController.items.isEmpty
                                  ? Center(
                                      child: Text('Belum ada pesanan',
                                          style: TextStyle(
                                              color: KtColor.neutral500)))
                                  : ListView.builder(
                                      itemCount: orderController.items.length,
                                      itemBuilder: (context, index) {
                                        final item =
                                            orderController.items[index];
                                        return OrderItemWidget(
                                          item: item,
                                          onIncrement: () => orderController
                                              .incrementQuantity(index),
                                          onDecrement: () => orderController
                                              .decrementQuantity(index),
                                        );
                                      },
                                    ),
                            ),
                            _buildOrderSummary(orderController),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Floating action button to go directly to payment confirmation
            floatingActionButton:
                !showOrderPanel && orderController.items.isNotEmpty
                    ? FloatingActionButton.extended(
                        onPressed: () {
                          // Navigate directly to payment confirmation page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentConfirmationPage(
                                orderController: orderController,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.payment),
                        label: Text('Bayar (${orderController.items.length})'),
                        backgroundColor: KtColor.successText,
                      )
                    : null,
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(OrderController orderController, bool isGridView,
      Function(bool) onViewToggle) {
    final productController = Provider.of<ProductController>(context);

    return Column(
      children: [
        // Show search results indicator when search is active
        if (productController.searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 4.0),
            child: Row(
              children: [
                Text(
                  'Results for "${productController.searchQuery}"',
                  style: TextStyle(
                    fontSize: 14,
                    color: KtColor.neutral500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: KtColor.violet100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${productController.products.length} items',
                    style: TextStyle(
                      fontSize: 12,
                      color: KtColor.violet700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => productController.clearSearch(),
                  child: Text('Clear',
                      style: TextStyle(color: KtColor.violet700, fontSize: 14)),
                ),
              ],
            ),
          ),

        // Regular action buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 2.0, 16.0, 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Action buttons grouped at right
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // View toggle button
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: KtColor.neutral200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => onViewToggle(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  isGridView ? KtColor.primary : KtColor.neutral200,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                bottomLeft: Radius.circular(6),
                              ),
                            ),
                            child: Icon(
                              Icons.grid_view,
                              size: 16,
                              color:
                                  isGridView ? KtColor.surface : KtColor.neutral500,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => onViewToggle(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  !isGridView ? KtColor.primary : KtColor.neutral200,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(6),
                                bottomRight: Radius.circular(6),
                              ),
                            ),
                            child: Icon(
                              Icons.view_list,
                              size: 16,
                              color:
                                  !isGridView ? KtColor.surface : KtColor.neutral500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderHeader() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: const [
          Text('Order',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Spacer(),
          Text('Menu', style: TextStyle(fontSize: 20, color: KtColor.neutral400)),
        ],
      ),
    );
  }

  Widget _buildOrderTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text('Menu',
                  style: TextStyle(color: KtColor.neutral500, fontSize: 12))),
          Expanded(
              flex: 3,
              child: Text('Nama',
                  style: TextStyle(color: KtColor.neutral500, fontSize: 12))),
          Expanded(
              flex: 2,
              child: Text('Jumlah',
                  style: TextStyle(color: KtColor.neutral500, fontSize: 12),
                  textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(OrderController orderController) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: KtColor.neutral200)),
      ),
      child: Column(
        children: [
          // Zona uang: angka yang dibaca kasir sambil terburu-buru, dengan
          // bingkai tebal supaya tidak tenggelam di antara daftar pesanan.
          Container(
            padding: const EdgeInsets.all(14),
            decoration: KtBold.surface(),
            child: Column(
              children: [
                _buildPriceRow('Sub Total', orderController.subtotal),
                const SizedBox(height: 10),
                _buildPriceRow('Total', orderController.total, isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: orderController.items.isEmpty
                  ? null
                  : () {
                      // Navigate to payment confirmation page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentConfirmationPage(
                            orderController: orderController,
                          ),
                        ),
                      );
                    },
              // Membayar adalah aksi utama, bukan status "berhasil" — hijau
              // dengan teks putih juga hanya 3,3:1. KtBold.action() ungu:
              // 5,7:1 dan target sentuh 56px.
              style: KtBold.action(),
              child: const Text('Bayar'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: orderController.items.isEmpty
                  ? null
                  : () => orderController.clearOrder(),
              style: ElevatedButton.styleFrom(
                backgroundColor: KtColor.surface,
                foregroundColor: KtColor.textSecondary,
                elevation: 0,
                disabledBackgroundColor: KtColor.surface,
                disabledForegroundColor: KtColor.neutral300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: KtColor.border),
                ),
              ),
              child: const Text('Reset',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: isBold ? KtColor.textPrimary : KtColor.neutral500,
                fontSize: isBold ? 16 : 14,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.normal)),
        Text(
          NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0)
              .format(amount),
          style: TextStyle(
              color: isBold ? KtColor.textPrimary : KtColor.neutral500,
              fontSize: isBold ? 20 : 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.normal),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    final productController = Provider.of<ProductController>(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Row(
        children: [
          // Use expanded instead of fixed width to make search bar responsive
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: KtColor.neutral50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: KtColor.neutral300),
                boxShadow: [
                  BoxShadow(
                    color: KtColor.neutral400.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Leading search icon
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Icon(
                      Icons.search,
                      color: KtColor.neutral400,
                      size: 20,
                    ),
                  ),

                  Expanded(
                    child: TextField(
                      // Use the focus node to control keyboard
                      focusNode: _searchFocusNode,
                      // Configure the text field to be scrollable and not auto-focus
                      scrollPadding: EdgeInsets.zero,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.search,
                      // Prevent auto-focus and keyboard issues
                      autofocus: false,
                      enableInteractiveSelection: true,
                      onChanged: (value) {
                        productController.setSearchQuery(value);
                      },
                      // Handle keyboard submission
                      onSubmitted: (_) {
                        // Dismiss keyboard when user presses "Search" on keyboard
                        _searchFocusNode.unfocus();
                      },
                      // Handle tap to prevent focus issues
                      onTap: () {
                        // Only focus if not already focused
                        if (!_searchFocusNode.hasFocus) {
                          _searchFocusNode.requestFocus();
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        hintStyle:
                            TextStyle(fontSize: 14, color: KtColor.neutral400),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 10),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),

                  // Clear button or search action button
                  if (productController.searchQuery.isNotEmpty)
                    // Show clear button when there's text
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          productController.clearSearch();
                          // Also unfocus when clearing search
                          _searchFocusNode.unfocus();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.close,
                            color: KtColor.neutral500,
                            size: 18,
                          ),
                        ),
                      ),
                    )
                  else
                    // Show a spacer when empty to keep symmetry
                    const SizedBox(width: 8),

                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(OrderController orderController) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 2.0, 16.0, 2.0),
      child: Row(
        children: [
          // Category Filter Dropdown
          _buildCategoryDropdown(),
          const Spacer(),
          // Action Buttons
          _buildActionButtons(orderController, _isGridView, (bool value) {
            setState(() {
              _isGridView = value;
            });
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final categoryController = Provider.of<CategoryController>(context);
    final productController = Provider.of<ProductController>(context);

    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: KtColor.violet100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: KtColor.violet200),
        ),
        child: Icon(
          Icons.filter_list,
          color: KtColor.violet700,
          size: 20,
        ),
      ),
      tooltip: 'Filter by Category',
      onSelected: (String category) {
        if (category == 'All') {
          productController.setCategory('All');
        } else {
          productController.loadProductsByCategory(category);
        }
      },
      itemBuilder: (BuildContext context) => [
        // All categories option
        PopupMenuItem<String>(
          value: 'All',
          child: Row(
            children: [
              Icon(
                Icons.category,
                color: KtColor.neutral500,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                'All Categories',
                style: TextStyle(
                  color: productController.selectedCategory == 'All'
                      ? KtColor.primary
                      : KtColor.neutral800,
                  fontWeight: productController.selectedCategory == 'All'
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              if (productController.selectedCategory == 'All')
                const Icon(
                  Icons.check,
                  color: KtColor.primary,
                  size: 18,
                ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        // Individual categories
        ...categoryController.categories.map((category) {
          return PopupMenuItem<String>(
            value: category.name,
            child: Row(
              children: [
                Icon(
                  _getCategoryIcon(category.name),
                  color: KtColor.neutral500,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  category.name,
                  style: TextStyle(
                    color: productController.selectedCategory == category.name
                        ? KtColor.primary
                        : KtColor.neutral800,
                    fontWeight:
                        productController.selectedCategory == category.name
                            ? FontWeight.bold
                            : FontWeight.normal,
                  ),
                ),
                if (productController.selectedCategory == category.name)
                  const Icon(
                    Icons.check,
                    color: KtColor.primary,
                    size: 18,
                  ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // Helper method to get category icon
  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'shirt':
        return Icons.shopping_bag;
      case 'drink':
        return Icons.local_drink;
      case 'snack':
        return Icons.fastfood;
      case 'pants':
        return Icons.dry_cleaning;
      case 'hot':
        return Icons.whatshot;
      default:
        return Icons.category;
    }
  }

  // Non-scrollable grid view layout
  Widget _buildNonScrollableGridView(
      BuildContext context,
      ProductController productController,
      OrderController orderController,
      bool showOrderPanel) {
    // Calculate columns based on screen width
    int crossAxisCount = 2;
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 400) crossAxisCount = 3;
    if (screenWidth > 650) crossAxisCount = 4;
    if (screenWidth > 900) crossAxisCount = 5;
    if (screenWidth > 1200) crossAxisCount = 6;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Build a non-scrollable grid using rows and columns
          GridView.builder(
            shrinkWrap: true, // Important - makes grid take only needed space
            physics: const NeverScrollableScrollPhysics(), // Disable scrolling
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: productController.products.length,
            itemBuilder: (context, index) {
              final product = productController.products[index];
              return ProductCard(
                product: product,
                isSmallSize: true,
                onTap: () {
                  addProductWithSize(context, orderController, product);
                },
              );
            },
          ),

          // Add padding at the bottom to ensure we can scroll all the way
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // Non-scrollable list view layout
  Widget _buildNonScrollableListView(
      BuildContext context,
      ProductController productController,
      OrderController orderController,
      bool showOrderPanel) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Use Column with children instead of ListView
          ...productController.products.map((product) {
            return Column(
              children: [
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: KtColor.neutral200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: product.image != null && product.image!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              product.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: KtColor.neutral400);
                              },
                            ),
                          )
                        : const Icon(Icons.image_not_supported_outlined,
                            color: KtColor.neutral400),
                  ),
                  title: Text(
                    product.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    NumberFormat.currency(
                            locale: 'id', symbol: 'Rp ', decimalDigits: 0)
                        .format(product.price),
                    style: TextStyle(color: KtColor.neutral600, fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: KtColor.primary),
                    onPressed: () {
                      addProductWithSize(context, orderController, product);
                    },
                  ),
                ),
                const Divider(height: 1),
              ],
            );
          }).toList(),

          // Add padding at the bottom
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
