// lib/utils/rate_cache.dart
//
// In-memory cache for EUR → USD / GBP rates.
// Rates expire after 60 minutes.
//
// Uses frankfurter.app (primary) → frankfurter.dev/v1 (fallback).
// Both are free, no API key, no rate limits, ECB-backed data.

import 'dart:convert';
import 'package:http/http.dart' as http;

class RateCache {
  RateCache._();

  static double? usd;
  static double? gbp;
  static DateTime? fetchedAt;

  static bool get isValid =>
      usd != null &&
      gbp != null &&
      fetchedAt != null &&
      DateTime.now().difference(fetchedAt!).inMinutes < 60;

  static void set(double newUsd, double newGbp) {
    usd = newUsd;
    gbp = newGbp;
    fetchedAt = DateTime.now();
  }

  static void clear() {
    usd = null;
    gbp = null;
    fetchedAt = null;
  }

  /// Fetches fresh rates. Returns null on success, or an error string.
  static Future<String?> fetch() async {
    final urls = [
      // Primary — the original, most widely reachable endpoint
      'https://api.frankfurter.app/latest?base=EUR&symbols=USD,GBP',
      // Fallback — newer domain
      'https://api.frankfurter.dev/v1/latest?base=EUR&symbols=USD,GBP',
    ];

    for (final url in urls) {
      try {
        final res = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 10));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final rates = data['rates'] as Map<String, dynamic>?;
          final newUsd = (rates?['USD'] as num?)?.toDouble();
          final newGbp = (rates?['GBP'] as num?)?.toDouble();

          if (newUsd != null && newGbp != null) {
            RateCache.set(newUsd, newGbp);
            return null; // ✓ success
          }
        }
      } catch (_) {
        continue; // try next URL
      }
    }

    return 'Αδυναμία σύνδεσης. Ελέγξτε το internet και δοκιμάστε ξανά.';
  }
}