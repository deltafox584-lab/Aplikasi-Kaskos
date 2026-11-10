// File: lib/widgets/transaction_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Dismissible(
      key: ValueKey(transaction.id), 
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Transaksi?'),
            content: const Text('Apakah Anda yakin ingin menghapus pengeluaran ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        child: ListTile(
          // --- Menampilkan Foto atau Ikon Kategori ---
          leading: transaction.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    transaction.imageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    // Efek loading saat gambar didownload dari internet
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        width: 50, height: 50,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    },
                    // Jika gambar gagal dimuat (misal: koneksi putus)
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                  ),
                )
              : CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(_getCategoryIcon(transaction.category), color: Theme.of(context).colorScheme.primary),
                ),
          title: Text(transaction.category, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${dateFormat.format(transaction.date)} • ${transaction.note}'),
          trailing: Text(
            currencyFormat.format(transaction.amount),
            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          onTap: onEdit,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Makan': return Icons.restaurant;
      case 'Kos': return Icons.house;
      case 'Transport': return Icons.directions_car;
      case 'Kuliah': return Icons.school;
      case 'Hiburan': return Icons.movie;
      default: return Icons.more_horiz;
    }
  }
}