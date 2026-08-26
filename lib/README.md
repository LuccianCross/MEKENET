# Scaffold Feature — Mekenet App Shell

## What I Built

The base app structure with 4 navigable screens (Home, Add, Debts, Settings), bottom navigation bar, and a mock repository for testing with fake transaction data.

## Folder Structure

```
lib/
├── main.dart                 → App entry point
├── models/
│   └── transaction.dart      → Data blueprint (id, amount, sender, type)
├── repositories/
│   ├── transaction_repository.dart   → Contract for data access
│   └── mock_transaction_repository.dart → Fake data for testing
├── screens/
│   ├── home_screen.dart      → Shows weekly income and transactions
│   ├── quick_add_screen.dart → Placeholder for adding transactions
│   ├── debts_screen.dart     → Shows who owes you money
│   └── settings_screen.dart  → Privacy and export options
└── widgets/
    └── bottom_nav_bar.dart   → Bottom navigation with 4 tabs
```

## How to Test

1. Run: `flutter run -d chrome`
2. Click through all 4 tabs:
   - **Home**: Shows income and transactions
   - **Add**: Shows "Coming Soon" placeholder
   - **Debts**: Shows debts list
   - **Settings**: Shows privacy options

## Known Issues

- Phone build has NDK issue (needs team help)
- Add screen is a placeholder
- Uses mock data (real SQLite coming soon)

## Next Steps

- Connect to real SQLite database
- Build the Add screen (manual entry)
- Add SMS parser integration