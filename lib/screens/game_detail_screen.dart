import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/game_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart'; // <-- 1. IMPORT BARU
import '../utils/database_helper.dart'; // <-- 2. IMPORT BARU

class GameDetailScreen extends StatefulWidget {
  // <-- 3. UBAH JADI StatefulWidget
  final Game game;

  const GameDetailScreen({Key? key, required this.game}) : super(key: key);

  @override
  _GameDetailScreenState createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  final ApiService _apiService = ApiService();
  final DatabaseHelper _dbHelper =
      DatabaseHelper.instance; // <-- 4. TAMBAHKAN DB HELPER
  final AuthService _authService =
      AuthService(); // <-- 5. TAMBAHKAN AUTH SERVICE

  double? _convertedPrice;
  String? _errorMessage;
  Map<String, dynamic>? _rates;

  // --- STATE BARU UNTUK WISHLIST ---
  bool _isInWishlist = false; // Untuk melacak status wishlist
  int? _currentUserId; // Untuk menyimpan ID user yang login
  // ---------------------------------

  @override
  void initState() {
    super.initState();
    // Panggil SEMUA data yang kita butuhkan saat layar dibuka
    _loadAllData();
  }

  void _loadAllData() async {
    // 1. Ambil User ID
    _currentUserId = await _authService.getUserId();

    // 2. Cek status wishlist (hanya jika user ID ada)
    if (_currentUserId != null) {
      bool status = await _dbHelper.isGameInWishlist(
        _currentUserId!,
        widget.game.id,
      );
      setState(() {
        _isInWishlist = status;
      });
    }

    // 3. Panggil API (fungsi ini sudah ada sebelumnya)
    _fetchRatesAndConvert();
  }

  void _fetchRatesAndConvert() async {
    // ... (Fungsi ini SAMA PERSIS seperti sebelumnya, tidak perlu diubah) ...
    // ... (Biarkan apa adanya) ...
    setState(() {
      _errorMessage = null;
    });
    _rates = await _apiService.getRates();
    if (_rates == null) {
      setState(() {
        _errorMessage = "Gagal memuat kurs. Cek koneksi internet.";
      });
      return;
    }
    if (widget.game.currencyCode == "IDR") {
      _convertedPrice = widget.game.price;
    } else {
      if (_rates!.containsKey(widget.game.currencyCode)) {
        double gameRate = _rates![widget.game.currencyCode].toDouble();
        double idrRate = _rates!['IDR'].toDouble();
        _convertedPrice = (widget.game.price * idrRate) / gameRate;
      } else {
        _errorMessage =
            "Kurs untuk ${widget.game.currencyCode} tidak ditemukan.";
      }
    }
    setState(() {});
  }

  // --- FUNGSI BARU UNTUK TOMBOL WISHLIST ---
  void _toggleWishlist() async {
    if (_currentUserId == null) return; // Seharusnya tidak terjadi

    if (_isInWishlist) {
      // Jika sudah ada, HAPUS
      await _dbHelper.removeFromWishlist(_currentUserId!, widget.game.id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Dihapus dari wishlist.')));
    } else {
      // Jika belum ada, TAMBAH
      await _dbHelper.addToWishlist(_currentUserId!, widget.game.id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Disimpan ke wishlist!')));
    }

    // Update status tombol
    setState(() {
      _isInWishlist = !_isInWishlist;
    });
  }

  // ... (Biarkan fungsi _formatOriginalPrice, _formatConvertedPrice, _getConvertedTime) ...
  // ... (SAMA PERSIS seperti sebelumnya) ...
  String _formatOriginalPrice() {
    final format = NumberFormat.currency(
      locale: 'en_US',
      symbol: widget.game.currencyCode == "USD"
          ? "\$"
          : widget.game.currencyCode == "JPY"
          ? "¥"
          : widget.game.currencyCode == "IDR"
          ? "Rp "
          : widget.game.currencyCode + " ",
      decimalDigits: widget.game.currencyCode == "IDR" ? 0 : 2,
    );
    return format.format(widget.game.price);
  }

  String _formatConvertedPrice() {
    if (_convertedPrice == null) return "Menghitung...";

    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: "Rp ",
      decimalDigits: 0,
    );
    return format.format(_convertedPrice);
  }

  String _getConvertedTime() {
    DateTime utcTime = DateTime.now().toUtc();
    DateTime gameTime = utcTime.add(
      Duration(hours: widget.game.timeZoneOffset),
    );
    return DateFormat('HH:mm').format(gameTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.game.name),
        // --- TOMBOL AKSI BARU DI APPBAR ---
        actions: [
          IconButton(
            // Tampilkan ikon berbeda berdasarkan status _isInWishlist
            icon: Icon(
              _isInWishlist ? Icons.favorite : Icons.favorite_border,
              color: _isInWishlist ? Colors.red : Colors.white,
            ),
            onPressed: _toggleWishlist, // Panggil fungsi toggle
          ),
        ],
        // ----------------------------------
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // <-- 6. TAMBAHKAN SingleChildScrollView
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ... (Semua widget Image, Text, Divider di sini SAMA PERSIS) ...
              // ... (Tidak ada yang berubah di dalam body) ...
              if (widget.game.imageUrl != null)
                Image.network(
                  widget.game.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[800],
                      child: Center(child: Icon(Icons.image_not_supported)),
                    );
                  },
                ),
              SizedBox(height: 20),
              Text(
                "Harga Asli (${widget.game.store}):",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                _formatOriginalPrice(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Estimasi Harga (IDR):",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              _errorMessage != null
                  ? Text(_errorMessage!, style: TextStyle(color: Colors.red))
                  : Text(
                      _formatConvertedPrice(),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                          ),
                    ),
              SizedBox(height: 30),
              Divider(),
              SizedBox(height: 20),
              Text(
                "Perkiraan Waktu Server/Event Saat Ini:",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                _getConvertedTime(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                "(Zona Waktu: GMT${widget.game.timeZoneOffset >= 0 ? '+' : ''}${widget.game.timeZoneOffset})",
              ),
              Text(
                "Waktu Lokal Anda (WIB): ${DateFormat('HH:mm').format(DateTime.now())}",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
