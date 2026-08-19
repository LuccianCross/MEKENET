import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main_screen.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _pin = '';
  String _confirmPin = '';

  bool _isSettingPin = true;
  bool _isConfirming = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkExistingPin();
  }

  Future<void> _checkExistingPin() async {
    final prefs = await SharedPreferences.getInstance();

    final hasPin = prefs.getBool('has_pin') ?? false;

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
          child: CircularProgressIndicator(
            color: Color(0xFF0A8E48),
          ),
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
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              const Icon(
                Icons.lock_outline,
                size: 48,
                color: Color(0xFF0A8E48),
              ),

              const SizedBox(height: 12),

              Text(
                _isSettingPin
                    ? (_isConfirming
                        ? 'Confirm your PIN'
                        : 'Create your PIN')
                    : 'Enter your PIN',

                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                _isSettingPin
                    ? (_isConfirming
                        ? 'Enter your 4-digit PIN again'
                        : 'Set a 4-digit PIN to secure your data')
                    : 'Please enter your 4-digit PIN',

                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),

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

                  child: const Text(
                    'Clear and start over',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinDots() {
    int length;

    if (_isSettingPin) {
      length =
          _isConfirming ? _confirmPin.length : _pin.length;
    } else {
      length = _pin.length;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,

      children: List.generate(
        4,
        (index) {
          return Container(
            margin:
                const EdgeInsets.symmetric(horizontal: 10),

            width: 16,
            height: 16,

            decoration: BoxDecoration(
              shape: BoxShape.circle,

              color: length > index
                  ? const Color(0xFF0A8E48)
                  : Colors.grey[300],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNumberRow(List<String> numbers) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceEvenly,

      children: numbers.map((number) {
        return Expanded(
          child: GestureDetector(
            onTap: number.isEmpty
                ? null
                : () => _handleNumberTap(number),

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
                    ? const Icon(
                        Icons.backspace,
                        size: 24,
                      )
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
      // =========================
      // SETTING NEW PIN
      // =========================

      if (_isSettingPin) {
        // First PIN
        if (!_isConfirming) {
          if (_pin.length < 4) {
            _pin += number;
          }

          if (_pin.length == 4) {
            _isConfirming = true;
          }
        }

        // Confirm PIN
        else {
          if (_confirmPin.length < 4) {
            _confirmPin += number;
          }

          if (_confirmPin.length == 4) {
            if (_pin == _confirmPin) {
              shouldGoHome = true;
            } else {
              _pin = '';
              _confirmPin = '';
              _isConfirming = false;

              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text(
                    'PINs do not match. Try again.',
                  ),
                ),
              );
            }
          }
        }
      }

      // =========================
      // LOGIN
      // =========================

      else {
        if (_pin.length < 4) {
          _pin += number;
        }
      }
    });

    // First-time setup successful
    if (shouldGoHome) {
      _savePinAndGoHome();
      return;
    }

    // Existing user login
    if (!_isSettingPin && _pin.length == 4) {
      _checkLoginPin();
    }
  }

  void _handleBackspace() {
    setState(() {
      if (_isSettingPin) {
        if (_isConfirming) {
          if (_confirmPin.isNotEmpty) {
            _confirmPin = _confirmPin.substring(
              0,
              _confirmPin.length - 1,
            );
          }
        } else {
          if (_pin.isNotEmpty) {
            _pin = _pin.substring(
              0,
              _pin.length - 1,
            );
          }
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(
            0,
            _pin.length - 1,
          );
        }
      }
    });
  }

  Future<void> _savePinAndGoHome() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString('user_pin', _pin);
    await prefs.setBool('has_pin', true);
    await prefs.setBool(
      'has_completed_onboarding',
      true,
    );

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const MainScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> _checkLoginPin() async {
    final prefs =
        await SharedPreferences.getInstance();

    final savedPin =
        prefs.getString('user_pin');

    if (_pin == savedPin) {
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const MainScreen(),
        ),
        (route) => false,
      );
    } else {
      setState(() {
        _pin = '';
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect PIN'),
        ),
      );
    }
  }
}