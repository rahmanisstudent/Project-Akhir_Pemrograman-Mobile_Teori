import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/game_model.dart';
import '../services/api_service.dart';
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
  final ApiService _apiService = ApiService();

  late Future<List<dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    // Inisialisasi _dataFuture dengan Future kosong
    _dataFuture = Future.value([]);
    _loadData();
  }

  void _loadData() async {
    final userId = await _authService.getUserId();
    if (userId != null) {
      setState(() {
        _dataFuture = Future.wait([
          _dbHelper.getMyWishlist(
            userId,
          ), // Memanggil fungsi DB yang sudah benar
          _apiService.getRates(), // Memanggil API Kurs
        ]);
      });
    }
  }

  // --- 3. PERBAIKI FUNGSI KALKULASI TOTAL ---
  // Logika ini jadi jauh lebih sederhana karena semua harga game sekarang dalam USD
  double _calculateTotal(List<Game> games, Map<String, dynamic>? rates) {
    // Cek jika API kurs gagal atau tidak ada data IDR
    if (rates == null || !rates.containsKey('IDR')) return 0.0;

    double totalIdr = 0.0;
    double idrRate = rates['IDR'].toDouble();

    for (var game in games) {
      // Kita jumlahkan HARGA DISKON (salePrice) untuk total wishlist
      totalIdr += game.salePrice * idrRate;
    }
    return totalIdr;
  }

  // (Fungsi format total ini sudah benar, tidak perlu diubah)
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
      body: FutureBuilder<List<dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final List<Game> wishlistGames = snapshot.data![0];
          final Map<String, dynamic>? rates = snapshot.data![1];

          if (wishlistGames.isEmpty) {
            return Center(child: Text("Wishlist kamu masih kosong."));
          }

          final double totalCost = _calculateTotal(wishlistGames, rates);

          return Column(
            children: [
              // --- KARTU TOTAL (Sudah Benar) ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.green[800],
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  // ... (UI Total Cost tidak berubah) ...
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

              // --- 4. PERBAIKI LISTVIEW ---
              Expanded(
                child: ListView.builder(
                  itemCount: wishlistGames.length,
                  itemBuilder: (context, index) {
                    final game = wishlistGames[index];
                    return ListTile(
                      // Gunakan 'thumb'
                      leading: game.thumb != null
                          ? Image.network(
                              game.thumb!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, e, s) =>
                                  Icon(Icons.gamepad),
                            )
                          : Icon(Icons.gamepad),
                      // Gunakan 'title'
                      title: Text(game.title),
                      // Tampilkan harga diskon individu
                      subtitle: Text(
                        "Diskon: Rp ${_formatTotal(game.salePrice * (rates?['IDR'] ?? 0.0))}",
                        style: TextStyle(color: Colors.greenAccent),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GameDetailScreen(game: game),
                          ),
                          // Refresh halaman ini saat kita kembali
                        ).then((_) => _loadData());
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
