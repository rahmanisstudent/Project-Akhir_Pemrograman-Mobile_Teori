import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Kita butuh NumberFormat
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

  // Format harga (misal: 29.99) -> "$29.99"
  final _priceFormat = NumberFormat.currency(locale: 'en_US', symbol: "\$");

  @override
  void initState() {
    super.initState();
    _loadGames();
    _searchController.addListener(_filterGames);
  }

  // Penting: Panggil ini untuk me-refresh data setelah Admin Sync
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
        // GANTI 'game.name' menjadi 'game.title'
        return game.title.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tampilan utama dengan Search Bar
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Cari Game...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
          SizedBox(height: 10),

          // --- GANTI UI LISTVIEW ---
          Expanded(
            // Tampilkan loading HANYA jika _allGames belum diload
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
                        // <-- Gunakan Card agar lebih rapi
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          // Tampilkan gambar thumbnail dari API
                          leading: game.thumb != null
                              ? Image.network(
                                  game.thumb!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.gamepad); // Fallback
                                  },
                                )
                              : Icon(Icons.gamepad),

                          // Ganti 'name' jadi 'title'
                          title: Text(game.title),

                          // Tampilkan harga diskon
                          subtitle: Text(
                            // Format harga diskon
                            "Harga Diskon: ${_priceFormat.format(game.salePrice)}",
                            style: TextStyle(color: Colors.greenAccent),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    GameDetailScreen(game: game),
                              ),
                              // 'then' akan dipanggil saat kita kembali dari DetailScreen
                              // Ini untuk me-refresh status wishlist
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
