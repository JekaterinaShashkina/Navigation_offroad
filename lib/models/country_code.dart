import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class CountryCode {
  final String name;
  final String iso2;
  final String dialCode;

  CountryCode({
    required this.name,
    required this.iso2,
    required this.dialCode,
  });

  factory CountryCode.fromMap(Map<String, dynamic> map) {
    return CountryCode(
      name: map['name'],
      iso2: map['iso2'],
      dialCode: map['dial_code'],
    );
  }
}

/// Конвертируем ISO2 в emoji-флаг (например EE → 🇪🇪)
String iso2ToFlag(String iso2) {
  final code = iso2.toUpperCase();
  return String.fromCharCodes(
    code.codeUnits.map((c) => 0x1F1E6 - 65 + c),
  );
}

/// Загружаем список кодов стран из assets/data/country_codes.json
Future<List<CountryCode>> loadCountryCodes() async {
  final raw = await rootBundle.loadString('assets/data/country_codes.json');
  final List data = json.decode(raw);
  return data.map((e) => CountryCode.fromMap(e)).toList();
}
