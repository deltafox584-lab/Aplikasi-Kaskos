// File: lib/screens/add_transaction_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../services/gemini_service.dart'; // IMPORT GEMINI SERVICE

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _geminiService = GeminiService();
  
  String _selectedCategory = 'Makan';
  DateTime _selectedDate = DateTime.now();
  
  File? _imageFile;
  bool _isUploading = false;
  bool _isScanning = false; // Status loading AI

  final List<String> _categories = [
    'Makan', 'Kos', 'Transport', 'Kuliah', 'Hiburan', 'Lainnya'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _amountController.text = widget.transaction!.amount.toString();
      _noteController.text = widget.transaction!.note;
      _selectedCategory = widget.transaction!.category;
      _selectedDate = widget.transaction!.date;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      // Otomatis jalankan pindai AI setelah foto berhasil diambil
      _scanReceiptWithAI();
    }
  }

  // --- Fungsi Pindai Struk dengan Gemini API ---
  Future<void> _scanReceiptWithAI() async {
    if (_imageFile == null) return;

    setState(() => _isScanning = true);

    try {
      final result = await _geminiService.scanReceipt(_imageFile!);

      if (result != null) {
        setState(() {
          if (result.amount != null) _amountController.text = result.amount.toString();
          if (result.note != null && result.note!.isNotEmpty) _noteController.text = result.note!;
          if (result.date != null) _selectedDate = result.date!;
          if (result.category != null && _categories.contains(result.category)) {
            _selectedCategory = result.category!;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Struk berhasil dipindai oleh Gemini AI!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membaca struk. Silakan isi form manual.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error AI: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUploading = true);

      try {
        final amount = int.parse(_amountController.text);
        final transactionData = TransactionModel(
          id: widget.transaction?.id,
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate,
          note: _noteController.text.trim(),
          imageUrl: widget.transaction?.imageUrl,
        );

        final provider = Provider.of<TransactionProvider>(context, listen: false);

        if (widget.transaction == null) {
          await provider.addTransaction(transactionData, imageFile: _imageFile);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil dicatat!')));
        } else {
          await provider.updateTransaction(transactionData);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil diperbarui!')));
        }

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.transaction != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditMode ? 'Edit Pengeluaran' : 'Tambah Pengeluaran')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (isEditMode && widget.transaction!.imageUrl != null)
              Container(
                height: 150,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(widget.transaction!.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else if (!isEditMode)
              Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: _imageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Ketuk untuk foto struk', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                    ),
                  ),
                  if (_imageFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: OutlinedButton.icon(
                        icon: _isScanning
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.auto_awesome),
                        label: Text(_isScanning ? 'Menganalisis Struk...' : 'Pindai Ulang dengan AI'),
                        onPressed: _isScanning ? null : _scanReceiptWithAI,
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),

            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Nominal Pengeluaran',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Nominal tidak boleh kosong';
                if (int.tryParse(value) == 0) return 'Nominal harus lebih dari 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (newValue) => setState(() => _selectedCategory = newValue!),
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              title: Text('Tanggal: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Catatan (Cth: Nasi Goreng)', border: OutlineInputBorder()),
              validator: (value) => value == null || value.trim().isEmpty ? 'Catatan tidak boleh kosong' : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: _isUploading || _isScanning ? null : _saveTransaction,
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Simpan', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}