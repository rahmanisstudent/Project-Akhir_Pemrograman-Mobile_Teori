class Game {
  final String dealID;
  final String title;
  final String? storeID;
  final double salePrice;
  final double normalPrice;
  final String? thumb;

  Game({
    required this.dealID,
    required this.title,
    this.storeID,
    required this.salePrice,
    required this.normalPrice,
    this.thumb,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      dealID: json['dealID'] ?? 'N/A',
      title: json['title'] ?? 'Unknown Title',
      storeID: json['storeID'],
      salePrice: double.tryParse(json['salePrice'] ?? '0.0') ?? 0.0,
      normalPrice: double.tryParse(json['normalPrice'] ?? '0.0') ?? 0.0,
      thumb: json['thumb'],
    );
  }

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
