import 'package:finance_tracker/models/account.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import 'add_transaction_screen.dart';
import 'dart:io';

class TransactionDetailScreen extends StatelessWidget {
  final Transaction txn;
  const TransactionDetailScreen({super.key, required this.txn});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'el_GR', symbol: '€');
    final isIncome = txn.type == 'εσοδο';
    final Box<Account> accBox = Hive.box<Account>('accounts');  // ← explicit type
    String accName = 'Χωρίς λογαριασμό';
      if (txn.accountId != null) {
      final acc = accBox.values.where((a) => a.id == txn.accountId).firstOrNull;
      if (acc != null) accName = acc.name;
}

    final catIcons = {
      'Φαγητό': '🍽️', 'Μεταφορά': '🚌', 'Λογαριασμοί': '💡',
      'Ψώνια': '🛍️', 'Υγεία': '💊', 'Ψυχαγωγία': '🎬',
      'Μισθός': '💰', 'Άλλο': '📌',
    };

    void deleteTxn() {
      if (txn.accountId != null) {
        final acc = accBox.values.where((a) => a.id == txn.accountId).firstOrNull;
        if (acc != null) {
          acc.balance += isIncome ? -txn.amount : txn.amount;
          acc.save();
        }
      }
      txn.delete();
      Navigator.pop(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Λεπτομέρειες'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AddTransactionScreen(existing: txn))),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Διαγραφή κίνησης'),
                content: const Text('Είστε σίγουροι ότι θέλετε να διαγράψετε αυτή την κίνηση;'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ακύρωση')),
                  FilledButton(onPressed: () { Navigator.pop(context); deleteTxn(); }, child: const Text('Διαγραφή')),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
              child: Text(catIcons[txn.category] ?? '📌', style: const TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '${isIncome ? '+' : '-'}${fmt.format(txn.amount)}',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isIncome ? Colors.green.shade700 : Colors.red.shade600),
            ),
          ),
          Center(child: Text(txn.title, style: const TextStyle(fontSize: 18))),
          const SizedBox(height: 4),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(isIncome ? 'Έσοδο' : 'Έξοδο', style: TextStyle(color: isIncome ? Colors.green.shade800 : Colors.red.shade800, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            child: Column(
              children: [
                _DetailRow(label: 'Κατηγορία', value: txn.category),
                _DetailRow(label: 'Ημερομηνία', value: DateFormat('dd/MM/yyyy').format(txn.date)),
                _DetailRow(label: 'Λογαριασμός', value: accName),
              ],
            ),
          ),
          if (txn.photoPath != null) ...[
            const SizedBox(height: 16),
            const Text('Φωτογραφία', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(txn.photoPath!), fit: BoxFit.cover)),
          ] else ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 120,
                color: Colors.grey.shade100,
                child: Center(child: Text(catIcons[txn.category] ?? '📌', style: const TextStyle(fontSize: 56))),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }
}