# Mekenet — Technical Architecture Document

> **Purpose:** This document explains every technical decision in the Mekenet project — why things are built the way they are, how files connect, where data flows, and what's done vs. what's left. Written so someone with minimal tech background can read it and deeply understand the system.

---

## Table of Contents

1. [What Mekenet Is](#1-what-mekenet-is)
2. [Project Structure — Every File Explained](#2-project-structure--every-file-explained)
3. [System Architecture — The Big Picture](#3-system-architecture--the-big-picture)
4. [Database Design — Visual Schema](#4-database-design--visual-schema)
5. [API Endpoints — Visual Reference](#5-api-endpoints--visual-reference)
6. [User Flow — What the User Experiences](#6-user-flow--what-the-user-experiences)
7. [App Flow — What Happens Inside the Code](#7-app-flow--what-happens-inside-the-code)
8. [SMS Pipeline — Step by Step](#8-sms-pipeline--step-by-step)
9. [Sync Pipeline — Phone to Server](#9-sync-pipeline--phone-to-server)
10. [Export Pipeline — Server to Loan Officer](#10-export-pipeline--server-to-loan-officer)
11. [Security & Privacy Design](#11-security--privacy-design)
12. [Testing Strategy](#12-testing-strategy)
13. [What's Done vs. What's Left](#13-whats-done-vs-whats-left)
14. [Key Decisions & Why](#14-key-decisions--why)

---

## 1. What Mekenet Is

**Problem:** Small shop owners in Addis Ababa receive money through mobile payments (Telebirr, CBE Birr, Awash Bank). When they get an SMS saying "You received ETB 5,000 from X", they screenshot it or ignore it. At the end of the month, they don't know their actual profit. They can't show a bank a clean financial record to get a loan.

**Solution:** Mekenet is a mobile app that automatically reads bank SMS, extracts the amount/date/direction, stores it locally (encrypted), and can optionally sync to a cloud server so the user can export a professional financial report for loan officers.

**Core promise:** Your data stays on your phone. You control when (or if) it leaves.

---

## 2. Project Structure — Every File Explained

```
INSA_final_project/
├── mekenet_mobile/          # Flutter mobile app (Android)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── database/
│   │   │   └── database_helper.dart
│   │   ├── models/
│   │   │   ├── transaction.dart
│   │   │   ├── debt.dart
│   │   │   ├── sync_response.dart
│   │   │   └── export_report.dart
│   │   ├── repositories/
│   │   │   ├── transaction_repository.dart
│   │   │   ├── sqlite_transaction_repository.dart
│   │   │   ├── debt_repository.dart
│   │   │   ├── sqlite_debt_repository.dart
│   │   │   └── repository_provider.dart
│   │   ├── services/
│   │   │   ├── sms/
│   │   │   │   └── sms_listener.dart
│   │   │   ├── parser/
│   │   │   │   ├── parsed_bank_sms.dart
│   │   │   │   ├── bank_identifier.dart
│   │   │   │   ├── telebirr_sms_parser.dart
│   │   │   │   ├── cbe_sms_parser.dart
│   │   │   │   ├── awash_sms_parser.dart
│   │   │   │   └── failed_parse_log.dart
│   │   │   └── sync_service.dart
│   │   ├── api_client/
│   │   │   └── mekenet_api_client.dart
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   ├── quick_add_screen.dart
│   │   │   ├── debts_screen.dart
│   │   │   └── settings_screen.dart
│   │   └── widgets/
│   │       └── bottom_nav_bar.dart
│   ├── assets/
│   │   └── sms_patterns.json
│   └── test/
│       └── parser/
│           └── telebirr_sms_parser_test.dart
│
├── server/                   # Python FastAPI backend
│   ├── main.py
│   ├── db/
│   │   └── database.py
│   ├── models/
│   │   └── transaction.py
│   ├── routes/
│   │   ├── sync.py
│   │   ├── export.py
│   │   └── hello.py
│   └── tests/
│       └── test_sync_export.py
```

### File-by-File Purpose

| File | What It Does (Plain English) |
|---|---|
| `main.dart` | App entry point. Initializes encrypted DB, SMS listener, sync service, then shows the app. |
| `database_helper.dart` | Creates and manages the encrypted SQLite database. Generates an encryption key, stores it securely, creates tables on first run. |
| `transaction.dart` | Defines what a transaction looks like: amount, direction (income/expense), source (which bank), timestamp, sync status. |
| `debt.dart` | Defines what a debt looks like: customer name, amount, status (open/paid), date created. |
| `sync_response.dart` | Defines what the server sends back after receiving a transaction (success/fail, count). |
| `export_report.dart` | Defines the structure of a financial report from the server (totals, category breakdowns, transaction list). |
| `transaction_repository.dart` | Interface — defines all operations you can do with transactions (save, query, delete, get totals). |
| `sqlite_transaction_repository.dart` | The real implementation — actually runs SQL queries against the encrypted database. |
| `debt_repository.dart` | Interface for debt operations. |
| `sqlite_debt_repository.dart` | Real implementation for debts. |
| `repository_provider.dart` | A central place that provides the right repository. Lets tests swap in fake versions. |
| `sms_listener.dart` | The orchestrator. Listens for incoming SMS, identifies the bank, routes to the right parser, saves to DB. |
| `parsed_bank_sms.dart` | The standard output format every parser returns (bank name, direction, amount, timestamp). |
| `bank_identifier.dart` | Loads `sms_patterns.json`, checks who sent the SMS, returns the bank name. |
| `telebirr_sms_parser.dart` | Regex patterns that extract amount, date, direction from Telebirr SMS text. |
| `cbe_sms_parser.dart` | Same for CBE (Commercial Bank of Ethiopia) SMS. |
| `awash_sms_parser.dart` | Same for Awash Bank SMS. |
| `failed_parse_log.dart` | When a parser can't handle an SMS, saves it to a log table for later review. |
| `sync_service.dart` | Manages syncing local transactions to the cloud. Has an opt-in toggle, retries on failure. |
| `mekenet_api_client.dart` | HTTP client that talks to the Python server. Sends transactions, fetches reports. |
| `home_screen.dart` | Dashboard — shows income/expenses/owed totals (currently hardcoded prototype data). |
| `quick_add_screen.dart` | Form to manually add an expense. Saves to SQLite and triggers sync. |
| `debts_screen.dart` | "Who owes me" list (currently hardcoded prototype data). |
| `settings_screen.dart` | Settings page with sync toggle, export button, privacy info. |
| `bottom_nav_bar.dart` | The 4-tab navigation bar at the bottom. |
| `sms_patterns.json` | Bank configuration — which phone numbers and keywords identify each bank. |
| `main.py` (server) | FastAPI app setup — CORS, router registration, creates DB tables on startup. |
| `database.py` (server) | SQLAlchemy setup — engine, session factory, connects to Neon PostgreSQL. |
| `transaction.py` (server) | Server-side transaction model (slightly different from mobile — optimized for export). |
| `sync.py` (server) | POST /sync endpoint — receives transactions, validates, deduplicates, stores. |
| `export.py` (server) | GET /export endpoint — generates financial reports with category breakdowns. |
| `hello.py` (server) | Smoke test endpoint — just returns "I'm working". |
| `test_sync_export.py` | 28 tests covering sync and export endpoints. |

---

## 3. System Architecture — The Big Picture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         ANDROID PHONE                               │
│                                                                     │
│  ┌──────────────┐    ┌──────────────────────────────────────────┐   │
│  │  SMS arrives  │───>│           SMS LISTENER                    │   │
│  │  (Telebirr/   │    │                                          │   │
│  │   CBE/Awash)  │    │  1. Bank Identifier (reads JSON config)  │   │
│  └──────────────┘    │  2. Parser (Telebirr/CBE/Awash)          │   │
│                      │  3. SHA-256 dedup check                   │   │
│                      │  4. Save to SQLite                        │   │
│                      └──────────────────┬───────────────────────┘   │
│                                         │                            │
│                                         ▼                            │
│                      ┌──────────────────────────────────────────┐   │
│                      │       ENCRYPTED SQLite DATABASE           │   │
│                      │                                          │   │
│                      │  ┌─────────────┐  ┌──────────────────┐   │   │
│                      │  │ transactions │  │     debts        │   │   │
│                      │  └─────────────┘  └──────────────────┘   │   │
│                      │  ┌──────────────────┐                    │   │
│                      │  │  failed_parses   │                    │   │
│                      │  └──────────────────┘                    │   │
│                      └──────────────────┬───────────────────────┘   │
│                                         │                            │
│                    ┌────────────────────┼────────────────────┐       │
│                    │                    │                     │       │
│                    ▼                    ▼                     ▼       │
│            ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│            │  Home Screen  │  │ Quick Add    │  │  Settings    │    │
│            │  (Dashboard)  │  │ (Add Expense)│  │ (Sync/Export)│    │
│            └──────────────┘  └──────────────┘  └──────┬───────┘    │
│                                                       │             │
│                                                       │ opt-in      │
│                                                       ▼             │
│                                              ┌────────────────┐     │
│                                              │  Sync Service   │     │
│                                              │  (retry queue)  │     │
│                                              └───────┬────────┘     │
└──────────────────────────────────────────────────────┼──────────────┘
                                                       │
                                                       │ POST /sync/
                                                       │ GET /export/
                                                       ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    NEON POSTGRESQL (Cloud)                           │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  FastAPI Server (server/main.py)                             │   │
│  │                                                              │   │
│  │  POST /sync/  ─── validates, deduplicates, stores            │   │
│  │  GET  /export/ ── builds report with totals + categories     │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  transactions table (server-side copy)                       │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

### Why This Architecture?

- **Offline-first:** The phone works without internet. The database is local. The server is optional.
- **Privacy by design:** Raw SMS is never stored or transmitted. Only structured data (amount, date, direction) leaves the phone, and only if the user enables sync.
- **Encryption at rest:** The SQLite file is encrypted. If someone steals the phone and plugs it into a computer, they can't read the database without the key.
- **Opt-in sync:** The server is a backup, not a requirement. The user decides.

---

## 4. Database Design — Visual Schema

### Mobile Database (Encrypted SQLite)

```
┌─────────────────────────────────────────────────────────────────┐
│                     transactions TABLE                           │
├──────────────────┬──────────┬───────────────────────────────────┤
│ Column           │ Type     │ Purpose                           │
├──────────────────┼──────────┼───────────────────────────────────┤
│ id               │ TEXT PK  │ UUID v4 (unique per transaction)  │
│ direction        │ TEXT     │ "income" or "expense"             │
│ amount           │ REAL     │ Amount in ETB (e.g. 5000.00)      │
│ source           │ TEXT     │ "telebirr", "cbe", "awash",       │
│                  │          │ "manual"                          │
│ raw_sms_hash     │ TEXT     │ SHA-256 hash (for dedup, no SMS   │
│                  │          │ text stored)                       │
│ counterparty_    │ TEXT     │ Currently stores bank name         │
│ masked           │          │ (future: masked phone number)      │
│ item_id          │ TEXT     │ NULL (future: price matching)      │
│ match_confidence │ TEXT     │ "unmatched" (future: learning)     │
│ category         │ TEXT     │ Category for manual expenses       │
│ timestamp        │ INTEGER  │ Unix epoch milliseconds            │
│ synced           │ INTEGER  │ 0 = not synced, 1 = synced         │
├──────────────────┴──────────┴───────────────────────────────────┤
│ Indexes: timestamp, synced, raw_sms_hash                        │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                       debts TABLE                                │
├──────────────────┬──────────┬───────────────────────────────────┤
│ Column           │ Type     │ Purpose                           │
├──────────────────┼──────────┼───────────────────────────────────┤
│ id               │ TEXT PK  │ UUID v4                            │
│ customer_name    │ TEXT     │ Who owes the money                 │
│ amount           │ REAL     │ How much in ETB                    │
│ status           │ TEXT     │ "open" or "paid"                   │
│ created_at       │ INTEGER  │ Unix epoch milliseconds            │
├──────────────────┴──────────┴───────────────────────────────────┤
│ Indexes: status, created_at                                     │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                   failed_parses TABLE                            │
├──────────────────┬──────────┬───────────────────────────────────┤
│ Column           │ Type     │ Purpose                           │
├──────────────────┼──────────┼───────────────────────────────────┤
│ id               │ INTEGER  │ Auto-increment primary key         │
│ raw_sms          │ TEXT     │ The full SMS text that failed      │
│ sender           │ TEXT     │ Phone number/shortcode that sent   │
│ reason           │ TEXT     │ "no_bank_match" or "parse_error"   │
│ created_at       │ INTEGER  │ Unix epoch milliseconds            │
└──────────────────┴──────────┴───────────────────────────────────┘
```

### Server Database (Neon PostgreSQL)

```
┌─────────────────────────────────────────────────────────────────┐
│               transactions TABLE (server-side)                   │
├──────────────────┬──────────┬───────────────────────────────────┤
│ Column           │ Type     │ Purpose                           │
├──────────────────┼──────────┼───────────────────────────────────┤
│ id               │ TEXT PK  │ Transaction UUID from mobile       │
│ type             │ TEXT     │ "income" or "expense"              │
│ amount           │ FLOAT    │ Amount in ETB                      │
│ description      │ TEXT     │ Counterparty info (masked)         │
│ date             │ TEXT     │ "YYYY-MM-DD" string                │
│ category         │ TEXT     │ Category (default: uncategorized)  │
│ currency         │ TEXT     │ "ETB" (default)                    │
│ device_id        │ TEXT     │ Which phone sent this              │
│ synced_at        │ DATETIME │ When it arrived on server           │
│ created_at       │ DATETIME │ When the record was created         │
└──────────────────┴──────────┴───────────────────────────────────┘
```

### Why Two Different Schemas?

The mobile schema uses integers for timestamps (faster queries on SQLite) and a hash for dedup. The server schema uses human-readable dates and a device_id for multi-device tracking. The **sync endpoint acts as a translation layer** between the two.

---

## 5. API Endpoints — Visual Reference

```
┌─────────────────────────────────────────────────────────────────┐
│                    FastAPI SERVER                                 │
│                    Port 8000                                      │
│                                                                   │
│  GET /health                                                      │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ Response: {"status": "ok"}                                  │ │
│  │ Purpose: Check if server is alive                           │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  POST /sync/                                                      │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ Headers:  X-Device-ID: <device-uuid>  (required)            │ │
│  │ Body:     {id, type, amount, description, date, category,   │ │
│  │            currency}                                        │ │
│  │                                                             │ │
│  │ Validates:                                                  │ │
│  │   - amount > 0                                              │ │
│  │   - type is "income" or "expense"                           │ │
│  │   - date is YYYY-MM-DD format                               │ │
│  │                                                             │ │
│  │ Deduplicates by transaction ID                              │ │
│  │                                                             │ │
│  │ Response (201): {success, message, transaction_id,          │ │
│  │                  stored_count}                              │ │
│  │ Response (401): Missing X-Device-ID                         │ │
│  │ Response (422): Invalid payload                             │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  GET /export/                                                     │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ Headers:  X-Device-ID: <device-uuid>  (required)            │ │
│  │ Params:   from_date (optional, YYYY-MM-DD)                  │ │
│  │           to_date   (optional, YYYY-MM-DD)                  │ │
│  │           type      (optional, "income"/"expense")          │ │
│  │                                                             │ │
│  │ Response (200):                                             │ │
│  │ {                                                           │ │
│  │   summary: {total_income, total_expense, net_balance,       │ │
│  │             transaction_count, currency},                    │ │
│  │   income_by_category: [{category, total, count}],           │ │
│  │   expense_by_category: [{category, total, count}],          │ │
│  │   transactions: [{id, type, amount, description, ...}],     │ │
│  │   generated_at: "ISO timestamp",                            │ │
│  │   filters_applied: {...}                                    │ │
│  │ }                                                           │ │
│  │                                                             │ │
│  │ Response (404): No data for this device                     │ │
│  │ Response (401): Missing X-Device-ID                         │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  GET /hello                                                       │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ Response: {"message": "I'm working"}                        │ │
│  │ Purpose: Smoke test                                         │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. User Flow — What the User Experiences

```
FIRST TIME USER
═══════════════

  ┌──────────┐     ┌──────────────┐     ┌────────────────┐
  │ Opens    │────>│ App asks for │────>│ DB is created  │
  │ app      │     │ SMS permission│    │ with encryption│
  └──────────┘     └──────────────┘     │ key generated  │
                                        └───────┬────────┘
                                                │
                                        ┌───────▼────────┐
                                        │ SMS listener   │
                                        │ starts         │
                                        └───────┬────────┘
                                                │
                                        ┌───────▼────────┐
                                        │ User sees home │
                                        │ screen (empty) │
                                        └────────────────┘


DAILY USE
═════════

  ┌──────────┐     ┌──────────────┐     ┌────────────────┐
  │ User     │     │ SMS arrives  │     │ App parses it  │
  │ receives │────>│ from bank    │────>│ automatically  │
  │ payment  │     │              │     │                │
  └──────────┘     └──────────────┘     └───────┬────────┘
                                                │
                          ┌─────────────────────┤
                          │                     │
                  ┌───────▼────────┐   ┌───────▼────────┐
                  │ Transaction    │   │ If parse fails  │
                  │ saved locally  │   │ → saved to log  │
                  └───────┬────────┘   └────────────────┘
                          │
              ┌───────────┼───────────┐
              │           │           │
      ┌───────▼──────┐  ┌▼───────────┐  ┌▼────────────────┐
      │ Home screen  │  │ Quick Add  │  │ Settings        │
      │ shows new    │  │ manual     │  │ toggle sync     │
      │ transaction  │  │ expense    │  │ on/off          │
      └──────────────┘  └────────────┘  └─────────────────┘


SYNCING TO CLOUD (opt-in)
══════════════════════════

  ┌──────────┐     ┌──────────────┐     ┌────────────────┐
  │ User     │     │ Sync toggle  │     │ Unsynced       │
  │ enables  │────>│ turned ON    │────>│ transactions   │
  │ sync     │     │ in settings  │     │ sent to server │
  └──────────┘     └──────────────┘     └───────┬────────┘
                                                │
                                        ┌───────▼────────┐
                                        │ Server stores  │
                                        │ in PostgreSQL   │
                                        └───────┬────────┘
                                                │
                                        ┌───────▼────────┐
                                        │ Local record   │
                                        │ marked synced  │
                                        └────────────────┘
```

---

## 7. App Flow — What Happens Inside the Code

### Startup Sequence

```
main() called
    │
    ├── WidgetsFlutterBinding.ensureInitialized()
    │
    ├── DatabaseHelper.instance.database
    │       │
    │       ├── Read encryption key from FlutterSecureStorage
    │       │   (backed by Android Keystore)
    │       │
    │       ├── If no key exists → generate one, store it
    │       │
    │       └── Open encrypted SQLite database
    │           ├── If first run → create tables + indexes
    │           └── Return database instance
    │
    ├── SmsListener().initialize()
    │       │
    │       ├── BankIdentifier.load()
    │       │   └── Load sms_patterns.json from assets
    │       │
    │       ├── Request SMS permission from Android
    │       │
    │       └── Register onNewMessage callback
    │
    ├── SyncService.instance.initialize()
    │       │
    │       ├── Read or generate device ID
    │       │   (stored in FlutterSecureStorage)
    │       │
    │       └── Inject device ID into MekenetApiClient
    │
    └── runApp(MyApp())
            │
            ├── Build MaterialApp with green theme (#0A8E48)
            │
            └── MainScreen with 4 tabs:
                    ├── Tab 0: HomeScreen (dashboard)
                    ├── Tab 1: QuickAddScreen (add expense)
                    ├── Tab 2: DebtsScreen (who owes me)
                    └── Tab 3: SettingsScreen (sync/export)
```

### Screen Wiring Status

| Screen | Connected to DB? | Status |
|---|---|---|
| `HomeScreen` | No — hardcoded data | Needs wiring to repository |
| `QuickAddScreen` | **Yes** — saves to SQLite + triggers sync | Complete |
| `DebtsScreen` | No — hardcoded data | Needs wiring to repository |
| `SettingsScreen` | **Yes** — sync toggle + export | Complete |

---

## 8. SMS Pipeline — Step by Step

This is the most important flow in the app. It runs automatically whenever an SMS arrives.

```
┌─────────────────────────────────────────────────────────────────┐
│                    SMS RECEIVED                                  │
│  Android triggers onNewMessage callback                          │
│  Input: smsText (String), sender (String?)                      │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 1: IDENTIFY THE BANK                                       │
│  BankIdentifier.identify(sender, smsText)                        │
│                                                                   │
│  a) Load sms_patterns.json (cached after first load)              │
│  b) Check sender against known shortcodes:                       │
│     - "8047" → could be Telebirr or Awash                        │
│     - "973"  → CBE                                               │
│  c) If sender matches → return that bank                         │
│  d) If not → search SMS body for keywords:                       │
│     - "telebirr" → Telebirr                                      │
│     - "CBE" / "Commercial Bank" → CBE                            │
│     - "Awash" → Awash                                            │
│  e) If nothing matches → return null                             │
│                                                                   │
│  Output: "Telebirr" | "CBE" | "Awash" | null                    │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                    ┌───────┴───────┐
                    │               │
                bank != null    bank == null
                    │               │
                    ▼               ▼
                    │        ┌──────────────────────────────────┐
                    │        │ STEP 1b: LOG FAILED PARSE         │
                    │        │ FailedParseLog.save(               │
                    │        │   smsText, sender,                 │
                    │        │   "no_bank_match"                  │
                    │        │ )                                  │
                    │        │ → Saves to failed_parses table     │
                    │        │ → Returns (stops processing)       │
                    │        └──────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 2: PARSE THE SMS                                           │
│  Route to parser based on bank name:                             │
│                                                                   │
│  "Telebirr" → TelebirrSmsParser.parse(smsText)                   │
│  "CBE"      → CbeSmsParser.parse(smsText)                        │
│  "Awash"    → AwashSmsParser.parse(smsText)                      │
│                                                                   │
│  Each parser:                                                     │
│  a) Guard: must contain "ETB" + bank name                        │
│  b) Guard: must contain direction keywords                       │
│     - Telebirr: "You have transferred" / "You have received"     │
│     - CBE: "debited" / "credited"                                │
│     - Awash: "sent" / "received"                                 │
│  c) Extract amount via regex: ETB\s+([\d,]+\.\d{2})              │
│  d) Extract date: on\s+(\d{2}/\d{2}/\d{4}\s+\d{2}:\d{2}:\d{2}) │
│  e) Extract balance (optional): balance is\s+ETB\s+([\d,]+\.\d{2})│
│  f) Return ParsedBankSms or null (never guesses)                 │
│                                                                   │
│  Output: ParsedBankSms {bankName, direction, amount, timestamp}  │
│          or null                                                  │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                    ┌───────┴───────┐
                    │               │
              parsed != null   parsed == null
                    │               │
                    ▼               ▼
                    │        ┌──────────────────────────────────┐
                    │        │ STEP 2b: LOG PARSE ERROR          │
                    │        │ FailedParseLog.save(               │
                    │        │   smsText, sender,                 │
                    │        │   "parse_error"                    │
                    │        │ )                                  │
                    │        │ → Returns (stops processing)       │
                    │        └──────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 3: DEDUPLICATE                                             │
│                                                                   │
│  a) Compute SHA-256 hash of raw SMS text                         │
│     hash = sha256(utf8.encode(smsText))                          │
│  b) Check: RepositoryProvider.transaction.existsBySmsHash(hash)  │
│     → SELECT id FROM transactions                                │
│       WHERE raw_sms_hash = '<hash>' LIMIT 1                      │
│  c) If exists → skip (log "Duplicate SMS ignored")               │
│  d) If new → continue                                            │
│                                                                   │
│  Why hash instead of storing raw SMS?                            │
│  → Privacy guarantee: raw text is never persisted                │
│  → Still allows exact duplicate detection                        │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 4: SAVE TRANSACTION                                        │
│                                                                   │
│  Create Transaction(                                             │
│    id: Uuid().v4(),                                              │
│    direction: parsed.direction == received ? "income" : "expense"│
│    amount: parsed.amount,                                        │
│    source: parsed.bankName.toLowerCase(),                        │
│    rawSmsHash: hash,                                             │
│    counterpartyMasked: parsed.bankName,                          │
│    timestamp: parsed.timestamp,                                  │
│  )                                                               │
│                                                                   │
│  RepositoryProvider.transaction.save(transaction)                │
│  → INSERT OR REPLACE INTO transactions ...                       │
│                                                                   │
│  ✅ Done. Transaction is now in the encrypted local database.    │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 5: SYNC (if enabled)                                       │
│                                                                   │
│  SyncService.syncOne(transaction)                                │
│  → Checks if sync is enabled (SharedPreferences toggle)          │
│  → If enabled: POST /sync/ to server                             │
│  → On success: markSynced(id) → sets synced = 1 in SQLite       │
│  → On failure: leaves synced = 0, retries later                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 9. Sync Pipeline — Phone to Server

