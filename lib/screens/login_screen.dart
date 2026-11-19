import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../services/backend_service.dart';
import 'register_screen.dart';

/// Layar login. Role pengguna menentukan layar berikutnya:
/// admin -> Kelola Menu, kasir -> POS. Penentuan itu dilakukan
/// AuthGate di main.dart berdasarkan [AppUser.role].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _checkingBackend = false;
  BackendHealth? _backendHealth;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkBackend();
  }

  Future<void> _checkBackend() async {
    setState(() => _checkingBackend = true);
    final BackendHealth health = await BackendService.instance.checkHealth();
    if (mounted) {
      setState(() {
        _backendHealth = health;
        _checkingBackend = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Email dan kata sandi wajib diisi.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await AuthService.instance.login(email, password);
    } catch (e) {
      setState(() => _error = _cleanMessage(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _cleanMessage(Object e) {
    final String text = e.toString();
    return text.startsWith('Exception: ')
        ? text.substring('Exception: '.length)
        : text;
  }

  void _fillDemo(String email) {
    _emailController.text = email;
    _passwordController.text = '123456';
    setState(() => _error = null);
  }

  /// Kartu status koneksi ke backend Laravel (Apache/XAMPP).
  Widget _buildBackendStatusCard(BuildContext context) {
    final bool? online = _backendHealth?.online;
    final Color color = online == true
        ? Colors.green.shade50
        : online == false
            ? Colors.orange.shade50
            : Colors.blueGrey.shade50;
    final IconData icon = online == true
        ? Icons.cloud_done_outlined
        : online == false
            ? Icons.cloud_off_outlined
            : Icons.cloud_queue_outlined;

    return Card(
      color: color,
      child: ListTile(
        leading: _checkingBackend
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        title: Text(
          online == true
              ? 'Backend terhubung'
              : online == false
                  ? 'Backend belum terhubung'
                  : 'Memeriksa backend...',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_backendHealth?.message ?? 'Menghubungi ${BackendConfig.baseUrl}'}'
          '\n${BackendConfig.baseUrl}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: IconButton(
          tooltip: 'Periksa lagi',
          icon: const Icon(Icons.refresh_outlined),
          onPressed: _checkingBackend ? null : _checkBackend,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool demoMode = AppConfig.isDemoMode;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 32),
              const Icon(
                Icons.point_of_sale_rounded,
                size: 72,
                color: Colors.teal,
              ),
              const SizedBox(height: 16),
              Text(
                'POS Sederhana',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Aplikasi kasir: Admin kelola menu, Kasir melayani transaksi.',
                textAlign: TextAlign.center,
              ),
              if (demoMode) ...<Widget>[
                const SizedBox(height: 16),
                Card(
                  color: Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Mode Demo (Firebase belum dikonfigurasi)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text('Ketuk untuk mengisi akun demo:'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: <Widget>[
                            OutlinedButton(
                              onPressed: () => _fillDemo('admin@pos.demo'),
                              child: const Text('Admin Demo'),
                            ),
                            OutlinedButton(
                              onPressed: () => _fillDemo('kasir@pos.demo'),
                              child: const Text('Kasir Demo'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _buildBackendStatusCard(context),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                  ),
                ),
                onSubmitted: (_) => _login(),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Masuk'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const RegisterScreen(),
                    ),
                  );
                },
                child: const Text('Belum punya akun? Daftar di sini'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
