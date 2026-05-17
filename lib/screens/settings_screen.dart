// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finance_tracker/theme_provider.dart';
import 'package:hive/hive.dart';
import 'pin_screen.dart';
import 'currency_converter_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final box = Hive.box('settings');
    final pinEnabled = box.get('pinEnabled', defaultValue: false) as bool;

    return Scaffold(
      appBar: AppBar(title: const Text('Ρυθμίσεις')),
      body: ListView(
        children: [

          // ── Εμφάνιση ─────────────────────────────────────────
          const _SectionHeader(title: 'Εμφάνιση'),
          SwitchListTile(
            title: const Text('Σκοτεινό θέμα'),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: themeProvider.isDark,
            onChanged: (_) => context.read<ThemeProvider>().toggle(),
          ),

          const Divider(height: 1),

          // ── Εργαλεία ─────────────────────────────────────────
          const _SectionHeader(title: 'Εργαλεία'),
          ListTile(
            leading: const Icon(Icons.currency_exchange_outlined),
            title: const Text('Μετατροπή νομίσματος'),
            subtitle: const Text('EUR → USD / GBP  ·  Δεδομένα ECB'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CurrencyConverterScreen()),
            ),
          ),

          const Divider(height: 1),

          // ── Ασφάλεια ─────────────────────────────────────────
          const _SectionHeader(title: 'Ασφάλεια'),
          SwitchListTile(
            title: const Text('Κλείδωμα με PIN'),
            secondary: const Icon(Icons.pin_outlined),
            value: pinEnabled,
            onChanged: (val) {
              if (val) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PinScreen(
                      isSetup: true,
                      onSuccess: () {
                        box.put('pinEnabled', true);
                        Navigator.pop(context);
                        setState(() {});
                      },
                    ),
                  ),
                );
              } else {
                box.put('pinEnabled', false);
                box.delete('pin');
                setState(() {});
              }
            },
          ),
          if (pinEnabled) ...[
            ListTile(
              leading: const Icon(Icons.lock_reset_outlined),
              title: const Text('Αλλαγή PIN'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PinScreen(
                    isSetup: true,
                    onSuccess: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ],

        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}