```
┌─────────────────────────────────────────────────────────────────┐
│                    TRIGGER POINTS                                 │
│                                                                   │
│  1. Immediately after saving a transaction (if sync enabled)     │
│  2. On app resume (retryUnsynced)                                │
│  3. When user toggles sync ON (retryUnsynced)                    │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  SyncService.syncOne(transaction)                                │
│                                                                   │
│  1. Check SharedPreferences "sync_enabled" → false by default    │
│  2. If false → return (do nothing)                               │
│  3. Call MekenetApiClient.syncTransaction(tx)                    │
│     │                                                             │
│     ├── Map mobile fields → server fields:                       │
│     │   direction  → type                                        │
│     │   counterpartyMasked → description                         │
│     │   timestamp  → date (YYYY-MM-DD)                           │
│     │                                                             │
│     ├── POST http://10.0.2.2:8000/sync/                          │
│     │   Headers: {Content-Type: application/json,                │
│     │             X-Device-ID: <device-uuid>}                    │
│     │   Body: {id, type, amount, description, date,             │
│     │          category, currency}                               │
│     │                                                             │
│     ├── 10 second timeout                                        │
│     │                                                             │
│     └── Returns SyncResponse or null (never throws)              │
│                                                                   │
│  4. If success → markSynced(tx.id)                               │
│     → UPDATE transactions SET synced = 1 WHERE id = ?            │
│  5. If failure → leave synced = 0, log, retry later             │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  Server: POST /sync/                                             │
│                                                                   │
│  1. Validate X-Device-ID header (401 if missing)                 │
│  2. Validate JSON payload with Pydantic model                    │
│     - amount > 0                                                 │
│     - type is "income" or "expense"                              │
│     - date is YYYY-MM-DD                                         │
│  3. Check for duplicate by transaction ID                        │
│     - If exists → return "deduplicated"                          │
│  4. Create SQLAlchemy Transaction, commit to PostgreSQL          │
│  5. Return SyncResponse {success, message, transaction_id,       │
│                          stored_count}                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## 10. Export Pipeline — Server to Loan Officer

```
┌─────────────────────────────────────────────────────────────────┐
│  User taps "Export Report" in Settings                           │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  Export Dialog appears (bottom sheet)                             │
│                                                                   │
│  Options:                                                        │
│  - Date range: From / To (optional)                              │
│  - Type filter: All / Income only / Expense only                 │
│  - "Generate Report" button                                      │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  MekenetApiClient.exportReport(fromDate, toDate, type)           │
│                                                                   │
│  GET http://10.0.2.2:8000/export/?from_date=X&to_date=Y&type=Z  │
│  Headers: {X-Device-ID: <device-uuid>}                          │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  Server: GET /export/                                            │
│                                                                   │
│  1. Validate X-Device-ID                                        │
│  2. Build query with optional filters                            │
│  3. Compute:                                                    │
│     - total_income = SUM(amount) WHERE type = "income"           │
│     - total_expense = SUM(amount) WHERE type = "expense"         │
│     - net_balance = total_income - total_expense                 │
│     - income_by_category: GROUP BY category                      │
│     - expense_by_category: GROUP BY category                     │
│  4. Return full report JSON                                      │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  Response displayed as formatted bottom sheet:                   │
│                                                                   │
│  ┌─────────────────────────────────────┐                        │
│  │        FINANCIAL REPORT             │                        │
│  │                                     │                        │
│  │  Total Income:     ETB 45,000       │                        │
│  │  Total Expenses:   ETB 12,000       │                        │
│  │  Net Balance:      ETB 33,000       │                        │
│  │  Transactions:     156              │                        │
│  │                                     │                        │
│  │  EXPENSE BREAKDOWN:                 │                        │
│  │  ├── Supplies:  ETB 5,000 (12)      │                        │
│  │  ├── Rent:      ETB 3,000 (3)       │                        │
│  │  ├── Transport: ETB 2,500 (28)      │                        │
│  │  └── Other:     ETB 1,500 (8)       │                        │
│  │                                     │                        │
│  │  Generated: 2026-08-19T10:30:00     │                        │
│  └─────────────────────────────────────┘                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## 11. Security & Privacy Design

