import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

import '../models/game_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/database_helper.dart';

class GameDetailScreen extends StatefulWidget {
  final Game game;

  const GameDetailScreen({Key? key, required this.game}) : super(key: key);

  @override
  _GameDetailScreenState createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  final ApiService _apiService = ApiService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AuthService _authService = AuthService();

  // --- PELUANG EFISIENSI: Buat formatter satu kali saja ---
  final NumberFormat _idrFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: "Rp ",
    decimalDigits: 0,
  );
  final NumberFormat _usdFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: "\$",
  );
  // ---------------------------------------------------------

  double? _convertedSalePrice;
  double? _convertedNormalPrice;
  String? _errorMessage;
  Map<String, dynamic>? _rates;

  bool _isInWishlist = false;
  int? _currentUserId;

  final _commentController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _commentsFuture;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  void _loadAllData() async {
    _currentUserId = await _authService.getUserId();

    if (_currentUserId != null) {
      bool status = await _dbHelper.isGameInWishlist(
        _currentUserId!,
        widget.game.dealID,
      );
      setState(() {
        _isInWishlist = status;
      });
    }
    _fetchRatesAndConvert();
    _loadComments();
  }

  void _loadComments() {
    setState(() {
      _commentsFuture = _dbHelper.getCommentsForGame(widget.game.dealID);
    });
  }

  Future<void> _postComment() async {
    if (_commentController.text.isEmpty || _currentUserId == null) {
      return;
    }

    // --- PERBAIKAN BUG KRITIS ---
    String timestamp = DateTime.now().toUtc().toIso8601String();
    await _dbHelper.addComment(
      _currentUserId!,
      widget.game.dealID,
      _commentController.text,
      timestamp, // <-- TAMBAHKAN TIMESTAMP YANG HILANG
    );
    // ----------------------------

    _commentController.clear();
    FocusScope.of(context).unfocus();
    _loadComments();
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
    setState(() {
      _isInWishlist = !_isInWishlist;
    });
  }

  // --- EFISIENSI: Gunakan formatter yang sudah dibuat ---
  String _formatConvertedPrice(double? priceInIdr) {
    if (priceInIdr == null) return "Menghitung...";
    return _idrFormat.format(priceInIdr);
  }

  String _formatUsdPrice(double priceInUsd) {
    return _usdFormat.format(priceInUsd);
  }
  // ---------------------------------------------------

  Future<void> _launchDealUrl() async {
    final Uri url = Uri.parse(
      'https://www.cheapshark.com/redirect?dealID=${widget.game.dealID}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak bisa membuka link penawaran.')),
      );
    }
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
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
                      color: Theme.of(context).colorScheme.secondary,
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

                  SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.shopping_cart_checkout),
                      label: Text('Lihat Penawaran di Toko'),
                      onPressed: _launchDealUrl,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSecondary,
                      ),
                    ),
                  ),

                  SizedBox(height: 30),
                  Divider(),
                  SizedBox(height: 20),
                  Text(
                    "Komentar Pengguna",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 10),
                  _buildCommentList(),
                ],
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _commentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(child: Text('Belum ada komentar.')),
          );
        }

        final comments = snapshot.data!;

        return ListView.builder(
          itemCount: comments.length,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final comment = comments[index];
            final String commentText =
                comment[DatabaseHelper.tableCommentsColComment];
            final String? fullName =
                comment[DatabaseHelper.tableUsersColFullName];
            final String? picturePath =
                comment[DatabaseHelper.tableUsersColPicturePath];
            final String? timestampString =
                comment[DatabaseHelper.tableCommentsColTimestamp];

            final String displayName = (fullName != null && fullName.isNotEmpty)
                ? fullName
                : 'User';

            String formattedTime = '';
            if (timestampString != null) {
              final DateTime utcTime = DateTime.parse(timestampString);
              final tz.Location wib = tz.getLocation('Asia/Jakarta');
              final tz.Location wita = tz.getLocation('Asia/Makassar');
              final tz.Location wit = tz.getLocation('Asia/Jayapura');
              final tz.Location london = tz.getLocation('Europe/London');

              final String wibTime = DateFormat(
                'HH:mm',
              ).format(tz.TZDateTime.from(utcTime, wib));
              final String witaTime = DateFormat(
                'HH:mm',
              ).format(tz.TZDateTime.from(utcTime, wita));
              final String witTime = DateFormat(
                'HH:mm',
              ).format(tz.TZDateTime.from(utcTime, wit));
              final String londonTime = DateFormat(
                'HH:mm',
              ).format(tz.TZDateTime.from(utcTime, london));

              formattedTime =
                  'WIB: $wibTime | WITA: $witaTime | WIT: $witTime | London: $londonTime';
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[600],
                  backgroundImage:
                      (picturePath != null && picturePath.isNotEmpty)
                      ? NetworkImage(picturePath)
                      : null,
                  child: (picturePath == null || picturePath.isEmpty)
                      ? Text(displayName[0].toUpperCase())
                      : null,
                ),
                title: Text(
                  displayName,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(commentText),
                    SizedBox(height: 4),
                    Text(
                      formattedTime,
                      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Tulis komentar...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
              ),
            ),
          ),
          SizedBox(width: 8.0),
          IconButton(
            icon: Icon(
              Icons.send,
              color: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: _postComment,
          ),
        ],
      ),
    );
  }
}
