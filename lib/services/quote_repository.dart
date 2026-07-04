import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/vachanamrut_quote.dart';

class QuoteRepository {
  const QuoteRepository._();

  static Future<List<VachanamrutQuote>> load() async {
    final jsonText = await rootBundle.loadString(
      'assets/vachanamrut_quotes.json',
    );
    final decoded = jsonDecode(jsonText) as List<Object?>;
    return decoded
        .cast<Map<String, Object?>>()
        .map(VachanamrutQuote.fromJson)
        .toList(growable: false);
  }
}