### Encryption Layer

```
┌─────────────────────────────────────────────────────────────────┐
│                    KEY GENERATION                                 │
│                                                                   │
│  First launch:                                                    │
│  1. Read key "mekenet_db_key" from FlutterSecureStorage           │
│  2. If null → generate: "mekenet-{timestamp_hex}-{hash}"        │
│  3. Write key to FlutterSecureStorage                             │
│     (backed by Android Keystore on physical devices)              │
│                                                                   │
│  Subsequent launches:                                             │
│  1. Read key from FlutterSecureStorage                           │
│  2. Open database with that key as password                       │
│                                                                   │
│  If secure storage is wiped → database becomes unreadable         │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    ENCRYPTION IN PRACTICE                         │
│                                                                   │
│  sqflite_sqlcipher encrypts the entire SQLite file.              │
│  The "password" is the encryption key.                           │
│                                                                   │
│  Without the key:                                                │
│  - The .db file looks like random bytes                          │
│  - Cannot be read by any tool                                    │
│  - Even rooting the phone doesn't help (key is in Keystore)     │
└─────────────────────────────────────────────────────────────────┘
```

### Privacy Guarantees

| Guarantee | How It's Enforced |
|---|---|
| Raw SMS never stored | Only SHA-256 hash saved in `raw_sms_hash` column |
| Raw SMS never transmitted | No code in the app sends raw SMS text anywhere |
| Data stays on phone by default | Sync is opt-in, off by default, requires explicit toggle |
| Only structured data syncs | Sync endpoint accepts {amount, type, date} — no SMS content |
| User controls sync | Toggle in Settings, stored in SharedPreferences |

