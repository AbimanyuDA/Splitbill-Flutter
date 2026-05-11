import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/receipt.dart';

class AiService {
  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'meta-llama/llama-4-scout-17b-16e-instruct';

  // Rotasi key otomatis jika kena rate limit
  static final _keys = <String>[];

  static void _loadKeys() {
    if (_keys.isNotEmpty) return;
    for (var i = 1; i <= 4; i++) {
      final k = dotenv.env['GROQ_API_KEY_$i'] ?? '';
      if (k.isNotEmpty) _keys.add(k);
    }
    // fallback ke single key jika ada
    final single = dotenv.env['GROQ_API_KEY'] ?? '';
    if (single.isNotEmpty && !_keys.contains(single)) _keys.add(single);
  }

  static int _keyIndex = 0;
  static String get _currentKey {
    _loadKeys();
    if (_keys.isEmpty) throw Exception('Tidak ada GROQ_API_KEY di .env');
    return _keys[_keyIndex % _keys.length];
  }

  static void _rotateKey() => _keyIndex++;

  static const _prompt =
      'Kamu adalah sistem OCR untuk nota/struk belanja. Analisa gambar nota ini dan ekstrak semua informasi.\n\n'
      'Kembalikan HANYA JSON valid (tanpa markdown, tanpa penjelasan) dengan format:\n'
      '{"items":[{"name":"nama item","price":harga_satuan,"qty":jumlah}],"tax":pajak,"shipping":ongkir,"subtotal":subtotal,"total":total}\n\n'
      'Aturan: semua angka integer tanpa pemisah ribuan. Jika tidak ada pajak/ongkir isi 0. '
      'Nama item gunakan teks asli di nota. Jika ada diskon per item sudah dikurangi dari price.';

  static Future<Receipt> analyzeReceipt(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final mimeType = _getMimeType(imageFile.path);

    // Coba hingga semua key habis
    Exception? lastError;
    for (var attempt = 0; attempt < _keys.length + 1; attempt++) {
      try {
        return await _callApi(base64Image, mimeType);
      } on _RateLimitException {
        _rotateKey();
        lastError = Exception('Semua API key kena rate limit, coba lagi nanti');
      } catch (e) {
        rethrow;
      }
    }
    throw lastError ?? Exception('Gagal menganalisa nota');
  }

  static Future<Receipt> _callApi(String base64Image, String mimeType) async {
    final body = jsonEncode({
      'model': _model,
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': _prompt},
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:$mimeType;base64,$base64Image',
              },
            },
          ],
        }
      ],
      'temperature': 0.1,
      'max_tokens': 1024,
    });

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_currentKey',
      },
      body: body,
    );

    if (response.statusCode == 429) throw _RateLimitException();

    if (response.statusCode != 200) {
      throw Exception('Groq API error ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final text =
        decoded['choices'][0]['message']['content'] as String;

    final cleaned = text
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    // Ambil JSON object dari response (Llama kadang tambah teks sebelum/sesudah)
    final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(cleaned);
    if (jsonMatch == null) throw Exception('AI tidak mengembalikan JSON valid');

    final receiptJson = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
    return Receipt.fromJson(receiptJson);
  }

  static String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}

class _RateLimitException implements Exception {}
