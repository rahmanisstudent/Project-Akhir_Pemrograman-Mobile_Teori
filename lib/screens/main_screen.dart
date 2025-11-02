import 'package:flutter/material.dart';
import 'package:pixelnomics_stable/screens/login_screen.dart'; // Sesuaikan nama proyek
import 'package:pixelnomics_stable/services/auth_service.dart'; // Sesuaikan nama proyek
import 'games_tab.dart';
import 'feedback_screen.dart';
import 'login_screen.dart';
import 'wishlist_screen.dart';
import 'voucher_tab.dart';

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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Tampilkan Username
          _buildUsername(),

          SizedBox(height: 30),

          ElevatedButton.icon(
            icon: Icon(Icons.favorite),
            label: Text('Lihat Wishlist Saya'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent, // Biar beda
            ),
            onPressed: () {
              // Pindah ke layar Wishlist
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WishlistScreen()),
              );
            },
          ),

          SizedBox(height: 10),
          // 2. Tombol Kirim Kesan & Pesan
          ElevatedButton(
            onPressed: () {
              // Pindah ke layar Feedback
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FeedbackScreen()),
              );
            },
            child: Text('Kirim Kesan & Pesan'),
          ),

          SizedBox(height: 10),

          // 3. Tombol Logout (masih sama)
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
        ],
      ),
    );
  }
}
