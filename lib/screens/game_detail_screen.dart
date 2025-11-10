import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

import '../models/game_model.dart';
import '../models/currency_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/database_helper.dart';
import '../utils/app_theme.dart';

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

  Currency _userCurrency = Currency.getByCode('IDR');
  final NumberFormat _usdFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: "\$",
  );

  double? _convertedSalePrice;
  double? _convertedNormalPrice;
  String? _errorMessage;
  Map<String, dynamic>? _rates;
  String? _currentUserRole;

  bool _isInWishlist = false;
  int? _currentUserId;

  late Future<List<Map<String, dynamic>>> _commentsFuture;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  void _loadComments() {
    setState(() {
      _commentsFuture = _dbHelper.getCommentsForGame(widget.game.dealID);
    });
  }

  void _loadAllData() async {
    _currentUserId = await _authService.getUserId();

    if (_currentUserId != null) {
      final userData = await _dbHelper.getUserData(_currentUserId!);
      if (userData != null) {
        String currencyCode =
            userData[DatabaseHelper.tableUsersColPreferredCurrency] ?? 'IDR';
        _userCurrency = Currency.getByCode(currencyCode);
        _currentUserRole = userData[DatabaseHelper.tableUsersColRole] ?? 'user';
      }

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

  void _deleteComment(int commentId, int commentUserId) async {
    bool isAdmin = _currentUserRole == 'admin';
    bool isOwner = commentUserId == _currentUserId;

    if (!isAdmin && !isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Anda tidak memiliki izin untuk menghapus komentar ini!',
          ),
          backgroundColor: kErrorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: kErrorColor),
            SizedBox(width: 8),
            Text('Hapus Komentar?'),
          ],
        ),
        content: Text('Apakah Anda yakin ingin menghapus komentar ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kErrorColor),
            child: Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteComment(commentId);
      _loadComments();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Komentar berhasil dihapus!'),
          backgroundColor: kSuccessColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showCommentDialog() {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Anda harus login untuk berkomentar!'),
          backgroundColor: kErrorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.comment_rounded, color: kPrimaryColor, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Tulis Komentar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kTextPrimaryColor,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: kTextSecondaryColor),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                TextField(
                  controller: commentController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Bagikan pendapat Anda tentang game ini...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  autofocus: true,
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(bottomSheetContext),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: kTextSecondaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Batal',
                          style: TextStyle(color: kTextSecondaryColor),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.send_rounded),
                        label: Text('Kirim'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (commentController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Komentar tidak boleh kosong!'),
                                backgroundColor: kErrorColor,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          String timestamp = DateTime.now()
                              .toUtc()
                              .toIso8601String();
                          await _dbHelper.addComment(
                            _currentUserId!,
                            widget.game.dealID,
                            commentController.text.trim(),
                            timestamp,
                          );

                          Navigator.pop(bottomSheetContext);
                          _loadComments();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Komentar berhasil ditambahkan!'),
                              backgroundColor: kSuccessColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
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

    _convertedSalePrice = _userCurrency.convertFromUSD(
      widget.game.salePrice,
      _rates!,
    );
    _convertedNormalPrice = _userCurrency.convertFromUSD(
      widget.game.normalPrice,
      _rates!,
    );

    if (_convertedSalePrice == 0.0) {
      _errorMessage = "Kurs untuk ${_userCurrency.code} tidak ditemukan.";
    }
    setState(() {});
  }

  void _toggleWishlist() async {
    if (_currentUserId == null) return;
    if (_isInWishlist) {
      await _dbHelper.removeFromWishlist(_currentUserId!, widget.game.dealID);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💔 Dihapus dari wishlist'),
          backgroundColor: kTextSecondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      await _dbHelper.addToWishlist(_currentUserId!, widget.game.dealID);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❤️ Disimpan ke wishlist!'),
          backgroundColor: kSuccessColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
    setState(() {
      _isInWishlist = !_isInWishlist;
    });
  }

  String _formatConvertedPrice(double? price) {
    if (price == null) return "Menghitung...";
    return _userCurrency.format(price);
  }

  String _formatUsdPrice(double priceInUsd) {
    return _usdFormat.format(priceInUsd);
  }

  Future<void> _launchDealUrl() async {
    final Uri url = Uri.parse(
      'https://www.cheapshark.com/redirect?dealID=${widget.game.dealID}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak bisa membuka link penawaran.'),
          backgroundColor: kErrorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Uint8List _base64ToImage(String base64String) {
    String cleanBase64 = base64String.split(',').last;
    return base64Decode(cleanBase64);
  }

  @override
  Widget build(BuildContext context) {
    final discountPercent = widget.game.normalPrice > 0
        ? ((1 - widget.game.salePrice / widget.game.normalPrice) * 100).round()
        : 0;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.game.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(
              _isInWishlist ? Icons.favorite : Icons.favorite_border,
              color: _isInWishlist ? kErrorColor : kTextSecondaryColor,
            ),
            onPressed: _toggleWishlist,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.game.thumb != null)
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Image.network(
                  widget.game.thumb!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: kTextSecondaryColor,
                        ),
                      ),
                    );
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Harga Diskon',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: kTextSecondaryColor),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _formatConvertedPrice(_convertedSalePrice),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: kSuccessColor,
                                      ),
                                ),
                                Text(
                                  _formatUsdPrice(widget.game.salePrice),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: kTextSecondaryColor),
                                ),
                              ],
                            ),
                          ),
                          if (discountPercent > 0)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: kErrorColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '-$discountPercent%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (widget.game.normalPrice > widget.game.salePrice) ...[
                        SizedBox(height: 16),
                        Divider(),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Harga Normal: ',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: kTextSecondaryColor),
                            ),
                            Text(
                              _formatConvertedPrice(_convertedNormalPrice),
                              style: TextStyle(
                                color: kTextSecondaryColor,
                                fontSize: 16,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.shopping_cart_checkout_rounded, size: 24),
                  label: Text(
                    'Lihat Penawaran di Steam',
                    style: TextStyle(fontSize: 16),
                  ),
                  onPressed: _launchDealUrl,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),

            SizedBox(height: 24),
            Divider(thickness: 8, color: Colors.grey[200]),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '💬 Komentar Pengguna',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_comment_rounded, color: kPrimaryColor),
                    onPressed: _showCommentDialog,
                    tooltip: 'Tambah Komentar',
                  ),
                ],
              ),
            ),

            _buildCommentList(),
            SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCommentDialog,
        icon: Icon(Icons.add_comment_rounded),
        label: Text('Tulis Komentar'),
        backgroundColor: kPrimaryColor,
        elevation: 4,
      ),
    );
  }

  Widget _buildCommentList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _commentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: CircularProgressIndicator(color: kPrimaryColor),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada komentar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: kTextSecondaryColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Jadilah yang pertama berkomentar!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }

        final comments = snapshot.data!;

        return ListView.builder(
          itemCount: comments.length,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            final comment = comments[index];
            final int commentId = comment['comment_id'];
            final int commentUserId =
                comment[DatabaseHelper.tableCommentsColUserId];
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
              final String wibTime = DateFormat(
                'dd MMM yyyy, HH:mm',
              ).format(tz.TZDateTime.from(utcTime, wib));
              formattedTime = wibTime;
            }

            bool isAdmin = _currentUserRole == 'admin';
            bool isOwner = commentUserId == _currentUserId;
            bool canDelete = isAdmin || isOwner;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: kPrimaryColor.withOpacity(0.1),
                      backgroundImage:
                          (picturePath != null && picturePath.isNotEmpty)
                          ? (picturePath.startsWith('data:image')
                                ? MemoryImage(_base64ToImage(picturePath))
                                : NetworkImage(picturePath) as ImageProvider)
                          : null,
                      child: (picturePath == null || picturePath.isEmpty)
                          ? Text(
                              displayName[0].toUpperCase(),
                              style: TextStyle(
                                color: kPrimaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  displayName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: kTextPrimaryColor,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Text(
                                formattedTime,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: kTextSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            commentText,
                            style: TextStyle(
                              color: kTextPrimaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (canDelete)
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: kErrorColor,
                          size: 20,
                        ),
                        onPressed: () =>
                            _deleteComment(commentId, commentUserId),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
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
}
