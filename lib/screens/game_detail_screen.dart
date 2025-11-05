import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/game_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/database_helper.dart';

class GameDetailScreen extends StatefulWidget {
  final Game game; // Model Game baru kita

  const GameDetailScreen({Key? key, required this.game}) : super(key: key);

  @override
  _GameDetailScreenState createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  final ApiService _apiService = ApiService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AuthService _authService = AuthService();

  double? _convertedSalePrice;
  double? _convertedNormalPrice;
  String? _errorMessage;
  Map<String, dynamic>? _rates;

  bool _isInWishlist = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  void _loadAllData() async {
    // 1. Ambil User ID
    _currentUserId = await _authService.getUserId();

    // 2. Cek status wishlist
    if (_currentUserId != null) {
      // --- PERBAIKAN DI SINI ---
      // Gunakan 'widget.game.dealID' (String)
      bool status = await _dbHelper.isGameInWishlist(
        _currentUserId!,
        widget.game.dealID,
      );
      // -------------------------
      setState(() {
        _isInWishlist = status;
      });
    }

    // 3. Panggil API Kurs Mata Uang
    _fetchRatesAndConvert();
  }

  void _fetchRatesAndConvert() async {
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

    if (_rates!.containsKey('IDR')) {
      double idrRate = _rates!['IDR'].toDouble();
      _convertedSalePrice = widget.game.salePrice * idrRate;
      _convertedNormalPrice = widget.game.normalPrice * idrRate;
    } else {
      _errorMessage = "Kurs untuk IDR tidak ditemukan.";
    }

    setState(() {});
  }

  void _toggleWishlist() async {
    if (_currentUserId == null) return;

    // --- PERBAIKAN DI SINI ---
    // Gunakan 'widget.game.dealID' (String)
    if (_isInWishlist) {
      await _dbHelper.removeFromWishlist(_currentUserId!, widget.game.dealID);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Dihapus dari wishlist.')));
    } else {
      await _dbHelper.addToWishlist(_currentUserId!, widget.game.dealID);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Disimpan ke wishlist!')));
    }
    // -------------------------

    setState(() {
      _isInWishlist = !_isInWishlist;
    });
  }

  // (Fungsi format harga tidak berubah)
  String _formatConvertedPrice(double? priceInIdr) {
    if (priceInIdr == null) return "Menghitung...";
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: "Rp ",
      decimalDigits: 0,
    );
    return format.format(priceInIdr);
  }

  String _formatUsdPrice(double priceInUsd) {
    final format = NumberFormat.currency(locale: 'en_US', symbol: "\$");
    return format.format(priceInUsd);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.game.title),
        actions: [
          IconButton(
            icon: Icon(
              _isInWishlist ? Icons.favorite : Icons.favorite_border,
              color: _isInWishlist ? Colors.red : Colors.white,
            ),
            onPressed: _toggleWishlist,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.game.thumb != null)
                Image.network(
                  widget.game.thumb!,
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
                "Harga Diskon (Steam):",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                _formatConvertedPrice(_convertedSalePrice),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ),
              ),
              Text(
                "(${_formatUsdPrice(widget.game.salePrice)})",
                style: Theme.of(context).textTheme.bodyLarge,
              ),

              SizedBox(height: 20),

              Text(
                "Harga Normal:",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                _formatConvertedPrice(_convertedNormalPrice),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              Text(
                "(${_formatUsdPrice(widget.game.normalPrice)})",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  decoration: TextDecoration.lineThrough,
                ),
              ),

              SizedBox(height: 30),
              Divider(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
