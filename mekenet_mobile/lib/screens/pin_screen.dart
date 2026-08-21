import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../main.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  static const _secureStorage = FlutterSecureStorage();
  static const _pinKey = 'mekenet_pin_hash';
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
              ? (_isConfirming ? 'Confirm PIN' : 'Set PIN')
              : 'Enter PIN',
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
                    ? (_isConfirming ? 'Confirm your PIN' : 'Create your PIN')
                    : 'Enter your PIN',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                _isSettingPin
                    ? (_isConfirming
                        ? 'Enter your 4-digit PIN again'
                        : 'Set a 4-digit PIN to secure your data')
                    : 'Please enter your 4-digit PIN',
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
                  child: const Text('Clear and start over'),
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
            color: length > index ? const Color(0xFF0A8E48) : Colors.grey[300],
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
            onTap: number.isEmpty ? null : () => _handleNumberTap(number),
            child: Container(
              height: 60,
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: number.isEmpty ? Colors.transparent : Colors.grey[100],
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
                const SnackBar(content: Text('PINs do not match. Try again.')),
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
            _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
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

  String _hashPin(String pin) {
    final bytes = utf8.encode('mekenet_salt_$pin');
    return sha256.convert(bytes).toString();
  }

  Future<void> _savePinAndGoHome() async {
    final hash = _hashPin(_pin);
    await _secureStorage.write(key: _pinKey, value: hash);
    await _secureStorage.write(key: _hasPinKey, value: 'true');

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (route) => false,
    );
  }

  Future<void> _checkLoginPin() async {
    final lockoutStr = await _secureStorage.read(key: _lockoutKey);
    if (lockoutStr != null) {
      final lockoutUntil = DateTime.parse(lockoutStr);
      if (DateTime.now().isBefore(lockoutUntil)) {
        final remaining = lockoutUntil.difference(DateTime.now()).inSeconds;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Too many attempts. Try again in $remaining seconds.')),
          );
          setState(() => _pin = '');
        }
        return;
      }
      await _secureStorage.delete(key: _lockoutKey);
      await _secureStorage.write(key: _failCountKey, value: '0');
    }

    final savedHash = await _secureStorage.read(key: _pinKey);
    final inputHash = _hashPin(_pin);

    if (inputHash == savedHash) {
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
        await _secureStorage.write(key: _lockoutKey, value: lockoutUntil.toIso8601String());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Too many attempts. Locked for 30 seconds.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Incorrect PIN. $_failCount/5 attempts.')),
          );
        }
      }

      setState(() => _pin = '');
    }
  }
}
