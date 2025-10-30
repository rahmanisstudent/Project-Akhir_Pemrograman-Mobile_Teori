import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // <-- 1. IMPORT PLUGIN LBS

class VoucherTab extends StatefulWidget {
  const VoucherTab({Key? key}) : super(key: key);

  @override
  _VoucherTabState createState() => _VoucherTabState();
}

class _VoucherTabState extends State<VoucherTab> {
  // Variabel untuk menyimpan status
  bool _isLoading = false;
  String? _currentLocation;
  String? _errorMessage;

  // --- FUNGSI UTAMA LBS ---
  // Fungsi ini akan meminta izin & mengambil lokasi
  Future<void> _getCurrentPosition() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Cek apakah layanan lokasi di HP aktif
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Layanan lokasi di HP Anda mati.');
      }

      // 2. Minta izin ke pengguna
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak permanen. Ubah di pengaturan HP.');
      }

      // 3. Jika izin diberikan, ambil lokasi
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Update UI dengan hasil
      setState(() {
        _isLoading = false;
        _currentLocation =
            'Lat: ${position.latitude}\nLong: ${position.longitude}';
      });
    } catch (e) {
      // Tangani semua error
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cari Toko Voucher Terdekat',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 20),

          // --- Tombol untuk memicu LBS ---
          ElevatedButton.icon(
            icon: Icon(Icons.my_location),
            label: Text('Dapatkan Lokasi Saya Saat Ini'),
            onPressed: _isLoading
                ? null
                : _getCurrentPosition, // Nonaktifkan saat loading
          ),
          SizedBox(height: 20),

          // --- Area untuk menampilkan HASIL LOKASI ---
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8.0),
            ),
            height: 100, // Beri tinggi tetap
            child: Center(
              child: _isLoading
                  ? CircularProgressIndicator() // Tampilkan loading
                  : _errorMessage != null
                  ? Text(
                      // Tampilkan error
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    )
                  : Text(
                      // Tampilkan hasil
                      _currentLocation ?? 'Tekan tombol di atas untuk mencari.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
            ),
          ),

          SizedBox(height: 30),
          Divider(),

          // --- Data Hardcode (Sesuai Syarat MVP) ---
          Text(
            'Rekomendasi Terdekat (Contoh):',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ListTile(
            leading: Icon(Icons.store),
            title: Text('Indomaret Gamer Point'),
            subtitle: Text('Jl. Merdeka No. 123, Jakarta'),
          ),
          ListTile(
            leading: Icon(Icons.store),
            title: Text('Alfamart Gaming Center'),
            subtitle: Text('Jl. Pahlawan No. 45, Bandung'),
          ),
        ],
      ),
    );
  }
}