### What We're NOT Doing (And Why)

| Approach | Why We Rejected It |
|---|---|
| OAuth / user accounts | Overkill for a pilot with 30 users. Device ID is sufficient. |
| End-to-end encryption for sync | The server needs to read the data for export. TLS is enough. |
| Biometric lock | PIN lock is in the SDD but not yet implemented. Planned for next phase. |
| CSPRNG for key generation | `DateTime.now().microsecondsSinceEpoch` is sufficient for the threat model (casual file access, not targeted attacks). |

---

## 12. Testing Strategy

### What Exists

```
┌─────────────────────────────────────────────────────────────────┐
│                    TEST PYRAMID                                   │
│                                                                   │
│                    ┌───────────┐                                  │
│                    │Integration│  ← 0 tests (empty folder)        │
│                    │   tests   │                                  │
│                  ┌─┴───────────┴─┐                                │
│                  │  Widget tests  │ ← 1 test (placeholder)        │
│                ┌─┴───────────────┴─┐                              │
│                │   Unit tests       │ ← 11 Telebirr parser tests  │
│              ┌─┴───────────────────┴─┐                            │
│              │   Server E2E tests     │ ← 28 tests (sync+export)  │
│              └───────────────────────┘                            │
└─────────────────────────────────────────────────────────────────┘
```

