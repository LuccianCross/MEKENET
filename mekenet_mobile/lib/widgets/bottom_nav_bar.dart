import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: L10n.instance.t('nav_home'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.add_circle),
          label: L10n.instance.t('nav_add'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.people),
          label: L10n.instance.t('nav_debts'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings),
          label: L10n.instance.t('nav_settings'),
        ),
      ],
    );
  }
}