# Mekenet — Hold Your Money Together

A mobile app that turns a shop owner's mobile-money SMS into a daily money record — automatically.

---

## Team Members

| Name | CTC Number | Role |
|------|------------|------|
| Lewi Kibru (Lead) | CTC-6064-26 | Product, Design, Go-to-Market |
| Lombame Lemma | CTC-888-26 | Team Member |
| Helen Tesfaye | CTC-1586-26 | Team Member |
| Mekdes Tesfaye | CTC-1711-26 | Frontend Developer |

---

## Features

- [x] App scaffold with 4 screens (Home, Add, Debts, Settings)
- [x] Bottom navigation
- [x] Mock repository with fake transaction data
- [ ] SMS Parser (Core Engine Dev)
- [ ] SQLite Database (Storage/Sync Dev)
- [ ] Export Service (Backend Dev)

---

## How to Run

### Prerequisites
- Flutter 3.22.0 or higher
- Chrome (for web testing)

### Steps

1. Clone the repository:
   ```bash
   git clone <repo-url>
   cd MEKENET
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   # For Chrome (fastest)
   flutter run -d chrome
   
   # For Android phone
   flutter run
   ```

---

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

---

## How to Test

1. Run: `flutter run -d chrome`
2. Click through all 4 tabs:
   - **Home**: Shows income and transactions
   - **Add**: Shows "Coming Soon" placeholder
   - **Debts**: Shows debts list
   - **Settings**: Shows privacy options

---

## Known Issues

- Phone build has NDK issue (needs team help)
- Add screen is a placeholder
- Uses mock data (real SQLite coming soon)

---

## Next Steps

- Connect to real SQLite database
- Build the Add screen (manual entry)
- Add SMS parser integration