### Parser Tests (11 passing)

Tests use 10 real anonymized Telebirr SMS samples. Each test verifies:
- Correct direction (sent/received)
- Correct amount
- Correct timestamp
- Correct balance (when present)
- Returns null for non-transaction SMS

### Server Tests (28 passing)

Uses in-memory SQLite (not real Postgres) for isolation. Covers:
- Sync: success, validation, dedup, missing device ID
- Export: no data, single/multiple transactions, category breakdowns, filtering, date ranges

### What's Missing

| Gap | Priority | Owner |
|---|---|---|
| CBE parser tests | High | Parser team member |
| Awash parser tests | High | Parser team member |
| Repository CRUD unit tests | Medium | Storage team member |
| Widget tests for screens | Low | Frontend team member |
| Integration test (SMS → DB → screen) | Low | Team lead |

---

## 13. What's Done vs. What's Left

### ✅ COMPLETE (Working)

| Feature | Branch | Status |
|---|---|---|
| Encrypted SQLite database | `main` | Working — creates DB, generates key, stores in Keystore |
| Transaction model + repository | `main` | Working — full CRUD + query methods |
| Debt model + repository | `main` | Working — full CRUD |
| Repository provider (DI) | `main` | Working — singleton + mock injection |
| SMS listener (Telebirr) | `main` | Working — parses real SMS, saves to DB |
| Multi-bank detection | `main` | Working — Telebirr, CBE, Awash via JSON config |
| CBE parser | `main` | Working — placeholder patterns (needs real SMS tuning) |
| Awash parser | `main` | Working — placeholder patterns (needs real SMS tuning) |
| Failed parse logging | `main` | Working — saves to failed_parses table |
| FastAPI server | `main` | Working — POST /sync/, GET /export/, GET /health |
| Neon PostgreSQL connection | `main` | Working — live connection verified |
| Sync endpoint | `main` | Working — validates, deduplicates, stores |
| Export endpoint | `main` | Working — generates reports with category breakdowns |
| Server tests (28) | `main` | All passing |
| API client (HTTP) | `pr/30` | Working — field mapping, error handling, device ID |
| Sync service (orchestrator) | `pr/30` | Working — opt-in toggle, retry, device ID |
| Settings screen (sync/export) | `pr/30` | Working — toggle + export dialog |
| Quick Add screen | `pr/30` | Working — saves to SQLite + triggers sync |
| Telebirr parser tests (11) | `main` | All passing |

