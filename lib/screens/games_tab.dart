import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/game_model.dart';
import '../utils/database_helper.dart';
import '../utils/app_theme.dart';
import 'game_detail_screen.dart';

class GamesTab extends StatefulWidget {
  const GamesTab({Key? key}) : super(key: key);

  @override
  _GamesTabState createState() => _GamesTabState();
}

class _GamesTabState extends State<GamesTab> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Game> _allGames = [];
  List<Game> _filteredGames = [];

  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Full Game',
    'DLC / Expansion',
    'In-Game Currency',
  ];
  String? _selectedCategory;

  final _priceFormat = NumberFormat.currency(locale: 'en_US', symbol: "\$");

  @override
  void initState() {
    super.initState();
    _loadGames();
    _searchController.addListener(_filterGames);
  }

  void _loadGames() async {
    final games = await _dbHelper.getAllGames();
    setState(() {
      _allGames = games;
      _filteredGames = games;
    });
  }

  void _filterGames() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredGames = _allGames.where((game) {
        final titleMatches = game.title.toLowerCase().contains(query);
        final categoryMatches =
            _selectedCategory == null || game.category == _selectedCategory;
        return titleMatches && categoryMatches;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4),
        itemCount: _categories.length + 1,
        separatorBuilder: (context, index) => SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return ChoiceChip(
              label: Text('🎮 Semua'),
              selected: _selectedCategory == null,
              selectedColor: kPrimaryColor,
              backgroundColor: Colors.grey[100],
              labelStyle: TextStyle(
                color: _selectedCategory == null
                    ? Colors.white
                    : kTextPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = null;
                  _filterGames();
                });
              },
            );
          }

          final category = _categories[index - 1];
          String emoji = index == 1
              ? '🎯'
              : index == 2
              ? '🎁'
              : '💰';

          return ChoiceChip(
            label: Text('$emoji $category'),
            selected: _selectedCategory == category,
            selectedColor: kPrimaryColor,
            backgroundColor: Colors.grey[100],
            labelStyle: TextStyle(
              color: _selectedCategory == category
                  ? Colors.white
                  : kTextPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedCategory = category;
                }
                _filterGames();
              });
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBackgroundColor,
      child: Column(
        children: [
          // Header Card dengan Search
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎮 Jelajahi Game Deals',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kTextPrimaryColor,
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari game favoritmu...',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: kPrimaryColor,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: kTextSecondaryColor),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                _buildCategoryChips(),
              ],
            ),
          ),
          Divider(height: 1),
          // Game List
          Expanded(
            child: _allGames.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.videogame_asset_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Database kosong',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: kTextSecondaryColor),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Jalankan "Sync" di tab profil',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : _filteredGames.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Game tidak ditemukan',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: kTextSecondaryColor),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _filteredGames.length,
                    itemBuilder: (context, index) {
                      final game = _filteredGames[index];
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.symmetric(vertical: 6),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    GameDetailScreen(game: game),
                              ),
                            ).then((_) => _loadGames());
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Game Thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: game.thumb != null
                                      ? Image.network(
                                          game.thumb!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Container(
                                                  width: 100,
                                                  height: 100,
                                                  color: Colors.grey[200],
                                                  child: Icon(
                                                    Icons.gamepad,
                                                    color: kPrimaryColor,
                                                    size: 32,
                                                  ),
                                                );
                                              },
                                        )
                                      : Container(
                                          width: 100,
                                          height: 100,
                                          color: Colors.grey[200],
                                          child: Icon(
                                            Icons.gamepad,
                                            color: kPrimaryColor,
                                            size: 32,
                                          ),
                                        ),
                                ),
                                SizedBox(width: 12),
                                // Game Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        game.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: kTextPrimaryColor,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 6),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: kPrimaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          game.category,
                                          style: TextStyle(
                                            color: kPrimaryColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            _priceFormat.format(game.salePrice),
                                            style: TextStyle(
                                              color: kSuccessColor,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          if (game.normalPrice > game.salePrice)
                                            Text(
                                              _priceFormat.format(
                                                game.normalPrice,
                                              ),
                                              style: TextStyle(
                                                color: kTextSecondaryColor,
                                                fontSize: 14,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: kTextSecondaryColor,
                                  size: 18,
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
      ),
    );
  }
}
