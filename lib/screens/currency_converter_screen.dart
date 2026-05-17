// lib/screens/currency_converter_screen.dart
//
// Rates from Frankfurter (frankfurter.app / frankfurter.dev)
// Free · No API key · No rate limits · Backed by ECB

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/rate_cache.dart';

class CurrencyConverterScreen extends StatefulWidget {
  /// Pre-fills the EUR amount field (e.g. from the home balance).
  final double? initialAmount;
  const CurrencyConverterScreen({super.key, this.initialAmount});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null) {
      _ctrl.text =
          widget.initialAmount!.toStringAsFixed(2).replaceAll('.', ',');
    }
    if (!RateCache.isValid) _fetchRates();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _fetchRates() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await RateCache.fetch();
    if (mounted) setState(() { _loading = false; _error = err; });
  }

  double get _eur =>
      double.tryParse(_ctrl.text.trim().replaceAll(',', '.')) ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fmtUsd = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    final fmtGbp = NumberFormat.currency(locale: 'en_GB', symbol: '£');

    final hasRates = RateCache.isValid;
    final usdVal = hasRates ? _eur * RateCache.usd! : null;
    final gbpVal = hasRates ? _eur * RateCache.gbp! : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Μετατροπή νομίσματος'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Ανανέωση ισοτιμιών',
            onPressed: _loading ? null : () { RateCache.clear(); _fetchRates(); },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [

          // ── EUR input ─────────────────────────────────────────
          Text(
            'ΠΟΣΟ ΣΕ ΕΥΡΩ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: cs.onSurface.withOpacity(0.45),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '0,00',
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  '€',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ),
              suffixIcon: _ctrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _ctrl.clear()),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 28),

          // ── Loading ───────────────────────────────────────────
          if (_loading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(children: [
                  CircularProgressIndicator(color: cs.primary),
                  const SizedBox(height: 14),
                  Text(
                    'Ανάκτηση ισοτιμιών από ECB…',
                    style: TextStyle(
                        color: cs.onSurface.withOpacity(0.5), fontSize: 13),
                  ),
                ]),
              ),
            ),

          // ── Error ─────────────────────────────────────────────
          if (_error != null && !_loading) ...[
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(Icons.wifi_off_rounded, color: cs.error, size: 20),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                  _error!,
                  style:
                      TextStyle(color: cs.onErrorContainer, fontSize: 13),
                )),
                TextButton(
                    onPressed: _fetchRates, child: const Text('Retry')),
              ]),
            ),
            // Tip about Android permissions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline,
                    size: 16, color: cs.onSurface.withOpacity(0.5)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Αν η εφαρμογή τρέχει σε Android, βεβαιωθείτε ότι το '
                    'AndroidManifest.xml περιέχει:\n'
                    '<uses-permission android:name="android.permission.INTERNET"/>',
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withOpacity(0.55),
                        fontFamily: 'monospace'),
                  ),
                ),
              ]),
            ),
          ],

          // ── Results ───────────────────────────────────────────
          if (hasRates && !_loading) ...[
            _ConversionCard(
              flag: '🇺🇸',
              currencyName: 'Αμερικανικό Δολάριο',
              code: 'USD',
              result: usdVal != null ? fmtUsd.format(usdVal) : '—',
              rateLabel: '1 € = ${RateCache.usd!.toStringAsFixed(4)} \$',
              accentColor: const Color(0xFF1565C0),
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _ConversionCard(
              flag: '🇬🇧',
              currencyName: 'Βρετανική Λίρα Στερλίνα',
              code: 'GBP',
              result: gbpVal != null ? fmtGbp.format(gbpVal) : '—',
              rateLabel: '1 € = ${RateCache.gbp!.toStringAsFixed(4)} £',
              accentColor: const Color(0xFFB71C1C),
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // ── Reference table ───────────────────────────────
            _RatesTable(
                usd: RateCache.usd!,
                gbp: RateCache.gbp!,
                isDark: isDark,
                cs: cs),
            const SizedBox(height: 16),

            // ── Source + timestamp ────────────────────────────
            Center(
              child: Column(children: [
                Text(
                  'Πηγή: European Central Bank  ·  frankfurter.app',
                  style: TextStyle(
                      fontSize: 11, color: cs.onSurface.withOpacity(0.38)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ενημέρωση: ${DateFormat('dd/MM/yyyy HH:mm').format(RateCache.fetchedAt!)}',
                  style: TextStyle(
                      fontSize: 11, color: cs.onSurface.withOpacity(0.38)),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────

class _ConversionCard extends StatelessWidget {
  final String flag, currencyName, code, result, rateLabel;
  final Color accentColor;
  final bool isDark;

  const _ConversionCard({
    required this.flag,
    required this.currencyName,
    required this.code,
    required this.result,
    required this.rateLabel,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceVariant.withOpacity(0.35) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? cs.outlineVariant : Colors.grey.shade200),
      ),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child:
              Center(child: Text(flag, style: const TextStyle(fontSize: 26))),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(code,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: cs.onSurface.withOpacity(0.5))),
                const SizedBox(height: 2),
                Text(currencyName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(rateLabel,
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurface.withOpacity(0.45))),
              ]),
        ),
        Text(
          result,
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: accentColor),
        ),
      ]),
    );
  }
}

class _RatesTable extends StatelessWidget {
  final double usd, gbp;
  final bool isDark;
  final ColorScheme cs;

  const _RatesTable({
    required this.usd,
    required this.gbp,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, String)>[
      ('1 EUR', '\$${usd.toStringAsFixed(4)}', '£${gbp.toStringAsFixed(4)}'),
      ('10 EUR', '\$${(usd * 10).toStringAsFixed(2)}',
          '£${(gbp * 10).toStringAsFixed(2)}'),
      ('100 EUR', '\$${(usd * 100).toStringAsFixed(2)}',
          '£${(gbp * 100).toStringAsFixed(2)}'),
      ('1 USD', '€${(1 / usd).toStringAsFixed(4)}',
          '£${(gbp / usd).toStringAsFixed(4)}'),
      ('1 GBP', '€${(1 / gbp).toStringAsFixed(4)}',
          '\$${(usd / gbp).toStringAsFixed(4)}'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceVariant.withOpacity(0.3)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? cs.outlineVariant : Colors.grey.shade200),
      ),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Text(
            'ΠΙΝΑΚΑΣ ΙΣΟΤΙΜΙΩΝ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: cs.onSurface.withOpacity(0.45),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(children: [
            Expanded(
                child: Text('Ποσό',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withOpacity(0.45)))),
            SizedBox(
                width: 100,
                child: Text('USD',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1565C0)))),
            SizedBox(
                width: 100,
                child: Text('GBP',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB71C1C)))),
          ]),
        ),
        const Divider(height: 1),
        ...rows.asMap().entries.map((e) {
          final i = e.key;
          final r = e.value;
          final isLast = i == rows.length - 1;
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: i.isEven
                  ? (isDark
                      ? Colors.white.withOpacity(0.03)
                      : Colors.white)
                  : Colors.transparent,
              borderRadius: isLast
                  ? const BorderRadius.only(
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14))
                  : null,
            ),
            child: Row(children: [
              Expanded(
                  child: Text(r.$1,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500))),
              SizedBox(
                  width: 100,
                  child: Text(r.$2,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1565C0)))),
              SizedBox(
                  width: 100,
                  child: Text(r.$3,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFB71C1C)))),
            ]),
          );
        }),
      ]),
    );
  }
}