### 🔄 IN PROGRESS / NEEDS MERGE

| Feature | Branch | Status |
|---|---|---|
| API client + sync + export screens | `pr/30` | Merged but NOT on `main` yet — needs merge to main |

### ❌ NOT YET DONE

| Feature | Priority | Difficulty | Assigned To |
|---|---|---|---|
| **Merge pr/30 to main** | Critical | Easy | Team lead |
| **Wire HomeScreen to real data** | High | Medium | Frontend |
| **Wire DebtsScreen to real DB** | High | Medium | Frontend |
| **CBE/Awash real SMS tuning** | High | Medium | Parser team |
| **CBE/Awash parser tests** | High | Easy | Parser team |
| **Repository unit tests** | Medium | Easy | Storage team |
| **Server tests for CBE/Awash** | Medium | Easy | Backend team |
| PIN lock on app launch | Medium | Medium | Onboarding team |
| Onboarding flow (first launch) | Medium | Medium | Onboarding team |
| Category budgets | Low | Medium | Analytics team |
| Analytics dashboard | Low | Hard | Analytics team |
| Item/PriceMatch logic | Low | Hard | Core engine team |
| Background SMS listener | Low | Hard | SMS team |
| Notification on SMS parse | Low | Easy | Frontend |

---

## 14. Key Decisions & Why

