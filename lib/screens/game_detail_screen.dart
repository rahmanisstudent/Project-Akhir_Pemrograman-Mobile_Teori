import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/game_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/database_helper.dart';
import 'package:timezone/timezone.dart' as tz;

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

  // State untuk harga konversi
  double? _convertedSalePrice;
  double? _convertedNormalPrice;
  String? _errorMessage;
  Map<String, dynamic>? _rates;

  // State untuk Wishlist
  bool _isInWishlist = false;
  int? _currentUserId;

  // --- STATE BARU UNTUK KOMENTAR ---
  final _commentController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _commentsFuture;
  // ---------------------------------

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
      bool status = await _dbHelper.isGameInWishlist(
        _currentUserId!,
        widget.game.dealID,
      );
      setState(() {
        _isInWishlist = status;
      });
    }

    // 3. Panggil API Kurs Mata Uang
    _fetchRatesAndConvert();

    // 4. PANGGIL KOMENTAR
    _loadComments();
  }

  // --- FUNGSI BARU: Memuat daftar komentar ---
  void _loadComments() {
    setState(() {
      _commentsFuture = _dbHelper.getCommentsForGame(widget.game.dealID);
    });
  }

  // --- FUNGSI BARU: Mengirim komentar ---
  Future<void> _postComment() async {
    if (_commentController.text.isEmpty || _currentUserId == null) {
      return; // Jangan kirim jika kosong atau user tidak login
    }

    // Simpan ke DB
    await _dbHelper.addComment(
      _currentUserId!,
      widget.game.dealID,
      _commentController.text,
    );

    // Kosongkan TextField
    _commentController.clear();
    // Tutup keyboard
    FocusScope.of(context).unfocus();
    // Muat ulang daftar komentar
    _loadComments();
  }

  // (Fungsi _fetchRatesAndConvert, _toggleWishlist, _formatConvertedPrice, _formatUsdPrice
  //  TETAP SAMA seperti sebelumnya, tidak ada perubahan)

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
      // --- PERBAIKAN: Gunakan Column, bukan Padding + SingleChildScrollView ---
      body: Column(
        children: [
          // --- BAGIAN ATAS: Info Game (Bisa di-scroll) ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // (Semua widget Image, Text, Divider di sini SAMA)
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

                  // --- BAGIAN BARU: Daftar Komentar ---
                  Text(
                    "Komentar Pengguna",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 10),
                  _buildCommentList(),
                  // ---------------------------------
                ],
              ),
            ),
          ),

          // --- BAGIAN BAWAH: Input Komentar (Tetap di bawah) ---
          _buildCommentInput(),
          // ----------------------------------------------------
        ],
      ),
    );
  }

  // --- WIDGET BARU: Untuk menampilkan daftar komentar ---
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

        // Gunakan ListView.builder agar efisien
        return ListView.builder(
          itemCount: comments.length,
          shrinkWrap: true, // Penting agar muat di dalam SingleChildScrollView
          physics:
              NeverScrollableScrollPhysics(), // Biar scroll utamanya yang jalan
          itemBuilder: (context, index) {
            final comment = comments[index];
            final String commentText =
                comment[DatabaseHelper.tableCommentsColComment];
            final String? fullName =
                comment[DatabaseHelper.tableUsersColFullName];
            final String? picturePath =
                comment[DatabaseHelper.tableUsersColPicturePath];
            final String? timestampString =
                comment[DatabaseHelper
                    .tableCommentsColTimestamp]; // <-- Ambil timestamp

            final String displayName = (fullName != null && fullName.isNotEmpty)
                ? fullName
                : 'User';

            // --- LOGIKA KONVERSI WAKTU ---
            String formattedTime = ''; // Default string kosong
            if (timestampString != null) {
              // 1. Parse string dari DB ke DateTime
              final DateTime utcTime = DateTime.parse(timestampString);

              // 2. Tentukan 4 zona waktu
              final tz.Location wib = tz.getLocation('Asia/Jakarta'); // WIB
              final tz.Location wita = tz.getLocation('Asia/Makassar'); // WITA
              final tz.Location wit = tz.getLocation('Asia/Jayapura'); // WIT
              final tz.Location london = tz.getLocation(
                'Europe/London',
              ); // London

              // 3. Konversi
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

              // 4. Buat string
              formattedTime =
                  'WIB: $wibTime | WITA: $witaTime | WIT: $witTime | London: $londonTime';
            }
            // --------------------------------

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

                // --- GANTI SUBTITLE-NYA ---
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(commentText), // Isi komentar
                    SizedBox(height: 4),
                    Text(
                      // Timestamp yang sudah dikonversi
                      formattedTime,
                      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                    ),
                  ],
                ),
                // ---------------------------
              ),
            );
          },
        );
      },
    );
  }

  // --- WIDGET BARU: Untuk input komentar ---
  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor, // Warna latar belakang
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
