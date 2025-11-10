import 'package:intl/intl.dart';

class Currency {
  final String code;
  final String name;
  final String flag;
  final String symbol;
  final String locale;
  final int decimalDigits;

  Currency({
    required this.code,
    required this.name,
    required this.flag,
    required this.symbol,
    required this.locale,
    required this.decimalDigits,
  });

  // kurs yang bisa dipakai
  static final List<Currency> supported = [
    Currency(
      code: 'IDR',
      name: 'Indonesia',
      flag: '🇮🇩',
      symbol: 'Rp',
      locale: 'id_ID',
      decimalDigits: 0,
    ),
    Currency(
      code: 'USD',
      name: 'United States',
      flag: '🇺🇸',
      symbol: '\$',
      locale: 'en_US',
      decimalDigits: 2,
    ),
    Currency(
      code: 'EUR',
      name: 'Europe',
      flag: '🇪🇺',
      symbol: '€',
      locale: 'de_DE',
      decimalDigits: 2,
    ),
  ];

  // ambil kurs by code
  static Currency getByCode(String code) {
    return supported.firstWhere(
      (currency) => currency.code == code,
      orElse: () => supported[0],
    );
  }

  NumberFormat get formatter {
    return NumberFormat.currency(
      locale: locale,
      symbol: "$symbol ",
      decimalDigits: decimalDigits,
    );
  }

  String format(double amount) {
    return formatter.format(amount);
  }

  // usd ke kurs yang dipilih (dari cheapshark soalnya usd)
  double convertFromUSD(double usdPrice, Map<String, dynamic> rates) {
    if (!rates.containsKey(code)) return 0.0;
    double rate = rates[code].toDouble();
    return usdPrice * rate;
  }

  @override
  String toString() => '$flag $name ($code)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}
