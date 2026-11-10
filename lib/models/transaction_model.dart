// File: lib/models/transaction_model.dart

class TransactionModel {
  String? id; // Berubah dari int ke String karena Firestore memakai ID berbasis teks
  final int amount;
  final String category;
  final DateTime date;
  final String note;
  final String? imageUrl; // Menampung link URL foto struk dari Firebase Storage

  TransactionModel({
    this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.note,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
      'imageUrl': imageUrl,
    };
  }

  // Mengubah data dari Firestore kembali menjadi objek, menyertakan documentId
  factory TransactionModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TransactionModel(
      id: documentId,
      amount: map['amount'] ?? 0,
      category: map['category'] ?? 'Lainnya',
      date: DateTime.parse(map['date']),
      note: map['note'] ?? '',
      imageUrl: map['imageUrl'],
    );
  }
}