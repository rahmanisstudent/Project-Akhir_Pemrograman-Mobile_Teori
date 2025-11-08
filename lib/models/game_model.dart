class Game {
  // Kita akan gunakan dealID dari API sebagai ID unik
  final String dealID;
  final String title;
  final String? storeID; // ID toko (misal: "1" untuk Steam)
  final double salePrice; // Harga diskon (sudah dikonversi dari String)
  final double normalPrice; // Harga normal (sudah dikonversi dari String)
  final String? thumb; // URL gambar thumbnail

  Game({
    required this.dealID,
    required this.title,
    this.storeID,
    required this.salePrice,
    required this.normalPrice,
    this.thumb,
  });

  // Fungsi Factory untuk mengubah JSON (dari API) menjadi objek Game
  // Ini akan meng-handle konversi "29.99" (String) menjadi 29.99 (double)
  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      dealID: json['dealID'] ?? 'N/A',
      title: json['title'] ?? 'Unknown Title',
      storeID: json['storeID'],
      // API mengembalikan harga sebagai String, kita ubah jadi double
      salePrice: double.tryParse(json['salePrice'] ?? '0.0') ?? 0.0,
      normalPrice: double.tryParse(json['normalPrice'] ?? '0.0') ?? 0.0,
      thumb: json['thumb'],
    );
  }

  // Fungsi untuk mengubah Map (dari Database) menjadi objek Game
  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      dealID: map['dealID'],
      title: map['title'],
      storeID: map['storeID'],
      salePrice: map['salePrice'],
      normalPrice: map['normalPrice'],
      thumb: map['thumb'],
    );
  }

  // Fungsi untuk mengubah objek Game menjadi Map (untuk disimpan ke DB)
  Map<String, dynamic> toMap() {
    return {
      'dealID': dealID,
      'title': title,
      'storeID': storeID,
      'salePrice': salePrice,
      'normalPrice': normalPrice,
      'thumb': thumb,
    };
  }

  String get category {
    String lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('dlc') ||
        lowerTitle.contains('pass') ||
        lowerTitle.contains('expansion')) {
      return 'DLC / Expansion';
    }
    if (lowerTitle.contains('coins') ||
        lowerTitle.contains('crystals') ||
        lowerTitle.contains('pack') ||
        lowerTitle.contains('currency')) {
      return 'In-Game Currency';
    }
    return 'Full Game';
  }
}
