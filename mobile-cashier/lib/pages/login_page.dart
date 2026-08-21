import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    _username.clear();
    _password.clear();
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return WillPopScope(
      // Prevent back navigation from login page
      onWillPop: () async => false,
      child: Scaffold(
        // Removing the AppBar to prevent back navigation
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      screenSize.height - MediaQuery.of(context).padding.top,
                ),
                child: Container(
                  width: isSmallScreen ? double.infinity : 400,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 24 : 32,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo or App name
                      const Icon(
                        Icons.storefront,
                        size: 64,
                        color: KtColor.primary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Kasir Simoto',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Aplikasi Kasir & Manajemen Toko',
                        style: TextStyle(
                          fontSize: 14,
                          color: KtColor.neutral400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Username field
                      TextField(
                        controller: _username,
                        decoration: InputDecoration(
                          labelText: 'Nama Pengguna',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      TextField(
                        controller: _password,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),

                      // Login button or loading indicator
                      auth.isLoading || _isLoggingIn
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_username.text.trim().isEmpty ||
                                      _password.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Nama pengguna dan password harus diisi'),
                                        backgroundColor: KtColor.danger,
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() => _isLoggingIn = true);
                                  final scaffoldMessenger =
                                      ScaffoldMessenger.of(context);
                                  final navigator = Navigator.of(context);

                                  try {
                                    await auth.login(
                                        _username.text.trim(), _password.text);

                                    if (!mounted) return;

                                    if (auth.error == null) {
                                      navigator.pushReplacementNamed('/');
                                    }
                                  } catch (e) {
                                    if (!mounted) return;
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Login error: $e'),
                                        backgroundColor: KtColor.danger,
                                      ),
                                    );
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isLoggingIn = false);
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: KtColor.primary,
                                  foregroundColor: KtColor.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'MASUK',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                      // Error message if any
                      if (auth.error != null)
                      
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            auth.error!,
                            style: const TextStyle(color: KtColor.danger),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
