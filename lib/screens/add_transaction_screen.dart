import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import 'dart:io';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? existing;
  const AddTransactionScreen({super.key, this.existing});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _type = 'εξοδο';
  String _category = 'Φαγητό';
  DateTime _date = DateTime.now();
  String? _accountId;
  String? _photoPath;

  final _categories = ['Φαγητό', 'Μεταφορά', 'Λογαριασμοί', 'Ψώνια', 'Υγεία', 'Ψυχαγωγία', 'Μισθός', 'Άλλο'];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final t = widget.existing!;
      _titleCtrl.text = t.title;
      _amountCtrl.text = t.amount.toString();
      _type = t.type;
      _category = t.category;
      _date = t.date;
      _accountId = t.accountId;
      _photoPath = t.photoPath;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _photoPath = img.path);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final txBox = Hive.box<Transaction>('transactions');
    final accBox = Hive.box<Account>('accounts');
    final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));

    if (widget.existing != null) {
      // Revert old account balance
      final old = widget.existing!;
      if (old.accountId != null) {
        final acc = accBox.values.firstWhere((a) => a.id == old.accountId, orElse: () => Account(id: '', name: '', balance: 0));
        if (acc.id.isNotEmpty) {
          acc.balance += old.type == 'εσοδο' ? -old.amount : old.amount;
          acc.save();
        }
      }
      old.title = _titleCtrl.text.trim();
      old.amount = amount;
      old.type = _type;
      old.category = _category;
      old.date = _date;
      old.accountId = _accountId;
      old.photoPath = _photoPath;
      old.save();
    } else {
      final txn = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleCtrl.text.trim(),
        amount: amount,
        type: _type,
        category: _category,
        date: _date,
        accountId: _accountId,
        photoPath: _photoPath,
      );
      txBox.add(txn);
    }

    // Update account balance
    if (_accountId != null) {
      final acc = accBox.values.firstWhere((a) => a.id == _accountId, orElse: () => Account(id: '', name: '', balance: 0));
      if (acc.id.isNotEmpty) {
        acc.balance += _type == 'εσοδο' ? amount : -amount;
        acc.save();
      }
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final accBox = Hive.box<Account>('accounts');
    final accounts = accBox.values.toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Νέα κίνηση' : 'Επεξεργασία')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Τίτλος / Περιγραφή', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Υποχρεωτικό πεδίο' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(labelText: 'Ποσό (€)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Υποχρεωτικό πεδίο';
                final n = double.tryParse(v.replaceAll(',', '.'));
                if (n == null || n <= 0) return 'Μη έγκυρο ποσό';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Τύπος', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'εξοδο', child: Text('Έξοδο')),
                DropdownMenuItem(value: 'εσοδο', child: Text('Έσοδο')),
              ],
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Κατηγορία', border: OutlineInputBorder()),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Ημερομηνία', border: OutlineInputBorder()),
                child: Text(DateFormat('dd/MM/yyyy').format(_date)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _accountId,
              decoration: const InputDecoration(labelText: 'Λογαριασμός', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('-- Χωρίς λογαριασμό --')),
                ...accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))),
              ],
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo),
              label: Text(_photoPath != null ? 'Φωτογραφία επιλέχθηκε ✓' : 'Επιλογή φωτογραφίας (προαιρετικά)'),
            ),
            if (_photoPath != null) ...[
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_photoPath!), height: 160, fit: BoxFit.cover)),
            ],
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: const Text('Αποθήκευση')),
          ],
        ),
      ),
    );
  }
}