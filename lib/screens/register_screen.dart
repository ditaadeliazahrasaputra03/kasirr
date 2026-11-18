import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// Pendaftaran akun baru beserta pilihan role (admin/kasir).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  String _role = 'kasir';
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Nama, email, dan kata sandi wajib diisi.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Kata sandi minimal 6 karakter.');
      return;
    }
    if (password != _confirmController.text) {
      setState(() => _error = 'Konfirmasi kata sandi tidak cocok.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await AuthService.instance.register(
        name: name,
        email: email,
        password: password,
        role: _role,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      final String text = e.toString();
      setState(
        () => _error = text.startsWith('Exception: ')
            ? text.substring('Exception: '.length)
            : text,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Kata Sandi (minimal 6 karakter)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Konfirmasi Kata Sandi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(
                labelText: 'Role / Hak Akses',
                border: OutlineInputBorder(),
              ),
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                  value: 'kasir',
                  child: Text('Kasir - melayani transaksi POS'),
                ),
                DropdownMenuItem<String>(
                  value: 'admin',
                  child: Text('Admin - mengelola menu'),
                ),
              ],
              onChanged: (String? value) {
                if (value != null) {
                  setState(() => _role = value);
                }
              },
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
              onPressed: _isLoading ? null : _register,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Buat Akun'),
            ),
          ],
        ),
      ),
    );
  }
}
