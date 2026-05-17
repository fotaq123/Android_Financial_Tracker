// lib/screens/statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

// ── Smart number formatter ────────────────────────────────────
String fmtCompact(double v) {
  final abs = v.abs();
  final sign = v < 0 ? '-' : '';
  if (abs >= 1e12) return '$sign${(abs / 1e12).toStringAsFixed(abs >= 10e12 ? 1 : 2)}T €';
  if (abs >= 1e9)  return '$sign${(abs / 1e9).toStringAsFixed(abs >= 10e9 ? 1 : 2)}B €';
  if (abs >= 1e6)  return '$sign${(abs / 1e6).toStringAsFixed(abs >= 10e6 ? 1 : 2)}M €';
  if (abs >= 1e3)  return '$sign${(abs / 1e3).toStringAsFixed(abs >= 10e3 ? 1 : 2)}K €';
  return NumberFormat.currency(locale: 'el_GR', symbol: '€').format(v);
}

enum _ViewMode { month, year }

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  _ViewMode _viewMode = _ViewMode.month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _prev() => setState(() {
        _selected = _viewMode == _ViewMode.month
            ? DateTime(_selected.year, _selected.month - 1)
            : DateTime(_selected.year - 1);
      });

  void _next() {
    final now = DateTime.now();
    final atLimit = _viewMode == _ViewMode.month
        ? (_selected.year == now.year && _selected.month == now.month)
        : _selected.year == now.year;
    if (!atLimit) {
      setState(() {
        _selected = _viewMode == _ViewMode.month
            ? DateTime(_selected.year, _selected.month + 1)
            : DateTime(_selected.year + 1);
      });
    }
  }

  bool get _canGoNext {
    final now = DateTime.now();
    return _viewMode == _ViewMode.month
        ? !(_selected.year == now.year && _selected.month == now.month)
        : _selected.year < now.year;
  }

  String get _periodLabel => _viewMode == _ViewMode.month
      ? DateFormat('MMMM yyyy', 'el_GR').format(_selected)
      : _selected.year.toString();

  List<Transaction> _filtered(List<Transaction> all) => all.where((t) {
        return _viewMode == _ViewMode.month
            ? t.date.year == _selected.year && t.date.month == _selected.month
            : t.date.year == _selected.year;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat.currency(locale: 'el_GR', symbol: '€');

    final catColors = {
      'Φαγητό': Colors.red.shade400,
      'Μεταφορά': Colors.blue.shade400,
      'Λογαριασμοί': Colors.amber.shade600,
      'Ψώνια': Colors.pink.shade400,
      'Υγεία': Colors.green.shade400,
      'Ψυχαγωγία': Colors.purple.shade400,
      'Μισθός': Colors.teal.shade400,
      'Άλλο': Colors.grey.shade400,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Στατιστικά'), centerTitle: false),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Transaction>('transactions').listenable(),
        builder: (context, Box<Transaction> box, _) {
          final allTxns = box.values.toList();
          final txns = _filtered(allTxns);

          final totalIn  = txns.where((t) => t.type == 'εσοδο').fold(0.0, (s, t) => s + t.amount);
          final totalOut = txns.where((t) => t.type == 'εξοδο').fold(0.0, (s, t) => s + t.amount);
          final net = totalIn - totalOut;

          // ── Bar chart data ──────────────────────────────────
          // Month mode: one group per month across all data (same as before)
          // Year mode: one group per month of the selected year
          final Map<String, Map<String, double>> monthly = {};
          final source = _viewMode == _ViewMode.month ? allTxns : txns;
          for (final t in source) {
            final key = _viewMode == _ViewMode.month
                ? DateFormat('yyyy-MM').format(t.date)
                : DateFormat('yyyy-MM').format(t.date);
            monthly.putIfAbsent(key, () => {'εσοδο': 0.0, 'εξοδο': 0.0});
            monthly[key]![t.type] = (monthly[key]![t.type] ?? 0) + t.amount;
          }

          List<String> mKeys;
          if (_viewMode == _ViewMode.year) {
            // Show all 12 months of selected year even if empty
            mKeys = List.generate(12, (i) =>
                '${_selected.year}-${(i + 1).toString().padLeft(2, '0')}');
            for (final k in mKeys) {
              monthly.putIfAbsent(k, () => {'εσοδο': 0.0, 'εξοδο': 0.0});
            }
          } else {
            mKeys = monthly.keys.toList()..sort();
          }

          // ── Category data ───────────────────────────────────
          final Map<String, double> catData = {};
          for (final t in txns.where((t) => t.type == 'εξοδο')) {
            catData[t.category] = (catData[t.category] ?? 0) + t.amount;
          }

          final mnLabels = ['Ιαν','Φεβ','Μαρ','Απρ','Μάι','Ιούν',
                            'Ιούλ','Αύγ','Σεπ','Οκτ','Νοε','Δεκ'];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // ── View toggle ─────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: cs.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  _ToggleBtn(label: 'Μήνας', active: _viewMode == _ViewMode.month,
                      onTap: () => setState(() {
                        _viewMode = _ViewMode.month;
                        _selected = DateTime(DateTime.now().year, DateTime.now().month);
                      })),
                  _ToggleBtn(label: 'Έτος', active: _viewMode == _ViewMode.year,
                      onTap: () => setState(() {
                        _viewMode = _ViewMode.year;
                        _selected = DateTime(DateTime.now().year);
                      })),
                ]),
              ),
              const SizedBox(height: 14),

              // ── Period navigator ────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(onPressed: _prev, icon: const Icon(Icons.chevron_left)),
                  Text(_periodLabel,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  IconButton(
                    onPressed: _canGoNext ? _next : null,
                    icon: Icon(Icons.chevron_right,
                        color: _canGoNext ? null : Colors.grey.shade400),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Summary cards ───────────────────────────────
              Row(children: [
                Expanded(child: _StatCard(label: 'Έσοδα',    value: fmtCompact(totalIn),  color: Colors.green.shade700)),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(label: 'Έξοδα',    value: fmtCompact(totalOut), color: Colors.red.shade600)),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(label: 'Ισοζύγιο', value: fmtCompact(net),
                    color: net >= 0 ? Colors.green.shade700 : Colors.red.shade600)),
              ]),
              const SizedBox(height: 20),

              // ── Bar chart ───────────────────────────────────
              Text(
                _viewMode == _ViewMode.month
                    ? 'Έσοδα vs Έξοδα ανά μήνα'
                    : 'Έσοδα vs Έξοδα ανά μήνα ${_selected.year}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (mKeys.isEmpty || mKeys.every((k) =>
                  (monthly[k]?['εσοδο'] ?? 0) == 0 &&
                  (monthly[k]?['εξοδο'] ?? 0) == 0))
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('Δεν υπάρχουν δεδομένα', style: TextStyle(color: Colors.grey)),
                ))
              else
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final idx = v.toInt();
                              if (idx < 0 || idx >= mKeys.length) return const SizedBox();
                              final parts = mKeys[idx].split('-');
                              final mn = mnLabels[int.parse(parts[1]) - 1];
                              // In month mode show year too if spans multiple years
                              final showYear = _viewMode == _ViewMode.month &&
                                  mKeys.length > 12 && parts[1] == '01';
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  showYear ? '${parts[0]}\n$mn' : mn,
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 54,
                            getTitlesWidget: (v, _) => Text(
                              fmtCompact(v),
                              style: const TextStyle(fontSize: 9, color: Colors.grey),
                            ),
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(mKeys.length, (i) {
                        final k = mKeys[i];
                        return BarChartGroupData(x: i, barRods: [
                          BarChartRodData(
                            toY: monthly[k]!['εσοδο']!,
                            color: Colors.green.shade400,
                            width: _viewMode == _ViewMode.year ? 8 : 10,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          BarChartRodData(
                            toY: monthly[k]!['εξοδο']!,
                            color: Colors.red.shade400,
                            width: _viewMode == _ViewMode.year ? 8 : 10,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ]);
                      }),
                    ),
                  ),
                ),

              // ── Legend ──────────────────────────────────────
              Row(children: [
                _LegendDot(color: Colors.green.shade400, label: 'Έσοδα'),
                const SizedBox(width: 16),
                _LegendDot(color: Colors.red.shade400, label: 'Έξοδα'),
              ]),
              const SizedBox(height: 20),

              // ── Pie chart ───────────────────────────────────
              const Text('Κατανομή εξόδων ανά κατηγορία',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (catData.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('Δεν υπάρχουν δεδομένα', style: TextStyle(color: Colors.grey)),
                ))
              else ...[
                SizedBox(
                  height: 240,
                  child: PieChart(
                    PieChartData(
                      sections: catData.entries.map((e) {
                        final pct = totalOut > 0 ? (e.value / totalOut * 100) : 0.0;
                        return PieChartSectionData(
                          value: e.value,
                          title: '${pct.toStringAsFixed(1)}%',
                          color: catColors[e.key] ?? Colors.grey,
                          radius: 80,
                          titleStyle: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                        );
                      }).toList(),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Category legend with amounts
                ...catData.entries.map((e) {
                  final pct = totalOut > 0 ? e.value / totalOut * 100 : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: catColors[e.key] ?? Colors.grey,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e.key,
                          style: const TextStyle(fontSize: 13))),
                      Text(fmtCompact(e.value),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 44,
                        child: Text('${pct.toStringAsFixed(1)}%',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ),
                    ]),
                  );
                }),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToggleBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(label, style: TextStyle(
              color: active ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.6),
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            )),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(value,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 12, height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ]);
  }
}