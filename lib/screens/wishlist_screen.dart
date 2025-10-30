import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format Rupiah
import '../models/game_model.dart';
import '../services/api_service.dart'; // <- Butuh API
import '../services/auth_service.dart';
import '../utils/database_helper.dart';
import 'game_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({Key? key}) : super(key: key);

  @override
  _WishlistScreenState createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService(); // <-- 1. Tambahkan API Service

  // Kita akan menunggu 'List' dari 2 data:
  // data[0] akan berisi List<Game> (dari DB)
  // data[1] akan berisi Map<String, dynamic> (dari API)
  late Future<List<dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    // Ambil user ID
    final userId = await _authService.getUserId();
    if (userId != null) {
      setState(() {
        // 2. Gunakan Future.wait untuk menunggu 2 data sekaligus
        _dataFuture = Future.wait([
          _dbHelper.getMyWishlist(userId), // Future 1: Ambil data DB
          _apiService.getRates(), // Future 2: Ambil data API
        ]);
      });
    }
  }

  // --- 3. FUNGSI BARU UNTUK KALKULASI TOTAL ---
  double _calculateTotal(List<Game> games, Map<String, dynamic>? rates) {
    if (rates == null) return 0.0; // Gagal dapat API

    double totalIdr = 0.0;
    double idrRate = rates['IDR'].toDouble();

    for (var game in games) {
      if (game.currencyCode == 'IDR') {
        totalIdr += game.price;
      } else if (rates.containsKey(game.currencyCode)) {
        double gameRate = rates[game.currencyCode].toDouble();
        // Konversi harga game ke USD dulu, baru ke IDR
        double priceInUsd = game.price / gameRate;
        totalIdr += priceInUsd * idrRate;
      }
    }
    return totalIdr;
  }

  // --- 4. FUNGSI BARU UNTUK FORMAT TOTAL ---
  String _formatTotal(double total) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: "Rp ",
      decimalDigits: 0,
    );
    return format.format(total);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Wishlist Saya')),
      // 5. Ubah FutureBuilder
      body: FutureBuilder<List<dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // --- 6. Ambil data dari hasil Future.wait ---
          final List<Game> wishlistGames = snapshot.data![0];
          final Map<String, dynamic>? rates = snapshot.data![1];

          if (wishlistGames.isEmpty) {
            return Center(child: Text("Wishlist kamu masih kosong."));
          }

          // --- 7. Hitung totalnya ---
          final double totalCost = _calculateTotal(wishlistGames, rates);

          // --- 8. Tampilkan UI-nya ---
          return Column(
            children: [
              // --- KARTU TOTAL ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.green[800],
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Estimasi Biaya Wishlist:',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    Text(
                      _formatTotal(totalCost),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // --- LISTVIEW ---
              Expanded(
                child: ListView.builder(
                  itemCount: wishlistGames.length,
                  itemBuilder: (context, index) {
                    final game = wishlistGames[index];
                    return ListTile(
                      leading: game.imageUrl != null
                          ? Image.network(
                              game.imageUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, e, s) =>
                                  Icon(Icons.gamepad),
                            )
                          : Icon(Icons.gamepad),
                      title: Text(game.name),
                      subtitle: Text(game.store),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GameDetailScreen(game: game),
                          ),
                        ).then((_) => _loadData()); // Refresh saat kembali
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
