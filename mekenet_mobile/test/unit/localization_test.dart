import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mekenet/l10n/app_localizations.dart';

void main() {
  group('AppLocalizations', () {
    test('returns English translations', () {
      final loc = AppLocalizations(const Locale('en'));
      expect(loc.t('appTitle'), 'Mekenet');
      expect(loc.t('home'), 'Home');
      expect(loc.t('income'), 'Income');
      expect(loc.t('expenses'), 'Expenses');
      expect(loc.t('debts'), 'Debts');
    });

    test('returns Amharic translations', () {
      final loc = AppLocalizations(const Locale('am'));
      expect(loc.t('appTitle'), 'መቀነት');
      expect(loc.t('home'), 'መነሻ');
      expect(loc.t('income'), 'ግቢ');
      expect(loc.t('expenses'), 'ወጪ');
      expect(loc.t('debts'), '뽐ዓን');
    });

    test('falls back to key for unknown locale', () {
      final loc = AppLocalizations(const Locale('fr'));
      expect(loc.t('appTitle'), 'appTitle');
    });

    test('falls back to key for missing translation', () {
      final loc = AppLocalizations(const Locale('en'));
      expect(loc.t('nonexistent_key'), 'nonexistent_key');
    });

    test('delegate supports en and am', () {
      const delegate = AppLocalizations.delegate;
      expect(delegate.isSupported(const Locale('en')), true);
      expect(delegate.isSupported(const Locale('am')), true);
      expect(delegate.isSupported(const Locale('fr')), false);
    });
  });
}
