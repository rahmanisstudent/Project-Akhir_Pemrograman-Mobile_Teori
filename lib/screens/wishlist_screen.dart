import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/database_helper.dart';
import '../utils/app_theme.dart';
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
  double _monthlyBudget = 500000.0;
  String _sortBy = 'name';

  @override
  void initState() {
    super.initState();
    _dataFuture = Future.value([]);
    _loadBudget();
    _loadData();
  }

  Future<void> _loadBudget() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _monthlyBudget = prefs.getDouble('monthly_budget') ?? 500000.0;
    });
  }

  Future<void> _saveBudget(double budget) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthly_budget', budget);
    setState(() {
      _monthlyBudget = budget;
    });
  }

  void _showBudgetDialog() {
    final controller = TextEditingController(
      text: _monthlyBudget.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: kPrimaryColor),
            SizedBox(width: 8),
            Text('Set Budget Bulanan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Atur budget bulanan Anda untuk membeli game',
              style: TextStyle(color: kTextSecondaryColor),
            ),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Budget (Rp)',
                prefixIcon: Icon(Icons.money_rounded, color: kSuccessColor),
                helperText: 'Contoh: 500000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              double? newBudget = double.tryParse(controller.text);
              if (newBudget != null && newBudget > 0) {
                _saveBudget(newBudget);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Budget berhasil diatur!'),
                    backgroundColor: kSuccessColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.sort_rounded, color: kPrimaryColor),
            SizedBox(width: 8),
            Text('Urutkan Berdasarkan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortOption('name', 'Nama Game (A-Z)', Icons.abc_rounded),
            _buildSortOption(
              'price_low',
              'Harga Terendah',
              Icons.arrow_downward_rounded,
            ),
            _buildSortOption(
              'price_high',
              'Harga Tertinggi',
              Icons.arrow_upward_rounded,
            ),
            _buildSortOption(
              'discount',
              'Diskon Terbesar',
              Icons.local_offer_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String value, String label, IconData icon) {
    bool isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? kPrimaryColor : kTextSecondaryColor,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? kPrimaryColor : kTextPrimaryColor,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check, color: kPrimaryColor) : null,
      onTap: () {
        setState(() {
          _sortBy = value;
        });
        Navigator.pop(context);
        _loadData();
      },
    );
  }

  void _loadData() async {
    final userId = await _authService.getUserId();
    if (userId != null) {
      setState(() {
        _dataFuture = Future.wait([
          _dbHelper.getMyWishlist(userId),
          _apiService.getRates(),
        ]);
      });
    }
  }

  List<Game> _sortGames(List<Game> games, Map<String, dynamic>? rates) {
    List<Game> sorted = List.from(games);

    switch (_sortBy) {
      case 'name':
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'price_low':
        sorted.sort((a, b) => a.salePrice.compareTo(b.salePrice));
        break;
      case 'price_high':
        sorted.sort((a, b) => b.salePrice.compareTo(a.salePrice));
        break;
      case 'discount':
        sorted.sort((a, b) {
          double discountA = ((1 - a.salePrice / a.normalPrice) * 100);
          double discountB = ((1 - b.salePrice / b.normalPrice) * 100);
          return discountB.compareTo(discountA);
        });
        break;
    }

    return sorted;
  }

  double _calculateTotal(List<Game> games, Map<String, dynamic>? rates) {
    if (rates == null || !rates.containsKey('IDR')) return 0.0;

    double totalIdr = 0.0;
    double idrRate = rates['IDR'].toDouble();

    for (var game in games) {
      totalIdr += game.salePrice * idrRate;
    }
    return totalIdr;
  }

  String _formatPrice(double price) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: "Rp ",
      decimalDigits: 0,
    );
    return format.format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text('💙 My Wishlist'),
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.sort_rounded),
            tooltip: 'Urutkan',
            onPressed: _showSortDialog,
          ),
          IconButton(
            icon: Icon(Icons.account_balance_wallet_rounded),
            tooltip: 'Set Budget',
            onPressed: _showBudgetDialog,
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: kPrimaryColor),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: kErrorColor),
                  SizedBox(height: 16),
                  Text("Error: ${snapshot.error}"),
                ],
              ),
            );
          }

          List<Game> wishlistGames = snapshot.data![0];
          final Map<String, dynamic>? rates = snapshot.data![1];

          if (wishlistGames.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Wishlist kamu masih kosong",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: kTextSecondaryColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Tambahkan game favoritmu!",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          wishlistGames = _sortGames(wishlistGames, rates);
          final double totalCost = _calculateTotal(wishlistGames, rates);
          final double percentage = (totalCost / _monthlyBudget) * 100;
          final bool isOverBudget = totalCost > _monthlyBudget;

          return Column(
            children: [
              // Budget Tracker Card
              Container(
                margin: EdgeInsets.all(16),
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Wishlist',
                                  style: TextStyle(
                                    color: kTextSecondaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _formatPrice(totalCost),
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: isOverBudget
                                        ? kErrorColor
                                        : kSuccessColor,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    (isOverBudget ? kErrorColor : kSuccessColor)
                                        .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isOverBudget
                                    ? Icons.warning_rounded
                                    : Icons.check_circle_rounded,
                                color: isOverBudget
                                    ? kErrorColor
                                    : kSuccessColor,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Budget: ${_formatPrice(_monthlyBudget)}',
                              style: TextStyle(
                                color: kTextSecondaryColor,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(0)}% dari budget',
                              style: TextStyle(
                                color: isOverBudget
                                    ? kErrorColor
                                    : kPrimaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            minHeight: 10,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOverBudget ? kErrorColor : kSuccessColor,
                            ),
                          ),
                        ),
                        if (isOverBudget) ...[
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kErrorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: kErrorColor,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Wishlist melebihi budget bulanan!',
                                    style: TextStyle(
                                      color: kErrorColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Sort Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_rounded,
                      size: 16,
                      color: kTextSecondaryColor,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Diurutkan: ${_getSortLabel()}',
                      style: TextStyle(
                        color: kTextSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '${wishlistGames.length} Game',
                      style: TextStyle(
                        color: kTextSecondaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 8),

              // Game List
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: wishlistGames.length,
                  itemBuilder: (context, index) {
                    final game = wishlistGames[index];
                    final idrPrice = game.salePrice * (rates?['IDR'] ?? 0.0);
                    final discountPercent = game.normalPrice > 0
                        ? ((1 - game.salePrice / game.normalPrice) * 100)
                              .round()
                        : 0;

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  GameDetailScreen(game: game),
                            ),
                          ).then((_) => _loadData());
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: game.thumb != null
                                    ? Image.network(
                                        game.thumb!,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, e, s) =>
                                            _buildPlaceholder(),
                                      )
                                    : _buildPlaceholder(),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      game.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: kPrimaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        game.category,
                                        style: TextStyle(
                                          color: kPrimaryColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          _formatPrice(idrPrice),
                                          style: TextStyle(
                                            color: kSuccessColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (discountPercent > 0) ...[
                                          SizedBox(width: 8),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: kErrorColor,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '-$discountPercent%',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[200],
      child: Icon(Icons.gamepad, color: kPrimaryColor, size: 32),
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'name':
        return 'Nama (A-Z)';
      case 'price_low':
        return 'Harga Terendah';
      case 'price_high':
        return 'Harga Tertinggi';
      case 'discount':
        return 'Diskon Terbesar';
      default:
        return 'Default';
    }
  }
}
