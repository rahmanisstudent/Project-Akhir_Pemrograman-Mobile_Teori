import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/game_model.dart';

class ApiService {
  final String _exRatesApiUrl =
      "https://open.er-api.com/v6/latest/USD"; //exchange Rate - API

  Future<Map<String, dynamic>?> getRates() async {
    try {
      final response = await http.get(Uri.parse(_exRatesApiUrl));

      // control statement
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey('rates')) {
          return data['rates'] as Map<String, dynamic>;
        } else {
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

  final String _cheapSharkUrl =
      "https://www.cheapshark.com/api/1.0/deals?storeID=1&upperPrice=50&pageSize=50";

  Future<List<Game>> getGameDeals() async {
    try {
      final response = await http.get(Uri.parse(_cheapSharkUrl));

      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(response.body);

        List<Game> games = jsonList.map((jsonItem) {
          return Game.fromJson(jsonItem as Map<String, dynamic>);
        }).toList();

        return games;
      } else {
        print("Error_cheapshark: Server merespon ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error_cheapshark: $e");
      return [];
    }
  }
}
