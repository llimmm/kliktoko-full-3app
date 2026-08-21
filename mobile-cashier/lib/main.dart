import 'dart:async';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scan_gun/scan_gun.dart';
import 'service/api_service.dart';
import 'service/category_service.dart';
import 'controllers/auth_controller.dart';
import 'controllers/product_controller.dart';
import 'controllers/order_controller.dart';
import 'controllers/category_controller.dart';
import 'controllers/history_controller.dart';
import 'pages/login_page.dart';
import 'pages/main_navigation.dart';
import 'config/api_config.dart';
import 'theme/tokens.dart';

// Add a splash screen widget
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.storefront,
              size: 80,
              color: KtColor.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              'Kasir Simoto',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Memuat aplikasi...',
              style: const TextStyle(
                fontSize: 16,
                color: KtColor.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() async {
  // Initialize TextInputBinding for scan gun support
  TextInputBinding();
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  await SharedPreferences.getInstance();

  // DISABLE ALL DIALOGS AND SCREEN ITEMS FOR SCANNER
  // Force silent mode globally

  runApp(const MyApp());
}

// Pindahkan kode inisialisasi ke dalam State class agar dijalankan dalam zona yang sama
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Konfigurasi error handling
    FlutterError.onError = (details) {
      FlutterError.dumpErrorToConsole(details);
      if (kDebugMode) {
        print('FlutterError: ${details.exception}');
        print('Stack trace: ${details.stack}');
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<ApiService>(
            create: (_) => ApiService(baseUrl: ApiConfig.baseUrl)),
        ProxyProvider<ApiService, CategoryService>(
          update: (ctx, apiService, _) => CategoryService(
            baseUrl: ApiConfig.baseUrl,
            apiService: apiService,
          ),
        ),

        // Controllers
        ChangeNotifierProvider<AuthController>(
          create: (ctx) => AuthController(apiService: ctx.read<ApiService>()),
        ),
        ChangeNotifierProvider<CategoryController>(
          create: (ctx) =>
              CategoryController(categoryService: ctx.read<CategoryService>()),
        ),
        ChangeNotifierProxyProvider<AuthController, ProductController>(
          create: (ctx) => ProductController(apiService: ctx.read()),
          update: (ctx, auth, ctrl) {
            // saat auth.token berubah, kita trigger load ulang
            if (auth.isLoggedIn && ctrl != null) {
              // Hanya reload jika kita benar-benar punya token valid
              if (kDebugMode) {
                print('Auth state changed, product controller updated');
              }
            }
            return ctrl ?? ProductController(apiService: ctx.read());
          },
        ),
        ChangeNotifierProvider<HistoryController>(
          create: (_) => HistoryController(
              ApiService(baseUrl: ApiConfig.baseUrl)),
        ),
        ChangeNotifierProxyProvider2<ApiService, HistoryController,
            OrderController>(
          create: (ctx) => OrderController(
            ctx.read<ApiService>(),
            ctx.read<HistoryController>(),
          ),
          update: (ctx, apiService, history, previous) =>
              previous ?? OrderController(apiService, history),
        ),
      ],
      child: Consumer<AuthController>(
        builder: (ctx, auth, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Kasir Simoto',
            theme: ktTheme(),
            // DISABLE ALL DIALOGS AND SCREEN ITEMS FOR SCANNER
            // Force silent mode globally
            // Show splash screen for a brief moment before deciding on the initial route
            home: FutureBuilder(
              // Small delay to show splash screen for better UX
              future: Future.delayed(const Duration(milliseconds: 1500)),
              builder: (context, snapshot) {
                // If we're still waiting, show splash screen
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SplashScreen();
                }

                // Once done, navigate to appropriate route based on auth state
                return auth.isLoggedIn
                    ? const MainNavigation()
                    : const LoginPage();
              },
            ),
            // Use onGenerateRoute for navigation after initial route
            onGenerateRoute: (settings) {
              if (settings.name == '/') {
                if (!auth.isLoggedIn) {
                  // Redirect to login if trying to access home without being logged in
                  return MaterialPageRoute(
                    builder: (_) => const LoginPage(),
                    settings: const RouteSettings(name: '/login'),
                  );
                }
                return MaterialPageRoute(
                  builder: (_) => const MainNavigation(),
                  settings: settings,
                );
              } else if (settings.name == '/login') {
                return MaterialPageRoute(
                  builder: (_) => const LoginPage(),
                  settings: settings,
                );
              }
              // Fallback for unknown routes
              return MaterialPageRoute(
                builder: (_) => auth.isLoggedIn
                    ? const MainNavigation()
                    : const LoginPage(),
              );
            },
            // Error handler global
            builder: (context, widget) {
              // Tangkap semua error di Flutter
              ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
                if (kDebugMode) {
                  print('Flutter Error: ${errorDetails.exception}');
                  print('Stack trace: ${errorDetails.stack}');
                }
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 60, color: KtColor.danger),
                        const SizedBox(height: 16),
                        const Text('Terjadi kesalahan',
                            style: TextStyle(fontSize: 20)),
                        const SizedBox(height: 8),
                        if (kDebugMode)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              errorDetails.exception.toString(),
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                                context, auth.isLoggedIn ? '/' : '/login');
                          },
                          child: const Text('Kembali'),
                        ),
                      ],
                    ),
                  ),
                );
              };
              return widget!;
            },
          );
        },
      ),
    );
  }
}
