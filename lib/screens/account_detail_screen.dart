import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/account.dart';
import '../models/transaction.dart';

class AccountDetailScreen extends StatelessWidget {
  final Account account;
  const AccountDetailScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final txBox = Hive.box<Transaction>('transactions');
    final fmt = NumberFormat.currency(locale: 'el_GR', symbol: '€');
    final accTxns = txBox.values.where((t) => t.accountId == account.id).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final now = DateTime.now();
    final twoMonthsAgo = DateTime(now.year, now.month - 2, now.day);
    final recentTxns = accTxns.where((t) => t.date.isAfter(twoMonthsAgo)).toList();

    // Build balance history
    double runBal = account.balance;
    for (final t in accTxns.reversed) {
      runBal += t.type == 'εσοδο' ? -t.amount : t.amount;
    }
    final spots = <FlSpot>[];
    double sim = runBal;
    for (int i = 0; i < recentTxns.length; i++) {
      sim += recentTxns[i].type == 'εσοδο' ? recentTxns[i].amount : -recentTxns[i].amount;
      spots.add(FlSpot(i.toDouble(), sim));
    }
    if (spots.isEmpty) spots.add(FlSpot(0, account.balance));

    void deleteAccount() {
      txBox.values.where((t) => t.accountId == account.id).forEach((t) {
        t.accountId = null;
        t.save();
      });
      account.delete();
      Navigator.pop(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Διαγραφή λογαριασμού'),
                content: const Text('Όλες οι κινήσεις θα αποσυνδεθούν. Συνέχεια;'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ακύρωση')),
                  FilledButton(onPressed: () { Navigator.pop(context); deleteAccount(); }, child: const Text('Διαγραφή')),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Διαθέσιμο υπόλοιπο', style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7), fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(fmt.format(account.balance), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                  Text('${accTxns.length} συνολικές κινήσεις', style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.6), fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Εξέλιξη υπολοίπου (τελευταίοι 2 μήνες)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 60, getTitlesWidget: (v, _) => Text(fmt.format(v), style: const TextStyle(fontSize: 10, color: Colors.grey)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}