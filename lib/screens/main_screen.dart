import 'package:flutter/material.dart';
import 'package:pixelnomics_stable/screens/login_screen.dart';
import 'package:pixelnomics_stable/services/auth_service.dart';
import 'package:pixelnomics_stable/services/notification_service.dart';
import 'games_tab.dart';
import 'wishlist_screen.dart';
import 'voucher_tab.dart';
import 'package:pixelnomics_stable/services/api_service.dart';
import 'package:pixelnomics_stable/utils/database_helper.dart';
import 'edit_profile_screen.dart';
import 'package:pixelnomics_stable/utils/app_theme.dart';

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
  // Service yang kita butuhkan
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // State untuk data
  late Future<Map<String, dynamic>?> _userDataFuture;
  bool _isSyncing = false;
  int? _currentUserId; // Simpan User ID

  @override
  void initState() {
    super.initState();
    // Panggil data saat tab pertama kali dibuka
    _loadUserData();
  }

  // Fungsi baru untuk mengambil data user dari DB v5
  void _loadUserData() async {
    // 1. Ambil ID dari session
    _currentUserId = await _authService.getUserId();
    if (_currentUserId != null) {
      // 2. Set Future untuk mengambil data lengkap dari DB
      setState(() {
        _userDataFuture = _dbHelper.getUserData(_currentUserId!);
      });
    }
  }

  // Fungsi untuk Sync data (sama seperti sebelumnya)
  void _syncData() async {
    setState(() {
      _isSyncing = true;
    });
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final games = await _apiService.getGameDeals();
      if (games.isNotEmpty) {
        await _dbHelper.cacheGames(games);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Sinkronisasi ${games.length} game berhasil!'),
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Gagal mengambil data dari API.')),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() {
      _isSyncing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan FutureBuilder untuk menunggu data user
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(child: Text('Gagal memuat data profil.'));
        }

        // --- Data user sudah siap ---
        final userData = snapshot.data!;
        final String role =
            userData[DatabaseHelper.tableUsersColRole] ?? 'user';
        final String username =
            userData[DatabaseHelper.tableUsersColUsername] ?? 'Tamu';
        // Gunakan nama lengkap, fallback ke username
        final String displayName =
            userData[DatabaseHelper.tableUsersColFullName] ?? username;
        final String? picturePath =
            userData[DatabaseHelper.tableUsersColPicturePath];

        return Padding(
          padding: const EdgeInsets.all(16.0),
          // Gunakan ListView agar bisa di-scroll
          child: ListView(
            children: [
              // --- 1. TAMPILKAN GAMBAR PROFIL ---
              Center(
                // CircleAvatar untuk gambar profil
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[700],
                  // Tampilkan gambar dari network (jika ada),
                  // jika tidak, tampilkan inisial nama
                  backgroundImage:
                      (picturePath != null && picturePath.isNotEmpty)
                      ? NetworkImage(picturePath)
                      : null,
                  child: (picturePath == null || picturePath.isEmpty)
                      ? Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(fontSize: 40, color: Colors.white),
                        )
                      : null,
                ),
              ),
              SizedBox(height: 10),

              // --- 2. TAMPILKAN NAMA LENGKAP ---
              Text(
                'Selamat Datang, $displayName!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),

              // --- 3. TOMBOL EDIT PROFIL ---
              ElevatedButton.icon(
                icon: Icon(Icons.edit),
                label: Text('Edit Profil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                onPressed: () {
                  // Pindah ke layar EditProfileScreen
                  // Kita gunakan .then() agar profil otomatis refresh
                  // saat kita kembali dari halaman edit
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(),
                    ),
                  ).then((_) {
                    // Muat ulang data user setelah kembali
                    _loadUserData();
                  });
                },
              ),
              SizedBox(height: 10),

              // --- 4. TOMBOL WISHLIST (sudah ada) ---
              ElevatedButton.icon(
                icon: Icon(Icons.favorite),
                label: Text('Lihat Wishlist Saya'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.onError,
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WishlistScreen()),
                  );
                },
              ),
              SizedBox(height: 10),

              // 6. Tombol Logout
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kCardColor,
                  foregroundColor: kErrorColor,
                  side: BorderSide(color: kErrorColor),
                ),
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

              // 7. Tombol Tes Notifikasi
              ElevatedButton(
                onPressed: () {
                  NotificationService().showTestNotification();
                },
                child: Text('Tes Notifikasi (Demo)'),
              ),

              // 8. Tombol Admin Sync
              Visibility(
                visible: role == 'admin', // Tampil hanya jika admin
                child: Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.sync),
                    label: _isSyncing
                        ? Text('Sinkronisasi...')
                        : Text('Sync Data Game (Admin)'),
                    onPressed: _isSyncing ? null : _syncData,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
