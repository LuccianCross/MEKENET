import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  static const _secureStorage = FlutterSecureStorage();
  static const _pinHashKey = 'mekenet_pin_hash';
  static const _pinSaltKey = 'mekenet_pin_salt';
  static const _hasPinKey = 'mekenet_has_pin';
  static const _failCountKey = 'mekenet_pin_fails';
  static const _lockoutKey = 'mekenet_pin_lockout';

  String _pin = '';
  String _confirmPin = '';
  bool _isSettingPin = true;
  bool _isConfirming = false;
  bool _loading = true;
  int _failCount = 0;

  @override
  void initState() {
    super.initState();
    _checkExistingPin();
  }

  Future<void> _checkExistingPin() async {
    final hasPin = await _secureStorage.read(key: _hasPinKey) == 'true';
    final savedFails = await _secureStorage.read(key: _failCountKey);
    _failCount = int.tryParse(savedFails ?? '0') ?? 0;

    if (!mounted) return;

    setState(() {
      _isSettingPin = !hasPin;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0A8E48)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _isSettingPin
              ? (_isConfirming
                  ? AppLocalizations.of(context).t('confirmPIN')
                  : AppLocalizations.of(context).t('setPIN'))
              : AppLocalizations.of(context).t('enterPIN'),
        ),
        backgroundColor: const Color(0xFF0A8E48),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.jpg',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              Text(
                _isSettingPin
                    ? (_isConfirming
                        ? AppLocalizations.of(context).t('confirmYourPIN')
                        : AppLocalizations.of(context).t('createYourPIN'))
                    : AppLocalizations.of(context).t('enterPIN'),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                _isSettingPin
                    ? (_isConfirming
                        ? AppLocalizations.of(context).t('confirmYourPIN')
                        : AppLocalizations.of(context).t('createYourPIN'))
                    : AppLocalizations.of(context).t('enterPIN'),
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildPinDots(),
              const SizedBox(height: 24),
              Column(
                children: [
                  _buildNumberRow(['1', '2', '3']),
                  _buildNumberRow(['4', '5', '6']),
                  _buildNumberRow(['7', '8', '9']),
                  _buildNumberRow(['', '0', '⌫']),
                ],
              ),
              const SizedBox(height: 16),
              if (_isSettingPin)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _pin = '';
                      _confirmPin = '';
                      _isConfirming = false;
                    });
                  },
                  child:
                      Text(AppLocalizations.of(context).t('clearAndStartOver')),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinDots() {
    int length = _isSettingPin
        ? (_isConfirming ? _confirmPin.length : _pin.length)
        : _pin.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                length > index ? const Color(0xFF0A8E48) : Colors.grey[300],
          ),
        );
      }),
    );
  }

  Widget _buildNumberRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) {
        return Expanded(
          child: GestureDetector(
            onTap:
                number.isEmpty ? null : () => _handleNumberTap(number),
            child: Container(
              height: 60,
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: number.isEmpty
                    ? Colors.transparent
                    : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: number == '⌫'
                    ? const Icon(Icons.backspace, size: 24)
                    : Text(
                        number,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _handleNumberTap(String number) {
    if (number == '⌫') {
      _handleBackspace();
      return;
    }

    bool shouldGoHome = false;

    setState(() {
      if (_isSettingPin) {
        if (!_isConfirming) {
          if (_pin.length < 4) _pin += number;
          if (_pin.length == 4) _isConfirming = true;
        } else {
          if (_confirmPin.length < 4) _confirmPin += number;
          if (_confirmPin.length == 4) {
            if (_pin == _confirmPin) {
              shouldGoHome = true;
            } else {
              _pin = '';
              _confirmPin = '';
              _isConfirming = false;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text(AppLocalizations.of(context).t('pinMismatch'))),
              );
            }
          }
        }
      } else {
        if (_pin.length < 4) _pin += number;
      }
    });

    if (shouldGoHome) {
      _savePinAndGoHome();
      return;
    }

    if (!_isSettingPin && _pin.length == 4) {
      _checkLoginPin();
    }
  }

  void _handleBackspace() {
    setState(() {
      if (_isSettingPin) {
        if (_isConfirming) {
          if (_confirmPin.isNotEmpty) {
            _confirmPin =
                _confirmPin.substring(0, _confirmPin.length - 1);
          }
        } else {
          if (_pin.isNotEmpty) {
            _pin = _pin.substring(0, _pin.length - 1);
          }
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  /// Generate a random 16-char hex salt.
  String _generateSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Hash PIN with per-user salt: SHA-256(salt + pin).
  String _hashPinWithSalt(String pin, String salt) {
    final bytes = utf8.encode('$salt$pin');
    return sha256.convert(bytes).toString();
  }

  Future<void> _savePinAndGoHome() async {
    final salt = _generateSalt();
    final hash = _hashPinWithSalt(_pin, salt);

    await _secureStorage.write(key: _pinSaltKey, value: salt);
    await _secureStorage.write(key: _pinHashKey, value: hash);
    await _secureStorage.write(key: _hasPinKey, value: 'true');
    await _secureStorage.write(key: _failCountKey, value: '0');

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (route) => false,
    );
  }

  Future<void> _checkLoginPin() async {
    // --- Check lockout (persisted in secure storage) ---
    final lockoutStr = await _secureStorage.read(key: _lockoutKey);
    if (lockoutStr != null) {
      final lockoutUntil = DateTime.tryParse(lockoutStr);
      if (lockoutUntil != null && DateTime.now().isBefore(lockoutUntil)) {
        final remaining = lockoutUntil.difference(DateTime.now()).inSeconds;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context).t('tryAgainIn')} $remaining '
                '${AppLocalizations.of(context).t('seconds')}.',
              ),
            ),
          );
          setState(() => _pin = '');
        }
        return;
      }
      await _secureStorage.delete(key: _lockoutKey);
      _failCount = 0;
      await _secureStorage.write(key: _failCountKey, value: '0');
    }

    // --- Verify PIN ---
    final savedSalt = await _secureStorage.read(key: _pinSaltKey) ?? '';
    final savedHash = await _secureStorage.read(key: _pinHashKey);
    final inputHash = _hashPinWithSalt(_pin, savedSalt);

    if (inputHash == savedHash) {
      _failCount = 0;
      await _secureStorage.write(key: _failCountKey, value: '0');
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );
    } else {
      _failCount++;
      await _secureStorage.write(key: _failCountKey, value: '$_failCount');

      if (_failCount >= 5) {
        final lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
        await _secureStorage.write(
          key: _lockoutKey,
          value: lockoutUntil.toIso8601String(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context).t('lockedFor')} 30 '
                '${AppLocalizations.of(context).t('lockoutSeconds')}',
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context).t('incorrectPIN')}. '
                '$_failCount/5 ${AppLocalizations.of(context).t('attempts')}.',
              ),
            ),
          );
        }
      }

      setState(() => _pin = '');
    }
  }
}
