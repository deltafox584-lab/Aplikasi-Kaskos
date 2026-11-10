// File: lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_card.dart';
import 'add_transaction_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              provider.isReadOnly ? 'Pantau: ${provider.userCode}' : 'KasKos',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HistoryScreen()),
                  );
                },
              ),
              // Tombol ganti peran / keluar
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Spanduk peringatan jika sedang dalam Mode Pantau Orang Tua
                    if (provider.isReadOnly)
                      Container(
                        color: Colors.orange.shade100,
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.visibility, color: Colors.orange, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Mode Pantau (Hanya Bisa Membaca Data)',
                              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryColumn('Hari Ini', currencyFormat.format(provider.totalHariIni)),
                          Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.5)),
                          _buildSummaryColumn('Bulan Ini', currencyFormat.format(provider.totalBulanIni)),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Transaksi Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Expanded(
                      child: provider.transactions.isEmpty
                          ? const Center(child: Text('Belum ada pengeluaran.', textAlign: TextAlign.center))
                          : ListView.builder(
                              itemCount: provider.transactions.length,
                              itemBuilder: (context, index) {
                                final transaction = provider.transactions[index];
                                return TransactionCard(
                                  transaction: transaction,
                                  onDelete: () {
                                    if (provider.isReadOnly) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Mode Pantau: Tidak bisa menghapus data')),
                                      );
                                      return;
                                    }
                                    provider.deleteTransaction(transaction.id!);
                                  },
                                  onEdit: () {
                                    if (provider.isReadOnly) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Mode Pantau: Tidak bisa mengedit data')),
                                      );
                                      return;
                                    }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddTransactionScreen(transaction: transaction),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
          // Sembunyikan tombol (+) Tambah Pengeluaran jika dalam mode Read-Only
          floatingActionButton: provider.isReadOnly
              ? null
              : FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
                    );
                  },
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }

  Widget _buildSummaryColumn(String title, String amount) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 8),
        Text(amount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
      ],
    );
  }
}