### Why Offline-First?

Ethiopia has no open banking API. SMS is the only way to get transaction data. Shop owners have unreliable internet. The app MUST work without network. The server is a backup, not a requirement.

### Why Encrypted SQLite?

The PRD says users fear digital records drawing tax attention. If the phone is lost or stolen, the database must be unreadable. `sqflite_sqlcipher` provides this with zero extra code from the developer.

### Why Pure-Function Parsers?

A parser that returns null on ambiguity is better than one that guesses wrong. "Unknown" prompts one tap. A wrong number silently breaks trust. Pure functions are also trivially unit-testable against a corpus of real messages.

### Why SHA-256 Hash Instead of Storing Raw SMS?

Privacy guarantee: the raw SMS text is never persisted. The hash allows exact duplicate detection without retaining the original message. This is a provable claim — the database schema itself enforces it.

### Why JSON-Driven Bank Identification?

Adding a new bank should be a data change (add a row to `sms_patterns.json`), not a code change. This makes it easy for team members who aren't Flutter developers to contribute.

### Why Server Schema Differs from Mobile?

The server needs to serve export consumers (loan officers) who need human-readable descriptions and ISO dates. The `device_id` header enables multi-device tracking in the future. The sync endpoint is the translation boundary.

### Why Foreground-Only SMS Listener?

Background SMS listeners on Android require special permissions, background service management, and battery optimization whitelisting. For an 8-day MVP, foreground-only is the pragmatic choice. SMS arriving while the app is closed will be captured on next launch.

### Why Opt-In Sync?

The PRD explicitly states that users fear tax attention. Sync being off by default and requiring an explicit toggle is a product requirement, not just a technical one. The user must feel in control.

---

*Document version: 1.0 — August 2026*
*Last updated: After merge of pr/30 (SMS multi-bank + API client/sync/export)*
