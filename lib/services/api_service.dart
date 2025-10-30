import 'dart:convert'; // Untuk jsonDecode
import 'package:http/http.dart' as http; // Untuk memanggil API

class ApiService {
  // Kita akan gunakan API gratis yang tidak butuh API Key
  // Kita ambil 'USD' sebagai mata uang dasar
  final String _baseUrl = "https://open.er-api.com/v6/latest/USD";

  /*
    Fungsi ini akan memanggil API dan mengembalikan sebuah 'Map' 
    yang berisi semua data kurs.
    Contoh:
    {
      "IDR": 16250.7,
      "EUR": 0.92,
      "JPY": 156.5,
      ...dll
    }
  */
  Future<Map<String, dynamic>?> getRates() async {
    try {
      // 1. Panggil API
      final response = await http.get(Uri.parse(_baseUrl));

      // 2. Cek apakah panggilan berhasil (HTTP 200)
      if (response.statusCode == 200) {
        // 3. Ubah data JSON (teks) menjadi Map
        Map<String, dynamic> data = jsonDecode(response.body);

        // 4. API ini mengembalikan data kurs di dalam key 'rates'
        if (data.containsKey('rates')) {
          // Kembalikan hanya bagian 'rates'-nya saja
          return data['rates'] as Map<String, dynamic>;
        } else {
          // Gagal jika formatnya aneh
          print("Error_api: Key 'rates' tidak ditemukan");
          return null;
        }
      } else {
        // Gagal jika server error (misal: 404, 500)
        print("Error_api: Server merespon ${response.statusCode}");
        return null;
      }
    } catch (e) {
      // Gagal jika tidak ada koneksi internet
      print("Error_api: $e");
      return null;
    }
  }
}
