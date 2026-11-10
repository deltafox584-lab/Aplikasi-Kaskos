// File: lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _codeController = TextEditingController();

  void _loginAsStudent() {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    provider.setStudentMode();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  void _loginAsParent() {
    final targetCode = _codeController.text.trim();
    if (targetCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan Kode Unik Mahasiswa terlebih dahulu')),
      );
      return;
    }

    final provider = Provider.of<TransactionProvider>(context, listen: false);
    provider.setParentMode(targetCode);
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.account_balance_wallet, size: 80, color: Colors.teal),
              const SizedBox(height: 16),
              const Text(
                'KasKos',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Catat & Pantau Pengeluaran Anak Kos',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),

              // --- Tombol Masuk Mahasiswa ---
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.person),
                label: const Text('Masuk sebagai Mahasiswa', style: TextStyle(fontSize: 16)),
                onPressed: _loginAsStudent,
              ),

              // Menampilkan Kode Unik Mahasiswa
              if (provider.ownUserCode.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Kode Anda: ${provider.ownUserCode}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: provider.ownUserCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kode unik berhasil disalin!')),
                        );
                      },
                    ),
                  ],
                ),
              ],

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('atau', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
              ),

              // --- Input & Tombol Masuk Orang Tua ---
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Kode Unik Mahasiswa',
                  hintText: 'Contoh: KOS-123456',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.family_restroom),
                label: const Text('Pantau Pengeluaran (Orang Tua)', style: TextStyle(fontSize: 16)),
                onPressed: _loginAsParent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}