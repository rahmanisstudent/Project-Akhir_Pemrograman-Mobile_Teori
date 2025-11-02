import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl =
      "https://open.er-api.com/v6/latest/USD"; //exchange Rate - API

  Future<Map<String, dynamic>?> getRates() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      // control statement
      if (response.statusCode == 200) {
        // ubah ke map dari json
        Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey('rates')) {
          return data['rates'] as Map<String, dynamic>;
        } else {
          // error handling
          print("Error_api: Key 'rates' tidak ditemukan");
          return null;
        }
      } else {
        print("Error_api: Server merespon ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error_api: $e");
      return null;
    }
  }
}
