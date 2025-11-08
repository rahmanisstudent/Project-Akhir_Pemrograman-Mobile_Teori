import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
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
    WishlistScreen(),
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
      appBar: AppBar(title: Text('PixelNomics'), elevation: 1),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.gamepad), label: 'Games'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Wishlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Voucher',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  _ProfileTabState createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  late Future<Map<String, dynamic>?> _userDataFuture;
  bool _isSyncing = false;
  int? _currentUserId;

  Uint8List _base64ToImage(String base64String) {
    String cleanBase64 = base64String.split(',').last;
    return base64Decode(cleanBase64);
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    _currentUserId = await _authService.getUserId();
    if (_currentUserId != null) {
      setState(() {
        _userDataFuture = _dbHelper.getUserData(_currentUserId!);
      });
    }
  }

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
            backgroundColor: kSuccessColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil data dari API.'),
            backgroundColor: kErrorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: kErrorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
    setState(() {
      _isSyncing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: kPrimaryColor));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: kErrorColor),
                SizedBox(height: 16),
                Text(
                  'Gagal memuat data profil.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        final userData = snapshot.data!;
        final String role =
            userData[DatabaseHelper.tableUsersColRole] ?? 'user';
        final String username =
            userData[DatabaseHelper.tableUsersColUsername] ?? 'Tamu';
        final String displayName =
            userData[DatabaseHelper.tableUsersColFullName] ?? username;
        final String? picturePath =
            userData[DatabaseHelper.tableUsersColPicturePath];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              SizedBox(height: 20),
              // Profile Picture with Shadow
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: kPrimaryColor.withOpacity(0.1),
                  backgroundImage:
                      (picturePath != null && picturePath.isNotEmpty)
                      ? (picturePath.startsWith('data:image')
                            ? MemoryImage(_base64ToImage(picturePath))
                            : NetworkImage(picturePath) as ImageProvider)
                      : null,
                  child: (picturePath == null || picturePath.isEmpty)
                      ? Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 48,
                            color: kPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              SizedBox(height: 20),
              // Name Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: kTextPrimaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: role == 'admin'
                              ? kSecondaryColor.withOpacity(0.2)
                              : kPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          role == 'admin' ? '👑 Admin' : '👤 User',
                          style: TextStyle(
                            color: role == 'admin'
                                ? kSecondaryColor
                                : kPrimaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              // Action Buttons
              _buildActionButton(
                context,
                icon: Icons.edit_rounded,
                label: 'Edit Profil',
                color: kPrimaryColor,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(),
                    ),
                  ).then((_) {
                    _loadUserData();
                  });
                },
              ),
              SizedBox(height: 12),
              _buildActionButton(
                context,
                icon: Icons.notifications_rounded,
                label: 'Tes Notifikasi',
                color: kSecondaryColor,
                onPressed: () {
                  NotificationService().showTestNotification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Notifikasi dikirim!'),
                      backgroundColor: kSuccessColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 12),
              _buildActionButton(
                context,
                icon: Icons.logout_rounded,
                label: 'Logout',
                color: kErrorColor,
                onPressed: () async {
                  await _authService.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
                  );
                },
              ),
              // Admin Section
              if (role == 'admin') ...[
                SizedBox(height: 30),
                Divider(),
                SizedBox(height: 20),
                Text(
                  '⚙️ Admin Controls',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kSecondaryColor,
                  ),
                ),
                SizedBox(height: 16),
                _buildActionButton(
                  context,
                  icon: _isSyncing ? Icons.sync_disabled : Icons.sync_rounded,
                  label: _isSyncing ? 'Sinkronisasi...' : 'Sync Data Game',
                  color: kSuccessColor,
                  onPressed: _isSyncing ? null : _syncData,
                ),
              ],
              SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 22),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
