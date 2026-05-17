import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import 'account_detail_screen.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Λογαριασμοί'), centerTitle: false),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAccountDialog(context),
        child: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Account>('accounts').listenable(),
        builder: (context, Box<Account> box, _) {
          final accounts = box.values.toList();
          if (accounts.isEmpty) return const Center(child: Text('Δεν υπάρχουν λογαριασμοί'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length,
            itemBuilder: (ctx, i) {
              final a = accounts[i];
              final txBox = Hive.box<Transaction>('transactions');
              final cnt = txBox.values.where((t) => t.accountId == a.id).length;
              final fmt = NumberFormat.currency(locale: 'el_GR', symbol: '€');
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AccountDetailScreen(account: a))),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const CircleAvatar(radius: 24, child: Icon(Icons.account_balance_wallet)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                              Text('$cnt κινήσεις', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        ),
                        Text(fmt.format(a.balance), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: a.balance >= 0 ? Colors.green.shade700 : Colors.red.shade600)),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final balCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Νέος λογαριασμός'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Όνομα λογαριασμού', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: balCtrl, decoration: const InputDecoration(labelText: 'Αρχικό υπόλοιπο (€)', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ακύρωση')),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final balance = double.tryParse(balCtrl.text.replaceAll(',', '.')) ?? 0.0;
              final box = Hive.box<Account>('accounts');
              box.add(Account(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, balance: balance));
              Navigator.pop(context);
            },
            child: const Text('Αποθήκευση'),
          ),
        ],
      ),
    );
  }
}