// File: lib/services/firebase_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/transaction_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Mendapatkan referensi folder data berdasarkan Kode Unik Mahasiswa
  CollectionReference _getCollection(String userCode) {
    return _firestore.collection('users').doc(userCode).collection('transactions');
  }

  // Menambah transaksi baru ke Firestore
  Future<void> addTransaction(String userCode, TransactionModel transaction) async {
    await _getCollection(userCode).add(transaction.toMap());
  }

  // Membaca transaksi secara realtime (Stream)
  Stream<List<TransactionModel>> getTransactions(String userCode) {
    return _getCollection(userCode)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Mengupdate transaksi
  Future<void> updateTransaction(String userCode, TransactionModel transaction) async {
    await _getCollection(userCode).doc(transaction.id).update(transaction.toMap());
  }

  // Menghapus transaksi
  Future<void> deleteTransaction(String userCode, String transactionId) async {
    await _getCollection(userCode).doc(transactionId).delete();
  }

  // Mengunggah foto struk ke Firebase Storage dan mengembalikan link URL-nya
  Future<String?> uploadStruk(File imageFile) async {
    try {
      // Membuat nama file unik dari waktu saat ini
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage.ref().child('struk_images/$fileName.jpg');
      
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error upload gambar: $e");
      return null; // Mengembalikan null jika gagal
    }
  }
}