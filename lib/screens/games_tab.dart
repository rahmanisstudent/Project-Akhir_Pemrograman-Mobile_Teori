import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../utils/database_helper.dart';
import 'game_detail_screen.dart';

// 1. Ubah menjadi StatefulWidget
class GamesTab extends StatefulWidget {
  const GamesTab({Key? key}) : super(key: key);

  @override
  _GamesTabState createState() => _GamesTabState();
}

class _GamesTabState extends State<GamesTab> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Variabel untuk menyimpan daftar game asli dari DB
  List<Game> _allGames = [];
  // Variabel untuk menyimpan daftar game yang sudah difilter
  List<Game> _filteredGames = [];

  // Controller untuk kotak pencarian
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Panggil data DB saat layar pertama kali dibuka
    _loadGames();

    // Tambahkan listener ke controller pencarian
    _searchController.addListener(_filterGames);
  }

  // Fungsi untuk mengambil data dari DB dan menyimpannya di state
  void _loadGames() async {
    final games = await _dbHelper.getAllGames();
    setState(() {
      _allGames = games;
      _filteredGames = games; // Awalnya, daftar filter = semua game
    });
  }

  // Fungsi yang akan dipanggil setiap kali pengguna mengetik
  void _filterGames() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredGames = _allGames.where((game) {
        // Cek apakah nama game mengandung teks pencarian
        return game.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    // Bersihkan controller saat widget ditutup
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Kita tidak lagi pakai FutureBuilder, karena data sudah ada di state

    // Tampilkan loading jika _allGames masih kosong
    if (_allGames.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    // Tampilan utama dengan Search Bar
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // --- KOTAK PENCARIAN ---
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

          // --- DAFTAR GAME (ListView) ---
          Expanded(
            child: _filteredGames.isEmpty
                ? Center(child: Text('Game tidak ditemukan.'))
                : ListView.builder(
                    itemCount: _filteredGames.length,
                    itemBuilder: (context, index) {
                      final game = _filteredGames[index];
                      return ListTile(
                        leading: game.imageUrl != null
                            ? Image.network(
                                game.imageUrl!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.gamepad);
                                },
                              )
                            : Icon(Icons.gamepad),
                        title: Text(game.name),
                        subtitle: Text(game.store),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  GameDetailScreen(game: game),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
