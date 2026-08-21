import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'package:kasir_simoto/pages/home_page.dart';
import 'package:kasir_simoto/pages/history_pages.dart';

import 'package:kasir_simoto/pages/printer_page.dart';
import 'package:kasir_simoto/pages/usb_scanner_page.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // Pages to be displayed
  final List<Widget> _pages = [
    const HomePage(),
    const HistoryPage(),
  ];

  // Page titles
  final List<String> _titles = [
    'Kasir',
    'History',
  ];

  // Icons for navigation
  final List<IconData> _icons = [
    Icons.point_of_sale_outlined,
    Icons.receipt_long_outlined,
    Icons.person_outline,
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Close the drawer if it's open
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _handleLogout() {
    // Close drawer first if open
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final authController =
                  Provider.of<AuthController>(context, listen: false);
              authController.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Logout', style: TextStyle(color: KtColor.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Jika ada dialog atau drawer terbuka, tutup dulu
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
          return false; // Jangan keluar dari app
        }
        // Jika tidak ada yang bisa di-pop, keluar dari app
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_selectedIndex]),
          backgroundColor: KtColor.surface,
          // Neobrutalism: tanpa elevasi lembut; tepi bawah adalah garis hitam
          // tegas, bukan bayangan yang di ambang terlihat.
          elevation: 0,
          scrolledUnderElevation: 0,
          shape: const Border(
            bottom: BorderSide(color: KtColor.black, width: 3),
          ),
        ),

        // Use drawer for navigation
        drawer: Drawer(
          width: 250, // More compact drawer width
          backgroundColor: KtColor.surface,
          // Sudut tegas + border kanan hitam, bukan panel membulat mengambang.
          shape: const Border(
            right: BorderSide(color: KtColor.black, width: 3),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Drawer header
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: const BoxDecoration(
                    color: KtColor.neutral100,
                    border: Border(
                      bottom: BorderSide(color: KtColor.black, width: 3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: KtColor.primary,
                        child: Icon(Icons.point_of_sale, color: KtColor.surface),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kasir Simoto',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Aplikasi Kasir',
                              style: TextStyle(
                                  color: KtColor.neutral600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Navigation items
                //
                // Tile terpilih dulu tint violet100 dengan teks ungu — 4,80:1,
                // lolos tipis dan luntur pada goresan huruf tipis. Sekarang
                // blok pekat berborder hitam dengan teks/ikon HITAM: 14,92:1.
                // Polanya sama seperti chip keadaan di app employee.
                for (int i = 0; i < _pages.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: KtSpace.sm, vertical: KtSpace.xs / 2),
                    child: Container(
                      decoration: _selectedIndex == i
                          ? KtBrutal.block(KtColor.violet100)
                          : null,
                      child: ListTile(
                        leading: Icon(
                          _icons[i],
                          color: _selectedIndex == i
                              ? KtColor.black
                              : KtColor.neutral600,
                          size: 20,
                        ),
                        title: Text(
                          _titles[i],
                          style: TextStyle(
                            color: _selectedIndex == i
                                ? KtColor.black
                                : KtColor.neutral800,
                            fontSize: 14,
                            fontWeight: _selectedIndex == i
                                ? FontWeight.w800
                                : FontWeight.normal,
                          ),
                        ),
                        dense: true,
                        visualDensity:
                            const VisualDensity(horizontal: 0, vertical: -1),
                        onTap: () => _onItemTapped(i),
                      ),
                    ),
                  ),

                const Divider(color: KtColor.black, thickness: 2),

                // Printer settings option
                ListTile(
                  leading: const Icon(
                    Icons.print,
                    color: KtColor.primary,
                    size: 20,
                  ),
                  title: const Text(
                    'Pengaturan Printer',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  dense: true,
                  visualDensity:
                      const VisualDensity(horizontal: 0, vertical: -1),
                  onTap: () {
                    // Close drawer first
                    Navigator.pop(context);
                    // Navigate to printer settings page with callback
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PrinterPage(
                          onConnectionChanged: (isConnected, selectedDevice) {
                            // Status koneksi sudah diperbarui di PrinterService karena menggunakan singleton
                            // Gunakan Future.microtask untuk memastikan setState dipanggil setelah navigasi selesai
                            Future.microtask(() {
                              if (mounted) {
                                setState(() {});
                              }
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),

                // Scanner settings option
                ListTile(
                  leading: const Icon(
                    Icons.qr_code_scanner,
                    color: KtColor.primary,
                    size: 20,
                  ),
                  title: const Text(
                    'USB Scanner iware',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  dense: true,
                  visualDensity:
                      const VisualDensity(horizontal: 0, vertical: -1),
                  onTap: () {
                    // Close drawer first
                    Navigator.pop(context);
                    // Navigate to USB scanner page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UsbScannerPage(),
                      ),
                    );
                  },
                ),

                const Divider(color: KtColor.black, thickness: 2),

                // Logout option
                ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: KtColor.textSecondary,
                    size: 20,
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: KtColor.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  dense: true,
                  visualDensity:
                      const VisualDensity(horizontal: 0, vertical: -1),
                  onTap: _handleLogout,
                ),
              ],
            ),
          ),
        ),

        // Main content
        body: _pages[_selectedIndex],
      ),
    );
  }
}
