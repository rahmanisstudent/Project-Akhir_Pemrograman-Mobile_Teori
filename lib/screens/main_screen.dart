import 'package:flutter/material.dart';
import 'package:pixelnomics_stable/screens/login_screen.dart';
import 'package:pixelnomics_stable/services/auth_service.dart';
import 'package:pixelnomics_stable/services/notification_service.dart';
import 'games_tab.dart';
import 'feedback_screen.dart';
import 'wishlist_screen.dart';
import 'voucher_tab.dart';
import 'package:pixelnomics_stable/services/api_service.dart';
import 'package:pixelnomics_stable/utils/database_helper.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    GamesTab(),
    VoucherTab(),
    ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PixelNomics')),
      body: _widgetOptions.elementAt(_selectedIndex),

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.gamepad), label: 'Games'),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Cari Voucher',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

// --- Widget untuk Tab Profil ---
class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  _ProfileTabState createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final AuthService _authService = AuthService();

  final ApiService _apiService = ApiService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _isSyncing = false;

  Widget _buildUsername() {
    return FutureBuilder<String?>(
      future: _authService.getUsername(), // Panggil fungsi getUsername
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(
            'Memuat...',
            style: Theme.of(context).textTheme.headlineSmall,
          );
        }
        if (snapshot.hasError) {
          return Text(
            'Error',
            style: Theme.of(context).textTheme.headlineSmall,
          );
        }
        // Jika berhasil, tampilkan username
        String username = snapshot.data ?? 'Tamu';
        return Text(
          'Selamat Datang, $username!',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      // 1. KITA CEK ROLE DULU
      future: _authService.getRole(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Tampilkan loading saat cek role
          return Center(child: CircularProgressIndicator());
        }

        // Tentukan apakah user ini admin
        final bool isAdmin = (snapshot.data == 'admin');

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Tampilkan Username (fungsi ini sudah ada)
              _buildUsername(),

              SizedBox(height: 30),

              // 2. Tombol Wishlist (sudah ada)
              ElevatedButton.icon(
                icon: Icon(Icons.favorite),
                label: Text('Lihat Wishlist Saya'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WishlistScreen()),
                  );
                },
              ),
              SizedBox(height: 10),

              // 3. Tombol Kesan Pesan (sudah ada)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FeedbackScreen()),
                  );
                },
                child: Text('Kirim Kesan & Pesan'),
              ),

              SizedBox(height: 10),

              // 4. Tombol Logout (sudah ada)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  await _authService.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
                  );
                },
                child: Text('Logout'),
              ),

              SizedBox(height: 20),

              // 5. Tombol Tes Notifikasi (sudah ada)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: () {
                  NotificationService().showTestNotification();
                },
                child: Text('Tes Notifikasi (Demo)'),
              ),

              // --- 6. TOMBOL ADMIN BARU (INTI DARI Visi #2) ---
              // Gunakan Visibility untuk menampilkan tombol hanya jika admin
              Visibility(
                visible: isAdmin, // HANYA TAMPIL JIKA ADMIN
                child: Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.sync),
                    label: _isSyncing
                        ? Text('Sinkronisasi...')
                        : Text('Sync Data Game (Admin)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                    // Nonaktifkan tombol saat sedang loading
                    onPressed: _isSyncing
                        ? null
                        : () async {
                            setState(() {
                              _isSyncing = true; // Mulai loading
                            });

                            // Tampilkan snackbar BUKAN di context ini
                            final scaffoldMessenger = ScaffoldMessenger.of(
                              context,
                            );

                            try {
                              // 1. Panggil API
                              final games = await _apiService.getGameDeals();

                              // 2. Simpan ke DB
                              if (games.isNotEmpty) {
                                await _dbHelper.cacheGames(games);
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Sinkronisasi ${games.length} game berhasil!',
                                    ),
                                  ),
                                );
                              } else {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Gagal mengambil data dari API.',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }

                            setState(() {
                              _isSyncing = false; // Selesai loading
                            });
                          },
                  ),
                ),
              ),
              // ------------------------------------------------
            ],
          ),
        );
      },
    );
  }
}
