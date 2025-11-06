import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/game_model.dart';
import '../utils/database_helper.dart';
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

  // --- STATE BARU UNTUK FILTER ---
  final List<String> _categories = [
    'Full Game',
    'DLC / Expansion',
    'In-Game Currency',
  ];
  String? _selectedCategory; // Kategori yang sedang dipilih
  // ------------------------------

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

  // --- PERBARUI FUNGSI FILTER ---
  void _filterGames() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredGames = _allGames.where((game) {
        // Cek 1: Apakah judulnya cocok?
        final titleMatches = game.title.toLowerCase().contains(query);

        // Cek 2: Apakah kategorinya cocok?
        final categoryMatches =
            _selectedCategory == null || game.category == _selectedCategory;

        return titleMatches && categoryMatches; // Keduanya harus benar
      }).toList();
    });
  }
  // -----------------------------

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- WIDGET BARU UNTUK CHIPS KATEGORI ---
  Widget _buildCategoryChips() {
    return Container(
      height: 50, // Beri tinggi tetap
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length + 1, // +1 untuk tombol "Semua"
        separatorBuilder: (context, index) => SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            // Tombol "Semua"
            return ChoiceChip(
              label: Text('Semua'),
              selected: _selectedCategory == null,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = null; // Hapus filter
                  _filterGames(); // Jalankan ulang filter
                });
              },
            );
          }

          final category = _categories[index - 1];
          return ChoiceChip(
            label: Text(category),
            selected: _selectedCategory == category,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedCategory = category;
                }
                _filterGames(); // Jalankan ulang filter
              });
            },
          );
        },
      ),
    );
  }
  // -------------------------------------

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // --- KOTAK PENCARIAN ---
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Cari Game ...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
          SizedBox(height: 10),

          // --- TAMBAHKAN UI CHIPS KATEGORI ---
          _buildCategoryChips(),
          SizedBox(height: 5),
          Divider(),
          // -----------------------------------

          // --- DAFTAR GAME (ListView) ---
          Expanded(
            child: _allGames.isEmpty
                ? Center(
                    child: Text(
                      'Database kosong. Jalankan "Sync" di tab profil (jika admin).',
                    ),
                  )
                : _filteredGames.isEmpty
                ? Center(child: Text('Game tidak ditemukan.'))
                : ListView.builder(
                    itemCount: _filteredGames.length,
                    itemBuilder: (context, index) {
                      final game = _filteredGames[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          leading: game.thumb != null
                              ? Image.network(
                                  game.thumb!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.gamepad);
                                  },
                                )
                              : Icon(Icons.gamepad),

                          title: Text(game.title),

                          subtitle: Text(
                            // Tampilkan harga DAN kategori baru kita
                            "${_priceFormat.format(game.salePrice)}  -  (${game.category})",
                            style: TextStyle(color: Colors.greenAccent),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    GameDetailScreen(game: game),
                              ),
                            ).then((_) => _loadGames());
                          },
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
