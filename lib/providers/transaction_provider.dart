// File: lib/providers/transaction_provider.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../services/firebase_service.dart';

class TransactionProvider extends ChangeNotifier {
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  
  String _userCode = ''; // Kode unik aktif
  String _ownUserCode = ''; // Simpan kode unik asli mahasiswa
  bool _isReadOnly = false; // Status apakah sedang dalam Mode Pantau Orang Tua

  final FirebaseService _firebase = FirebaseService();
  StreamSubscription? _streamSubscription;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String get userCode => _userCode;
  String get ownUserCode => _ownUserCode;
  bool get isReadOnly => _isReadOnly;

  TransactionProvider() {
    _initProvider();
  }

  Future<void> _initProvider() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _ownUserCode = prefs.getString('userCode') ?? '';

    if (_ownUserCode.isEmpty) {
      _ownUserCode = 'KOS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      await prefs.setString('userCode', _ownUserCode);
    }

    _userCode = _ownUserCode;
    _listenToFirebase();
  }

  // Masuk sebagai Mahasiswa (Akses Penuh)
  void setStudentMode() {
    _isReadOnly = false;
    _userCode = _ownUserCode;
    _listenToFirebase();
  }

  // Masuk sebagai Orang Tua (Akses Baca Saja dengan Kode Unik Anak)
  void setParentMode(String targetCode) {
    _isReadOnly = true;
    _userCode = targetCode.trim().toUpperCase();
    _listenToFirebase();
  }

  void _listenToFirebase() {
    _streamSubscription?.cancel();
    _streamSubscription = _firebase.getTransactions(_userCode).listen((data) {
      _transactions = data;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addTransaction(TransactionModel transaction, {File? imageFile}) async {
    if (_isReadOnly) return; // Mencegah tambah jika mode read-only
    String? imageUrl = transaction.imageUrl;
    
    if (imageFile != null) {
      imageUrl = await _firebase.uploadStruk(imageFile);
    }

    final newTx = TransactionModel(
      amount: transaction.amount,
      category: transaction.category,
      date: transaction.date,
      note: transaction.note,
      imageUrl: imageUrl,
    );

    await _firebase.addTransaction(_userCode, newTx);
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    if (_isReadOnly) return;
    await _firebase.updateTransaction(_userCode, transaction);
  }

  Future<void> deleteTransaction(String id) async {
    if (_isReadOnly) return;
    await _firebase.deleteTransaction(_userCode, id);
  }

  int get totalHariIni {
    final now = DateTime.now();
    return _transactions.where((tx) =>
        tx.date.year == now.year && tx.date.month == now.month && tx.date.day == now.day
    ).fold(0, (sum, tx) => sum + tx.amount);
  }

  int get totalBulanIni {
    final now = DateTime.now();
    return _transactions.where((tx) =>
        tx.date.year == now.year && tx.date.month == now.month
    ).fold(0, (sum, tx) => sum + tx.amount);
  }

  List<TransactionModel> getTransactionsByFilter(String filter) {
    final now = DateTime.now();
    if (filter == 'Hari Ini') {
      return _transactions.where((tx) => 
        tx.date.year == now.year && tx.date.month == now.month && tx.date.day == now.day
      ).toList();
    } else if (filter == '7 Hari Terakhir') {
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      return _transactions.where((tx) => tx.date.isAfter(sevenDaysAgo)).toList();
    } else if (filter == 'Bulan Ini') {
      return _transactions.where((tx) => 
        tx.date.year == now.year && tx.date.month == now.month
      ).toList();
    }
    return _transactions;
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}