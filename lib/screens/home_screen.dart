// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../utils/rate_cache.dart';
import 'transaction_detail_screen.dart';
import 'add_transaction_screen.dart';
import 'currency_converter_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Αρχική'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.currency_exchange),
            tooltip: 'Μετατροπή νομίσματος',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CurrencyConverterScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen())),
        child: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Transaction>('transactions').listenable(),
        builder: (context, Box<Transaction> txBox, _) {
          return ValueListenableBuilder(
            valueListenable: Hive.box<Account>('accounts').listenable(),
            builder: (context, Box<Account> accBox, _) {
              final txns = txBox.values.toList();
              final totalIn = txns
                  .where((t) => t.type == 'εσοδο')
                  .fold(0.0, (s, t) => s + t.amount);
              final totalOut = txns
                  .where((t) => t.type == 'εξοδο')
                  .fold(0.0, (s, t) => s + t.amount);
              final balance = totalIn - totalOut;
              final recent = [...txns]
                ..sort((a, b) => b.date.compareTo(a.date));
              final recentFive = recent.take(5).toList();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SummaryCard(
                      totalIn: totalIn,
                      totalOut: totalOut,
                      balance: balance),
                  const SizedBox(height: 10),
                  _CurrencyStrip(eurAmount: balance),
                  const SizedBox(height: 16),
                  Text('Πρόσφατες κινήσεις',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (recentFive.isEmpty)
                    const Center(
                        child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('Δεν υπάρχουν κινήσεις')))
                  else
                    ...recentFive
                        .map((t) => _TxnTile(txn: t, accBox: accBox)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Currency strip
// ─────────────────────────────────────────────────────────────

class _CurrencyStrip extends StatefulWidget {
  final double eurAmount;
  const _CurrencyStrip({required this.eurAmount});

  @override
  State<_CurrencyStrip> createState() => _CurrencyStripState();
}

class _CurrencyStripState extends State<_CurrencyStrip> {
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (!RateCache.isValid) _fetchRates();
  }

  Future<void> _fetchRates() async {
    setState(() { _loading = true; _failed = false; });
    final err = await RateCache.fetch();
    if (mounted) setState(() { _loading = false; _failed = err != null; });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // ── Loading ──────────────────────────────────────────────
    if (_loading) {
      return Container(
        height: 42,
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Center(
          child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: cs.primary)),
        ),
      );
    }

    // ── Not loaded / failed ──────────────────────────────────
    if (!RateCache.isValid) {
      return GestureDetector(
        onTap: _fetchRates,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _failed
                ? cs.errorContainer.withOpacity(0.4)
                : cs.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _failed ? cs.error.withOpacity(0.3) : cs.outlineVariant),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(
              _failed ? Icons.wifi_off_rounded : Icons.currency_exchange,
              size: 15,
              color: _failed ? cs.error : cs.primary,
            ),
            const SizedBox(width: 8),
            Text(
              _failed
                  ? 'Αδυναμία φόρτωσης — πατήστε για επανάληψη'
                  : 'Εμφάνιση ισοτιμιών EUR / USD / GBP',
              style: TextStyle(
                  fontSize: 13,
                  color: _failed ? cs.error : cs.primary,
                  fontWeight: FontWeight.w500),
            ),
          ]),
        ),
      );
    }

    // ── Rates ready ──────────────────────────────────────────
    final usdVal = widget.eurAmount * RateCache.usd!;
    final gbpVal = widget.eurAmount * RateCache.gbp!;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                CurrencyConverterScreen(initialAmount: widget.eurAmount)),
      ),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(children: [
          Icon(Icons.currency_exchange, size: 15, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '🇺🇸 \$${usdVal.toStringAsFixed(2)}  ·  '
              '🇬🇧 £${gbpVal.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '1€ = \$${RateCache.usd!.toStringAsFixed(3)}',
            style: TextStyle(
                fontSize: 11, color: cs.onSurface.withOpacity(0.45)),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right,
              size: 16, color: cs.onSurface.withOpacity(0.35)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Existing widgets (unchanged)
// ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final double totalIn, totalOut, balance;
  const _SummaryCard(
      {required this.totalIn,
      required this.totalOut,
      required this.balance});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'el_GR', symbol: '€');
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Συνολικό υπόλοιπο',
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer
                        .withOpacity(0.7),
                    fontSize: 13)),
            const SizedBox(height: 4),
            Text(fmt.format(balance),
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: _MetricItem(
                      label: 'Έσοδα',
                      value: fmt.format(totalIn),
                      color: Colors.green.shade700)),
              Expanded(
                  child: _MetricItem(
                      label: 'Έξοδα',
                      value: fmt.format(totalOut),
                      color: Colors.red.shade600)),
            ]),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MetricItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(fontSize: 12, color: Colors.black54)),
      Text(value,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: color)),
    ]);
  }
}

class _TxnTile extends StatelessWidget {
  final Transaction txn;
  final Box<Account> accBox;
  const _TxnTile({required this.txn, required this.accBox});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'el_GR', symbol: '€');
    final isIncome = txn.type == 'εσοδο';
    final catIcons = {
      'Φαγητό': '🍽️',
      'Μεταφορά': '🚌',
      'Λογαριασμοί': '💡',
      'Ψώνια': '🛍️',
      'Υγεία': '💊',
      'Ψυχαγωγία': '🎬',
      'Μισθός': '💰',
      'Άλλο': '📌',
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => TransactionDetailScreen(txn: txn))),
        leading: CircleAvatar(
          backgroundColor:
              isIncome ? Colors.green.shade50 : Colors.red.shade50,
          child: Text(catIcons[txn.category] ?? '📌',
              style: const TextStyle(fontSize: 18)),
        ),
        title: Text(txn.title,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
            '${txn.category} · ${DateFormat('dd/MM/yyyy').format(txn.date)}',
            style: const TextStyle(fontSize: 12)),
        trailing: Text(
          '${isIncome ? '+' : '-'}${fmt.format(txn.amount)}',
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isIncome
                  ? Colors.green.shade700
                  : Colors.red.shade600),
        ),
      ),
    );
  }
}