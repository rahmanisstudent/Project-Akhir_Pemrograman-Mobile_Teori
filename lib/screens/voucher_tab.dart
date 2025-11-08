import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pixelnomics_stable/utils/app_theme.dart';

class VoucherTab extends StatefulWidget {
  const VoucherTab({Key? key}) : super(key: key);

  @override
  _VoucherTabState createState() => _VoucherTabState();
}

class _VoucherTabState extends State<VoucherTab> {
  bool _isLoading = false;
  String? _errorMessage;

  LatLng _mapCenter = LatLng(-6.2088, 106.8456);
  Position? _currentPosition;
  final MapController _mapController = MapController();

  final List<Map<String, dynamic>> _stores = [
    {
      'name': 'Indomaret Sudirman',
      'location': LatLng(-6.2180, 106.8480),
      'color': Colors.red,
      'icon': Icons.store,
    },
    {
      'name': 'Alfamart Gatsu',
      'location': LatLng(-6.9175, 107.6191),
      'color': Colors.blue,
      'icon': Icons.store,
    },
  ];

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 Lokasi ditemukan!'),
          backgroundColor: kSuccessColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    // Store markers
    for (var store in _stores) {
      markers.add(
        Marker(
          width: 120.0,
          height: 100.0,
          point: store['location'],
          child: GestureDetector(
            onTap: () {
              _showStoreInfo(store['name']);
            },
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: store['color'],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: store['color'].withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(store['icon'], color: Colors.white, size: 24),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: Text(
                    store['name'],
                    style: TextStyle(
                      fontSize: 10,
                      color: kTextPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // User location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          width: 100.0,
          height: 100.0,
          point: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryColor.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(Icons.my_location, color: Colors.white, size: 24),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Anda',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return markers;
  }

  void _showStoreInfo(String storeName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.store, color: kPrimaryColor),
            SizedBox(width: 8),
            Expanded(child: Text(storeName, style: TextStyle(fontSize: 18))),
          ],
        ),
        content: Text(
          'Toko ini menjual voucher game!\n\n'
          '💳 Tersedia: Steam, PSN, Xbox\n'
          '💰 Diskon hingga 20%',
          style: TextStyle(color: kTextSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _mapCenter, initialZoom: 13.0),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),

          // Header Card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: kPrimaryColor, size: 28),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cari Toko Voucher',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: kTextPrimaryColor,
                                ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Icon(Icons.my_location_rounded),
                        label: Text(
                          _isLoading ? 'Mencari...' : 'Dapatkan Lokasi Saya',
                        ),
                        onPressed: _isLoading ? null : _getCurrentPosition,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Store Legend
          Positioned(
            bottom: 80,
            left: 16,
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Legenda',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kTextPrimaryColor,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 8),
                    ..._stores.map(
                      (store) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: store['color'],
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              store['name'],
                              style: TextStyle(
                                fontSize: 11,
                                color: kTextSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Error Message
          if (_errorMessage != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                color: kErrorColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
