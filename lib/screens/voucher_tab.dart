// Di file: lib/screens/voucher_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // <-- IMPORT BARU
import 'package:latlong2/latlong.dart'; // <-- IMPORT BARU
import 'package:geolocator/geolocator.dart'; // (Ini sudah ada)

class VoucherTab extends StatefulWidget {
  const VoucherTab({Key? key}) : super(key: key);

  @override
  _VoucherTabState createState() => _VoucherTabState();
}

class _VoucherTabState extends State<VoucherTab> {
  bool _isLoading = false;
  String? _errorMessage;

  // State baru untuk Peta
  LatLng _mapCenter = LatLng(-6.2088, 106.8456); // Default: Jakarta
  Position? _currentPosition;
  final MapController _mapController = MapController();

  // Ambil lokasi hardcode dari kodemu sebelumnya
  final List<Marker> _storeMarkers = [
    // Indomaret (Lokasi fiksi di Jakarta)
    Marker(
      width: 80.0,
      height: 80.0,
      point: LatLng(-6.2180, 106.8480),
      child: Column(
        children: [
          Icon(Icons.store, color: Colors.red, size: 30),
          Text('Indomaret', style: TextStyle(fontSize: 10, color: Colors.red)),
        ],
      ),
    ),
    // Alfamart (Lokasi fiksi di Bandung)
    Marker(
      width: 80.0,
      height: 80.0,
      point: LatLng(-6.9175, 107.6191),
      child: Column(
        children: [
          Icon(Icons.store, color: Colors.blue, size: 30),
          Text('Alfamart', style: TextStyle(fontSize: 10, color: Colors.blue)),
        ],
      ),
    ),
  ];

  // Fungsi LBS yang sudah ada
  Future<void> _getCurrentPosition() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Layanan lokasi di HP Anda mati.');
      }
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
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newCenter = LatLng(position.latitude, position.longitude);
      setState(() {
        _isLoading = false;
        _currentPosition = position;
        _mapCenter = newCenter;
      });
      _mapController.move(newCenter, 15.0);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // Fungsi untuk membuat Marker lokasimu
  Marker _buildUserMarker() {
    if (_currentPosition == null) {
      // Jika lokasi belum ada, kembalikan marker kosong
      return Marker(point: LatLng(0, 0), child: Container());
    }

    return Marker(
      width: 80.0,
      height: 80.0,
      point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      child: Column(
        children: [
          Icon(Icons.my_location, color: Colors.greenAccent, size: 30),
          Text(
            'Lokasi Anda',
            style: TextStyle(fontSize: 10, color: Colors.greenAccent),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gabungkan marker toko dan marker user
    List<Marker> allMarkers = List.from(_storeMarkers)..add(_buildUserMarker());

    return Scaffold(
      // Kita pakai Stack agar tombol bisa "mengambang" di atas peta
      body: Stack(
        children: [
          // --- WIDGET PETA OSM ---
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _mapCenter, initialZoom: 13.0),
            children: [
              // TileLayer adalah "gambar" petanya
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              // MarkerLayer untuk menampilkan semua pin
              MarkerLayer(markers: allMarkers),
            ],
          ),

          // --- TOMBOL UNTUK MENDAPATKAN LOKASI ---
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: ElevatedButton.icon(
              icon: Icon(Icons.my_location),
              label: Text('Dapatkan Lokasi Saya'),
              onPressed: _isLoading ? null : _getCurrentPosition,
              style: ElevatedButton.styleFrom(
                // Gunakan tema kita
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),

          // --- TAMPILKAN ERROR JIKA ADA ---
          if (_errorMessage != null)
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
