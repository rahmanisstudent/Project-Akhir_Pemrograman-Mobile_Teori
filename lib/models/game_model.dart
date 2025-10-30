class Game {
  final int id;
  final String name;
  final String store;
  final double price;
  final String currencyCode;
  final String? imageUrl;
  final int timeZoneOffset;

  Game({
    required this.id,
    required this.name,
    required this.store,
    required this.price,
    required this.currencyCode,
    this.imageUrl,
    required this.timeZoneOffset,
  });

  // Fungsi untuk mengubah Map (dari database) menjadi objek Game
  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'],
      name: map['name'],
      store: map['store'],
      price: map['price'],
      currencyCode: map['currency_code'],
      imageUrl: map['image_url'],
      timeZoneOffset: map['time_zone_offset'],
    );
  }
}
