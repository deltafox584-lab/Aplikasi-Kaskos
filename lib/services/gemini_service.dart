// File: lib/services/gemini_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiReceiptResult {
  final int? amount;
  final String? category;
  final String? note;
  final DateTime? date;

  GeminiReceiptResult({this.amount, this.category, this.note, this.date});
}

class GeminiService {
  // Mengambil API Key dari environment variable saat aplikasi dijalankan
  // Jangan pernah menaruh API Key langsung sebagai String di kode!
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  Future<GeminiReceiptResult?> scanReceipt(File imageFile) async {
    if (_apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY belum dikonfigurasi saat pembentukan/menjalankan aplikasi.');
    }

    // Gunakan model terbaru gemini-3.8-flash untuk pemrosesan multimodal yang cepat
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent?key=$_apiKey',
    );

    try {
      // Ubah file gambar ke format base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Prompt instruksi eksplisit agar AI merespons dalam format JSON
      const promptText = '''
Analisis foto struk belanja ini. Ekstrak informasi berikut dalam format JSON murni tanpa markdown/penjelasan tambahan:
{
  "amount": (angka total pembayaran dalam rupiah, int saja tanpa titik/koma),
  "category": (pilih salah satu persis: "Makan", "Kos", "Transport", "Kuliah", "Hiburan", atau "Lainnya"),
  "note": (nama toko atau ringkasan item singkat),
  "date": (tanggal pada struk format YYYY-MM-DD, jika tidak terlihat gunakan tanggal hari ini)
}
''';

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "inlineData": {
                    "mimeType": "image/jpeg",
                    "data": base64Image,
                  }
                },
                {"text": promptText}
              ]
            }
          ],
          "generationConfig": {
            "responseMimeType": "application/json" // Memaksa AI memberikan balasan JSON
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String textResponse = data['candidates'][0]['content']['parts'][0]['text'];
        final Map<String, dynamic> parsedJson = jsonDecode(textResponse);

        return GeminiReceiptResult(
          amount: parsedJson['amount'] is int ? parsedJson['amount'] : int.tryParse(parsedJson['amount'].toString()),
          category: parsedJson['category'],
          note: parsedJson['note'],
          date: parsedJson['date'] != null ? DateTime.tryParse(parsedJson['date']) : null,
        );
      } else {
        print('Gemini API Error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Gagal melakukan ekstraksi struk: $e');
      return null;
    }
  }
}