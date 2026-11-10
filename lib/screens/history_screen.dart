// File: lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_card.dart';
import 'add_transaction_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Filter bawaan saat halaman dibuka
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Hari Ini', '7 Hari Terakhir', 'Bulan Ini'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pengeluaran'),
        actions: [
          // Dropdown untuk memilih filter langsung dari AppBar
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<String>(
              value: _selectedFilter,
              dropdownColor: Theme.of(context).colorScheme.surface,
              underline: const SizedBox(), // Menghilangkan garis bawah bawaan dropdown
              icon: const Icon(Icons.filter_list),
              items: _filters.map((filter) {
                return DropdownMenuItem(value: filter, child: Text(filter));
              }).toList(),
              onChanged: (newValue) {
                setState(() => _selectedFilter = newValue!);
              },
            ),
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          // Mengambil data yang sudah disaring dari Provider
          final filteredTransactions = provider.getTransactionsByFilter(_selectedFilter);

          if (filteredTransactions.isEmpty) {
            return const Center(child: Text('Tidak ada transaksi di rentang waktu ini.'));
          }

          return ListView.builder(
            itemCount: filteredTransactions.length,
            itemBuilder: (context, index) {
              final transaction = filteredTransactions[index];
              return TransactionCard(
                transaction: transaction,
                onDelete: () {
                  provider.deleteTransaction(transaction.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaksi berhasil dihapus')),
                  );
                },
                onEdit: () {
                  // Membuka halaman AddTransactionScreen dalam mode Edit
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddTransactionScreen(transaction: transaction),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}