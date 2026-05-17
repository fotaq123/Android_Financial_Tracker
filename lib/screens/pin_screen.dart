import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class PinScreen extends StatefulWidget {
  final bool isSetup;        // true = setting a new PIN, false = verifying
  final VoidCallback? onSuccess;

  const PinScreen({super.key, this.isSetup = false, this.onSuccess});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _confirming = false;
  String _error = '';

  String _hash(String pin) =>
      sha256.convert(utf8.encode(pin)).toString();

  void _onKey(String digit) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += digit;
      _error = '';
    });
    if (_pin.length == 4) _submit();
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _submit() async {
    final box = Hive.box('settings');

    if (widget.isSetup) {
      if (!_confirming) {
        setState(() {
          _confirmPin = _pin;
          _pin = '';
          _confirming = true;
        });
      } else {
        if (_pin == _confirmPin) {
          box.put('pinHash', _hash(_pin));
          box.put('pinEnabled', true);
          widget.onSuccess?.call();
        } else {
          setState(() {
            _pin = '';
            _confirmPin = '';
            _confirming = false;
            _error = 'Τα PIN δεν ταιριάζουν. Δοκιμάστε ξανά.';
          });
        }
      }
    } else {
      final stored = box.get('pinHash');
      if (_hash(_pin) == stored) {
        widget.onSuccess?.call();
      } else {
        setState(() {
          _pin = '';
          _error = 'Λάθος PIN';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String title = widget.isSetup
        ? (_confirming ? 'Επιβεβαίωση PIN' : 'Ορίστε PIN')
        : 'Εισάγετε PIN';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (_error.isNotEmpty)
                Text(_error, style: TextStyle(color: Colors.red.shade400, fontSize: 13)),
              const SizedBox(height: 32),

              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pin.length
                        ? Theme.of(context).colorScheme.primary
                        : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  ),
                )),
              ),
              const SizedBox(height: 40),

              // Keypad
              SizedBox(
                width: 280,
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    ...['1','2','3','4','5','6','7','8','9'].map((d) => _KeyButton(
                      label: d, onTap: () => _onKey(d),
                    )),
                    const SizedBox.shrink(),
                    _KeyButton(label: '0', onTap: () => _onKey('0')),
                    _KeyButton(
                      icon: Icons.backspace_outlined,
                      onTap: _onDelete,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  const _KeyButton({this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceVariant,
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: onTap,
        child: Center(
          child: label != null
              ? Text(label!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500))
              : Icon(icon, size: 22),
        ),
      ),
    );
  }
}