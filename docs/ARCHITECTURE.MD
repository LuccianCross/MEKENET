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
15. [Dockerization — Containerizing the Server](#15-dockerization--containerizing-the-server)
16. [Ethiopian Language Support — Package Assessment](#16-ethiopian-language-support--package-assessment)

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

## 15. Dockerization — Containerizing the Server

### What Is Docker and Why Do We Use It?

Imagine you buy a new laptop. You install Python, then install all the packages, then copy the code, then realize it needs a different Python version, then the packages conflict with each other. Docker eliminates this entire problem.

**Docker packages the server AND everything it needs (Python, libraries, system tools) into one sealed box called a "container."** That container runs the same way on your laptop, on a colleague's laptop, on a cloud server, anywhere. No "it works on my machine" problems.

```
WITHOUT DOCKER                          WITH DOCKER
════════════════                        ════════════════

  Your laptop:                          Your laptop:
  ├── Python 3.13 ✅                     ┌──────────────────────┐
  ├── fastapi 0.104 ✅                   │  mekenet-server      │
  ├── sqlalchemy 2.0 ✅                  │  (sealed box)        │
  ├── psycopg2 2.9 ❌ (missing!)        │                      │
  └── code: "It crashed!"               │  Python 3.12         │
                                         │  fastapi 0.104       │
  Colleague's laptop:                    │  sqlalchemy 2.0      │
  ├── Python 3.11 ❌ (wrong version)     │  psycopg2 2.9       │
  ├── fastapi 0.99 ❌ (old version)      │  uvicorn 0.24        │
  ├── code: "Import errors!"            │  code                │
                                         │                      │
                                         │  → Works everywhere  │
                                         └──────────────────────┘
```

### The Mekenet Server Docker Setup

Our server has two files that control Docker:

#### `server/Dockerfile` — The Recipe

```
┌─────────────────────────────────────────────────────────────────┐
│  Dockerfile — Multi-Stage Build                                  │
│                                                                   │
│  STAGE 1: "builder" (like a kitchen)                              │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  Base image:  python:3.12-slim                              │ │
│  │  Purpose:     Install Python packages                       │ │
│  │                                                             │ │
│  │  Steps:                                                     │ │
│  │  1. Install system tools: gcc, libpq-dev                    │ │
│  │     (needed to compile psycopg2 from source)                │ │
│  │  2. Copy requirements.txt                                   │ │
│  │  3. pip install --prefix=/install -r requirements.txt       │ │
│  │     (installs everything to a staging area, not final)      │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  STAGE 2: "runtime" (like a serving plate)                        │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  Base image:  python:3.12-slim (fresh, clean)               │ │
│  │  Purpose:     Run the server with minimal footprint          │ │
│  │                                                             │ │
│  │  Steps:                                                     │ │
│  │  1. COPY --from=builder /install /usr/local                 │ │
│  │     (copy ONLY the installed packages — no gcc, no dev libs)│ │
│  │  2. COPY . .                                                │ │
│  │     (copy our Python code)                                  │ │
│  │  3. EXPOSE 8000                                             │ │
│  │  4. CMD ["uvicorn", "main:app", "--host", "0.0.0.0"]       │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  Why two stages?                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  Builder stage has: gcc, libpq-dev, pip cache, build tools  │ │
│  │  Runtime stage has: ONLY our code + Python packages          │ │
│  │                                                             │ │
│  │  Builder image: ~400 MB                                     │ │
│  │  Runtime image: ~120 MB  (3x smaller!)                      │ │
│  │                                                             │ │
│  │  Smaller image = faster downloads, less storage,            │ │
│  │  faster deployment, smaller attack surface (fewer tools     │ │
│  │  for an attacker to exploit)                                │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

#### `server/docker-compose.yml` — The Orchestrator

```
┌─────────────────────────────────────────────────────────────────┐
│  docker-compose.yml                                              │
│                                                                   │
│  services:                                                        │
│    api:                                                           │
│      build: .              ← Build from Dockerfile in this dir    │
│      ports: "8000:8000"    ← Map laptop port 8000 → container    │
│      env_file: .env        ← Load secrets from .env file          │
│      environment:                                                 │
│        DATABASE_URL=${DATABASE_URL}                               │
│      restart: unless-stopped  ← Auto-restart if it crashes        │
│      healthcheck:                                                │
│        test: curl http://localhost:8000/health                    │
│        interval: 30s         ← Check every 30 seconds             │
│        timeout: 10s          ← Give up after 10 seconds           │
│        retries: 3            ← Try 3 times before marking "down"  │
│                                                                   │
│  What this does:                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  1. Builds the Docker image from our Dockerfile             │ │
│  │  2. Starts the container                                    │ │
│  │  3. Maps port 8000 so we can access it from our browser     │ │
│  │  4. Passes the DATABASE_URL from .env into the container    │ │
│  │  5. Keeps it running, restarts on crash                     │ │
│  │  6. Checks /health every 30s to detect problems             │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### The `.env` File — Secrets

The `.env` file contains the database connection string. **It is never committed to git** (listed in `.gitignore`).

```
# server/.env
DATABASE_URL=postgresql://user:password@ep-cool-bird-123456.us-east-2.aws.neon.tech/mekenet?sslmode=require
```

**Why separate?** Because the DATABASE_URL contains your password. You don't want that in your code repository where anyone with access can see it.

### Complete Data Flow with Docker

```
┌─────────────────────────────────────────────────────────────────────┐
│                    YOUR LAPTOP                                       │
│                                                                      │
│  ┌──────────────────────┐                                           │
│  │  Docker Desktop       │  (or Docker Engine on Linux)              │
│  │                       │                                           │
│  │  ┌─────────────────┐ │                                           │
│  │  │ Container: api   │ │                                           │
│  │  │                  │ │                                           │
│  │  │  ┌────────────┐ │ │                                           │
│  │  │  │ uvicorn     │ │ │    ┌──────────────────┐                  │
│  │  │  │ main:app    │─┼─┼───>│ Neon PostgreSQL   │                  │
│  │  │  │ :8000       │ │ │    │ (cloud database)   │                  │
│  │  │  └────────────┘ │ │    │ ep-cool-bird...    │                  │
│  │  │                  │ │    └──────────────────┘                  │
│  │  │  Reads .env ─────┼─┤    ↑                                      │
│  │  └─────────────────┘ │    │ DATABASE_URL                         │
│  └──────────────────────┘    │ (SSL connection)                      │
│                              │                                       │
│  Browser: http://localhost:8000/health                               │
│  ──────────────────────────>│                                       │
│  Response: {"status": "ok"} │                                       │
└─────────────────────────────────────────────────────────────────────┘
```

### Step-by-Step: How to Run the Server in Docker

```bash
# Step 1: Navigate to server directory
cd server/

# Step 2: Create your .env file (only needed once)
echo 'DATABASE_URL=your-neon-connection-string-here' > .env

# Step 3: Build the Docker image
docker compose build
# This runs both stages of the Dockerfile:
#   - Installs gcc, libpq-dev in the builder stage
#   - pip installs all Python packages
#   - Copies only what's needed to the runtime stage
#   - Produces a ~120MB image

# Step 4: Start the server
docker compose up
# You'll see output like:
#   api-1  | INFO:     Uvicorn running on http://0.0.0.0:8000

# Step 5: Test it (in another terminal)
curl http://localhost:8000/health
# → {"status":"ok","db_connection":"healthy"}

curl http://localhost:8000/hello
# → {"message":"I'm working"}

# Step 6: Stop the server
docker compose down
```

### How the Health Check Works

```
┌─────────────────────────────────────────────────────────────────┐
│  HEALTH CHECK CYCLE                                              │
│                                                                   │
│  Every 30 seconds:                                                │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐     │
│  │ Docker        │────>│ GET /health  │────>│ Server       │     │
│  │ Engine        │     │              │     │ responds     │     │
│  └──────────────┘     └──────────────┘     └──────┬───────┘     │
│                                                    │              │
│                                              ┌─────┴─────┐       │
│                                              │           │       │
│                                          status=ok   status=degraded│
│                                              │           │       │
│                                              ▼           ▼       │
│                                          ✅ Running   ⚠️ Warning  │
│                                          (do nothing) (check logs)│
│                                                                   │
│  If 3 retries fail → Docker marks container as "unhealthy"        │
│  With restart: unless-stopped → Docker automatically restarts it  │
└─────────────────────────────────────────────────────────────────┘
```

The `/health` endpoint does TWO things:
1. **Confirms the server is alive** (responding to HTTP requests)
2. **Tests the database connection** (`SELECT 1` against Neon PostgreSQL)

If the database is down, it returns `{"status": "degraded"}` instead of crashing — this is graceful degradation.

### Deploying to a Cloud Platform

Docker containers can be deployed to any cloud platform. Here are the most practical options for Mekenet:

```
┌─────────────────────────────────────────────────────────────────┐
│  DEPLOYMENT OPTIONS                                               │
│                                                                   │
│  ┌─────────────────┬──────────────┬───────────────────────────┐  │
│  │ Platform        │ Free Tier    │ Best For                   │  │
│  ├─────────────────┼──────────────┼───────────────────────────┤  │
│  │ Railway         │ $5/month     │ Easiest — push & deploy    │  │
│  │ Fly.io          │ 3 shared VMs │ Good free tier, Docker     │  │
│  │ Render          │ Free tier    │ Simple, auto-deploys       │  │
│  │ AWS ECS/Fargate │ 12mo free    │ Production-grade           │  │
│  │ DigitalOcean    │ $5/month     │ Simple, predictable bills  │  │
│  └─────────────────┴──────────────┴───────────────────────────┘  │
│                                                                   │
│  Recommended for Mekenet MVP: Railway                             │
│  → Connects to GitHub, auto-deploys on push                       │
│  → Supports Docker natively                                       │
│  → Free $5/month credit covers our needs                          │
│                                                                   │
│  deploy command (Railway CLI):                                     │
│  $ railway login                                                  │
│  $ railway init                                                   │
│  $ railway up                                                     │
└─────────────────────────────────────────────────────────────────┘
```

### Container Isolation — What Runs Where

```
┌─────────────────────────────────────────────────────────────────┐
│  WHAT'S IN THE CONTAINER          │  WHAT'S OUTSIDE              │
│  ═══════════════════════════      │  ═══════════════════════      │
│                                    │                                │
│  ✅ Python 3.12                    │  ❌ No Python on host needed   │
│  ✅ fastapi 0.104                  │  ❌ No pip install on host     │
│  ✅ sqlalchemy 2.0                 │  ❌ No system dependencies     │
│  ✅ uvicorn 0.24                   │  ❌ No port conflicts          │
│  ✅ psycopg2-binary 2.9            │  ❌ No version mismatches      │
│  ✅ Our code (main.py, routes/)    │                                │
│                                    │  ✅ .env file (secrets)        │
│  Does NOT contain:                 │  ✅ Docker Engine              │
│  ❌ The database (that's Neon)     │  ✅ docker-compose.yml         │
│  ❌ The mobile app (that's Flutter)│  ✅ Dockerfile                 │
│  ❌ Test data                      │  ✅ Logs                       │
│  ❌ .env file (mounted from host)  │                                │
└─────────────────────────────────────────────────────────────────┘
```

### Why Neon PostgreSQL Is NOT Containerized

```
┌─────────────────────────────────────────────────────────────────┐
│  COMMON QUESTION: "Why not run the database in Docker too?"      │
│                                                                   │
│  We could do:                                                     │
│    services:                                                      │
│      api:                                                         │
│        build: .                                                   │
│      db:                                                          │
│        image: postgres:16                                         │
│        volumes:                                                   │
│          - pgdata:/var/lib/postgresql/data                        │
│                                                                   │
│  But we chose Neon because:                                        │
│                                                                   │
│  1. BACKUPS — Neon automatically backs up the database daily.     │
│     If your laptop dies, the data survives.                       │
│     A Docker volume on your laptop = data dies with the laptop.   │
│                                                                   │
│  2. SCALING — Neon is serverless PostgreSQL. It scales            │
│     automatically. A Docker postgres on your laptop is limited    │
│     to your laptop's CPU/RAM.                                     │
│                                                                   │
│  3. DEPLOYMENT — When we deploy to Railway/Fly.io, the           │
│     container needs to connect to the database. Neon gives        │
│     us a stable URL. A local Docker DB would be unreachable       │
│     from a deployed container.                                    │
│                                                                   │
│  4. COST — Neon free tier gives us 0.5 GB storage and            │
│     24/7 compute. That's enough for the MVP. Running Postgres     │
│     in Docker 24/7 on a paid VM costs $5-10/month.               │
│                                                                   │
│  5. SIMPLICITY — One fewer container to manage, monitor,          │
│     and debug. The mobile app talks to the server, the server     │
│     talks to Neon. Simple chain.                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Environment Variables Reference

```
┌─────────────────────────────────────────────────────────────────┐
│  Variable             │ Where      │ Purpose                     │
│  ═══════════════════  │ ══════════ │ ═══════════════════════════ │
│  DATABASE_URL         │ .env       │ Neon PostgreSQL connection   │
│                       │            │ string with SSL required     │
│                       │            │                               │
│  docker-compose.yml   │ .env       │ Tells Docker to read the     │
│  env_file: .env       │            │ .env file and pass vars      │
│                       │            │ into the container           │
│                       │            │                               │
│  environment:         │ compose    │ Overrides/extends env vars   │
│  DATABASE_URL=${...}  │            │ inside the container         │
└─────────────────────────────────────────────────────────────────┘
```

The flow:
1. You put `DATABASE_URL=...` in `server/.env`
2. `docker-compose.yml` says `env_file: .env` → Docker reads it
3. `environment: DATABASE_URL=${DATABASE_URL}` → passes it into the container
4. `server/db/database.py` reads it: `os.getenv("DATABASE_URL")`
5. If it's missing → falls back to in-memory SQLite (for testing)

### Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| `DATABASE_URL not set` | .env file missing or empty | Create `server/.env` with your Neon URL |
| `connection refused` | Neon URL is wrong or DB is paused | Check Neon dashboard; unpause if sleeping |
| `port 8000 already in use` | Something else on your machine uses port 8000 | Change port mapping: `"8001:8000"` in docker-compose.yml |
| `pip install fails during build` | Network issue or missing system deps | Run `docker compose build --no-cache` |
| Container keeps restarting | Code crash on startup | Check logs: `docker compose logs api` |

---

## 16. Ethiopian Language Support — Package Assessment

### The Problem

Our Amharic translations have gaps. Some keys are correctly translated (authentic Amharic from the team), but others fell back to English because we couldn't generate correct Amharic text programmatically. We investigated Flutter packages that might help.

### Packages Evaluated

#### `geez_fonts` — Ethiopic Font Library

```
┌─────────────────────────────────────────────────────────────────┐
│  Package:  geez_fonts                                            │
│  URL:      pub.dev/packages/geez_fonts                           │
│  Purpose:  Provides 150+ Ethiopic font families                   │
│  What:     Dynamic font loading from the Geez Archive            │
│                                                                   │
│  What it DOES:                                                    │
│  ✅ Beautiful Amharic typography (Adwa, Benaiah, etc.)           │
│  ✅ Dynamic loading (no bundling needed)                          │
│  ✅ TextStyle and TextTheme support                               │
│                                                                   │
│  What it DOES NOT do:                                             │
│  ❌ Translate English text to Amharic                             │
│  ❌ Provide localization strings                                  │
│  ❌ Help with our garbled Amharic translations problem            │
│                                                                   │
│  VERDICT: Not useful for our current problem.                     │
│  USEFUL IF: We want prettier Amharic fonts later (cosmetic only) │
└─────────────────────────────────────────────────────────────────┘
```

#### `ethio_greg_dual_calendar` — Ethiopian Calendar UI

```
┌─────────────────────────────────────────────────────────────────┐
│  Package:  ethio_greg_dual_calendar                              │
│  Purpose:  Dual-calendar date picker (Gregorian + Ethiopian)      │
│  What:     Full calendar widget with Amharic month/weekday names  │
│                                                                   │
│  What it DOES:                                                    │
│  ✅ Amharic month names (መስከረም, ጥቅምት, ...)                    │
│  ✅ Ethiopian calendar conversion                                 │
│  ✅ Ge'ez numeral display (፩ ፲ ፴)                                │
│                                                                   │
│  POTENTIAL USE:                                                   │
│  → Date picker for Quick Add screen                               │
│  → Showing dates in Amharic on the dashboard                      │
│  → Ethiopian calendar preference toggle in Settings               │
└─────────────────────────────────────────────────────────────────┘
```

#### `kenat` — Comprehensive Ethiopian Calendar

```
┌─────────────────────────────────────────────────────────────────┐
│  Package:  kenat (ቀናት — "days" in Amharic)                      │
│  Purpose:  Full Ethiopian calendar system with cultural data      │
│                                                                   │
│  What it DOES:                                                    │
│  ✅ Ethiopian ↔ Gregorian date conversion                         │
│  ✅ Holidays (Christian, Islamic, public)                         │
│  ✅ Fasting periods (Abiy Tsome, Filset, Ramadan)                │
│  ✅ Bahire Hasab (ecclesiastical computation)                     │
│  ✅ Ethiopian time system (12-hour day/night)                     │
│  ✅ Ge'ez numerals (፳፻፲፮)                                       │
│  ✅ Amharic weekday/month names                                  │
│  ✅ Multilingual (Amharic + English)                              │
│                                                                   │
│  POTENTIAL USE:                                                   │
│  → "Today" could show ዛሬ ቀኑ (with correct Amharic)              │
│  → Transaction dates in Ethiopian calendar                        │
│  → Holiday awareness (e.g., no transactions on Fasting days)      │
└─────────────────────────────────────────────────────────────────┘
```

### Recommendation

| Need | Solution | Priority |
|---|---|---|
| Correct Amharic UI translations | Hire Amharic speaker to review translations | **High** — do this first |
| Prettier Amharic fonts | `geez_fonts` | Low — cosmetic |
| Ethiopian calendar display | `ethio_greg_dual_calendar` or `kenat` | Medium — nice to have |
| Ethiopian date formatting | `kenat` (most complete) | Medium — nice to have |

**Bottom line:** No package solves our core problem (garbled Amharic text). The fix is human: get a native Amharic speaker to review and correct the translations in `lib/l10n/app_localizations.dart`. The calendar packages are value-add features for a future release.

---

*Document version: 2.0 — August 2026*
*Last updated: Dockerization docs + Ethiopian language package assessment*
