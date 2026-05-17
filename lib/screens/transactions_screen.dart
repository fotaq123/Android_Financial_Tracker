import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import 'add_transaction_screen.dart';
import 'transaction_detail_screen.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filter = 'ολες';
  String _sort = 'desc';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Κινήσεις'), centerTitle: false),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen())),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _FilterChip(label: 'Όλες', value: 'ολες', current: _filter, onTap: (v) => setState(() => _filter = v)),
                const SizedBox(width: 8),
                _FilterChip(label: 'Έσοδα', value: 'εσοδο', current: _filter, onTap: (v) => setState(() => _filter = v)),
                const SizedBox(width: 8),
                _FilterChip(label: 'Έξοδα', value: 'εξοδο', current: _filter, onTap: (v) => setState(() => _filter = v)),
                const Spacer(),
                DropdownButton<String>(
                  value: _sort,
                  underline: const SizedBox(),
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                  items: const [
                    DropdownMenuItem(value: 'desc', child: Text('Νεότερες')),
                    DropdownMenuItem(value: 'asc', child: Text('Παλαιότερες')),
                  ],
                  onChanged: (v) => setState(() => _sort = v!),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<Transaction>('transactions').listenable(),
              builder: (context, Box<Transaction> box, _) {
                final accBox = Hive.box<Account>('accounts');
                var list = box.values.toList();
                if (_filter != 'ολες') list = list.where((t) => t.type == _filter).toList();
                list.sort((a, b) => _sort == 'desc' ? b.date.compareTo(a.date) : a.date.compareTo(b.date));
                if (list.isEmpty) return const Center(child: Text('Δεν υπάρχουν κινήσεις'));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final t = list[i];
                    final fmt = NumberFormat.currency(locale: 'el_GR', symbol: '€');
                    final isIncome = t.type == 'εσοδο';
                    final catIcons = {
                      'Φαγητό': '🍽️', 'Μεταφορά': '🚌', 'Λογαριασμοί': '💡',
                      'Ψώνια': '🛍️', 'Υγεία': '💊', 'Ψυχαγωγία': '🎬',
                      'Μισθός': '💰', 'Άλλο': '📌',
                    };
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: ListTile(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionDetailScreen(txn: t))),
                        leading: CircleAvatar(
                          backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                          child: Text(catIcons[t.category] ?? '📌', style: const TextStyle(fontSize: 18)),
                        ),
                        title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text('${t.category} · ${DateFormat('dd/MM/yyyy').format(t.date)}', style: const TextStyle(fontSize: 12)),
                        trailing: Text(
                          '${isIncome ? '+' : '-'}${fmt.format(t.amount)}',
                          style: TextStyle(fontWeight: FontWeight.w600, color: isIncome ? Colors.green.shade700 : Colors.red.shade600),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label, value, current;
  final void Function(String) onTap;
  const _FilterChip({required this.label, required this.value, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, color: selected ? Colors.white : Colors.grey.shade700, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}