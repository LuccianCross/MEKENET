// This file creates the bottom navigation bar with 4 tabs
// It's like the menu at the bottom of the app

import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  // 'StatelessWidget' means this widget doesn't change state
  // (it just shows what it's told to show)
  
  // These are the properties this widget needs:
  final int currentIndex;        // Which tab is selected (0, 1, 2, or 3)
  final Function(int) onTap;    // What to do when a tab is tapped

  // Constructor - requires these values when creating this widget
  const BottomNavBar({
  super.key,
  required this.currentIndex,
  required this.onTap,
});

  @override
  Widget build(BuildContext context) {
    // This is what gets displayed on screen
    return BottomNavigationBar(
      currentIndex: currentIndex,     // Highlight the selected tab
      onTap: onTap,                   // Call this function when tapped
      type: BottomNavigationBarType.fixed, // Keep all tabs visible
      items: const [                  // The 4 tabs
        BottomNavigationBarItem(
          icon: Icon(Icons.home),     // Home icon
          label: 'Home',              // Label below icon
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle), // Add icon
          label: 'Add',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),   // People/debts icon
          label: 'Debts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings), // Settings icon
          label: 'Settings',
        ),
      ],
    );
  }
}