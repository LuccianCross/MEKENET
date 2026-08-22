# Mekenet - Technical Architecture

> Last updated: August 2026
> This document describes the actual implemented architecture of the Mekenet MVP.

---

## 1. System Overview

Mekenet is an offline-first financial tracker for Ethiopian SMEs. The core loop -- reading an SMS, extracting a transaction, updating profit -- **never depends on network access**. Cloud sync is an opt-in add-on controlled by the user.

```
FLUTTER MOBILE APP (Offline-first)
===================================

  SMS arrives
      |
      v
  Bank Identifier (sender-based, anti-phishing)
      |
      v
  Bank-specific Parser (Telebirr / CBE / Awash)
      |
      v
  ParsedBankSms {direction, amount, counterparty, balance, fee}
      |
      v
  Deduplication (SHA-256 hash of raw SMS body)
      |
      v
  Auto-categorization (learned counterparty+direction -> category)
      |
      v
  Encrypted SQLite (SQLCipher) -- source of truth
      |
      v
  UI updates live via broadcast stream
      |
      v
  Sync to backend (only if sync toggle ON)

User flows:
  Quick Add  ->  Manual income/expense  ->  Same save pipeline
  Debts      ->  Manual debt tracking   ->  Debt repository (no SMS)
  Settings   ->  Categories, Language, PIN, Sync, Export
```

```
FASTAPI BACKEND (Python)
========================

  POST /sync/   ->  Receives structured transactions from app
  GET  /export/ ->  Generates bank-ready reports with date/type filters
  GET  /health  ->  DB connectivity check
      |
      v
  PostgreSQL (Neon cloud)
```

---

## 2. Key Architectural Decisions

### 2.1 Offline-First, Not Offline-Capable

Every feature works against the local encrypted SQLite database with zero network calls:

- SMS parsing and transaction logging
- Profit/expense/income calculation (day, week, month)
- Income-by-category breakdown
- Debt tracking (owed-to-me / I-owe)
- Category management (add/remove defaults and custom categories for both income and expense)
- CSV export and share
- Report generation (local fallback when backend is unreachable)

Cloud sync is a toggle in Settings. When enabled, each new transaction is POSTed to the backend. When disabled, the app is fully air-gapped.

### 2.2 Parser as a Pure Function

Each bank parser has the signature `String smsText -> ParsedBankSms?`:

- No side effects, no I/O, no database access
- Returns null for non-matching messages (graceful degradation)
- Unit-testable against 38+ real anonymized SMS samples across 3 banks
- The SMS listener is a separate thin orchestration layer that only hands text to the parser and acts on the result
- Bank identification is also separate (`bank_identifier.dart`) -- matches sender IDs from `assets/sms_patterns.json` and uses body keywords to disambiguate shared shortcodes

### 2.3 Repository Pattern

```
  UI Screen  ->  Repository Interface (abstract class)
                      |
                 SQLite Implementation (concrete class)
                      |
                 DatabaseHelper (encrypted SQLite singleton)
```

- UI never touches SQLite directly
- Abstract interfaces (`TransactionRepository`, `DebtRepository`) define the contract
- `RepositoryProvider` is a service locator that lazily instantiates SQLite repos as singletons
- Tests inject mock repositories via `useTransactionMock()` / `useDebtMock()`
- This separation allowed frontend and storage work to happen in parallel during development

### 2.4 Direction-Aware Category Learning

The auto-categorization system learns per-counterparty AND per-direction:

- Income from "Amina" learns "Sales" (most frequent income category for that counterparty)
- Expense to "Amina" learns "Transport" (most frequent expense category for that counterparty)
- No cross-contamination between income and expense labels
- Income defaults to "Sales"; expense defaults to "other"
- The `getCategoryByCounterparty()` SQL query filters by `direction` column

### 2.5 Encrypted Storage

- Database encrypted at rest via SQLCipher (`sqflite_sqlcipher`)
- 256-bit encryption key generated once, stored in Android Keystore via `flutter_secure_storage`
- PIN stored as SHA-256 hash, never in plaintext
- Raw SMS text is never persisted -- only extracted fields and a SHA-256 hash (for deduplication)

---

## 3. Project Structure

```
INSA_final_project/
  mekenet_mobile/                     # Flutter mobile app
    lib/
      main.dart                       # Entry point, StartupScreen, MainScreen (IndexedStack)
      l10n/
        app_localizations.dart        # Hand-rolled en/am translations (~50 keys each)
      models/
        transaction.dart              # Core Transaction model (toMap/fromMap)
        debt.dart                     # Debt model (owed_to_me / i_owe types)
        export_report.dart            # Export report (local buildLocal + backend mirror)
        sync_response.dart            # Backend sync response mirror
      database/
        database_helper.dart          # SQLCipher-encrypted SQLite singleton, schema, migrations
      repositories/
        transaction_repository.dart   # Abstract interface
        sqlite_transaction_repository.dart  # SQLCipher implementation (~318 lines)
        debt_repository.dart          # Abstract interface
        sqlite_debt_repository.dart   # SQLCipher implementation
        repository_provider.dart      # Service locator + test mock hooks
      services/
        category_service.dart         # Income/expense categories, usage tracking, smart pre-fill
        sync_service.dart             # Opt-in cloud sync orchestrator (syncOne, retryUnsynced)
        parser/
          bank_identifier.dart        # Sender-based bank detection (anti-phishing)
          telebirr_sms_parser.dart    # Telebirr parser (most thorough, handles typos)
          cbe_sms_parser.dart         # CBE parser (3 distinct SMS templates)
          awash_sms_parser.dart       # Awash Bank parser
          parsed_bank_sms.dart        # ParsedBankSms value object + TransactionDirection enum
          failed_parse_log.dart       # Failed parse logging model + DAO
        sms/
          sms_listener.dart           # Core SMS ingestion pipeline (foreground + background)
      screens/
        onboarding_screen.dart        # 4-page wizard: language, intro, SMS permission, privacy
        pin_screen.dart               # PIN setup/verification (SHA-256 hashed, lockout)
        home_screen.dart              # Dashboard: profit card, summary, chart, categories
        quick_add_screen.dart         # Manual income/expense entry with toggle
        debts_screen.dart             # Debt tracking (owed-to-me / I-owe tabs)
        settings_screen.dart          # Config hub (~1400 lines): sync, export, categories, etc.
      widgets/
        bottom_nav_bar.dart           # 4-tab bottom navigation bar
      api_client/
        mekenet_api_client.dart       # Thin HTTP client for FastAPI backend
    test/                             # 40 unit/widget tests
    test_assets/                      # Real anonymized SMS samples (Telebirr, CBE, Awash)
    assets/images/
      logo.jpg                        # App logo (launcher icon + in-app branding)
    assets/sms_patterns.json          # Bank sender IDs and keywords for identification

  server/                             # Python + FastAPI backend
    main.py                           # FastAPI app factory + CORS + /health endpoint
    routes/                           # /sync and /export endpoints
    models/                           # Pydantic data models
    db/                               # SQLAlchemy + Postgres connection
    tests/                            # Backend tests
    Dockerfile                        # Multi-stage Python 3.12 build
    docker-compose.yml                # Single-service deployment config
```

---

## 4. Data Model

### Transaction (primary entity)

| Field | Type | Description |
|-------|------|-------------|
| id | TEXT (UUID) | Primary key, generated via `uuid` package |
| direction | TEXT | `'income'` or `'expense'` |
| amount | REAL | Decimal amount in Ethiopian Birr (ETB) |
| source | TEXT | `'telebirr'`, `'cbe'`, `'awash'`, or `'manual'` |
| raw_sms_hash | TEXT | SHA-256 hash of raw SMS body (deduplication key; raw text is never stored) |
| counterparty_masked | TEXT | Extracted counterparty name or bank name as fallback |
| item_id | TEXT | Reserved for future inventory item linking |
| match_confidence | TEXT | `'auto'`, `'confirmed'`, or `'unmatched'` (default) |
| category | TEXT | User-selected or auto-learned category (e.g. "Sales", "Inventory") |
| timestamp | INTEGER | Epoch milliseconds |
| synced | INTEGER | 0 = local only, 1 = synced to backend |

Indexes on: `timestamp`, `synced`, `raw_sms_hash`.

### Debt

| Field | Type | Description |
|-------|------|-------------|
| id | TEXT (UUID) | Primary key |
| customer_name | TEXT | Who owes / is owed |
| amount | REAL | Amount in ETB |
| status | TEXT | `'open'` or `'paid'` |
| type | TEXT | `'owed_to_me'` or `'i_owe'` (added in v2 migration) |
| created_at | INTEGER | Epoch milliseconds |

### FailedParseLog

| Field | Type | Description |
|-------|------|-------------|
| id | TEXT (UUID) | Primary key |
| sms_body_hash | TEXT | SHA-256 of the unparseable SMS |
| reason_code | TEXT | `'no_bank_match'` or `'parse_error'` |
| raw_sender | TEXT | Sender ID that was matched (or null) |
| timestamp | INTEGER | Epoch milliseconds |

---

## 5. Core Data Flows

### 5.1 Automatic SMS Processing

```
1. SMS arrives -> Android broadcasts to onBackgroundMessage()
2. Bank identification: normalize sender (+251 stripping), match against
   assets/sms_patterns.json sender IDs. Reject unknown senders (anti-phishing).
   Disambiguate shared shortcodes (e.g. 8047) using body keywords.
3. Route to correct parser based on bank name.
4. Parser extracts: direction, amount, counterparty, timestamp, balance, fees.
   Returns null if message is not a transaction.
5. Compute SHA-256 hash of raw SMS body.
6. Check database: existsBySmsHash() -> skip if duplicate.
7. Direction: 'received' -> 'income', 'sent' -> 'expense'.
8. Counterparty: use parser-extracted name, fallback to bank name.
9. Auto-categorize: getCategoryByCounterparty(counterparty, direction: direction).
   Falls back to 'Sales' for income, 'other' for expense.
10. Save Transaction to encrypted SQLite.
11. Notify UI via SmsListener.transactionStream broadcast.
12. If sync enabled: SyncService.syncOne(transaction) -> POST to backend.
13. On startup: back-fill inbox using sms_last_processed_ms watermark.
```

### 5.2 Manual Transaction Entry (Quick Add)

```
1. User opens Quick Add tab.
2. Toggles between Income and Expense.
3. Direction-specific category chips load (income or expense categories).
4. Most-used category for that direction is pre-selected.
5. User enters amount, optional note, and date.
6. Transaction saved locally -> syncOne() -> snackbar confirmation.
```

### 5.3 Category Learning

```
1. When a transaction is saved with a category, recordUsage(category, direction)
   increments a direction-prefixed counter in SharedPreferences.
2. When a new SMS arrives for a known counterparty:
   - getCategoryByCounterparty(name, direction: 'income') queries:
     SELECT category, COUNT(*) FROM transactions
     WHERE counterparty_masked = ? AND direction = ?
     AND category IS NOT NULL AND category NOT IN ('other','uncategorized')
     GROUP BY category ORDER BY cnt DESC LIMIT 1
   - If found, use that category. Otherwise fall back to direction default.
3. getMostUsedCategory(direction) returns the most-used category for smart
   pre-filling in the Quick Add screen.
```

---

## 6. SMS Parser Design

### Supported Banks

| Bank | Parser File | Test Cases | Features |
|------|------------|------------|----------|
| Telebirr | telebirr_sms_parser.dart | 10 samples + non-transaction | Amount, direction, counterparty, timestamp, balance, fee, VAT |
| CBE | cbe_sms_parser.dart | 11 samples + non-transaction | Amount, direction, timestamp, balance (3 distinct SMS templates) |
| Awash | awash_sms_parser.dart | 5 samples + non-transaction | Amount, direction, timestamp, balance |

### Parser Contract

```dart
// Input: raw SMS text (String)
// Output: ParsedBankSms? (null = not a transaction or unrecognizable)
ParsedBankSms? parseTelebirrSms(String sms);
ParsedBankSms? parseCbeSms(String sms);
ParsedBankSms? parseAwashSms(String sms);
```

### ParsedBankSms Value Object

```dart
class ParsedBankSms {
  String bankName;           // 'telebirr' | 'cbe' | 'awash'
  TransactionDirection direction;  // sent | received
  double amount;
  DateTime? timestamp;
  double? balanceAfter;
  String? transactionId;
  String? counterparty;      // extracted name (Telebirr only currently)
  double? serviceFee;
  double? vat;
}
```

### Bank Identification Anti-Phishing

The `bank_identifier.dart` module rejects SMS from unknown senders rather than guessing. It:
1. Normalizes the sender (strips +251 prefix)
2. Matches against known sender IDs in `assets/sms_patterns.json`
3. Uses body keywords to disambiguate shared shortcodes (e.g., 8047 is used by multiple banks)
4. Returns `null` for unrecognized senders, which causes the SMS to be skipped and logged to `failed_parses`

---

## 7. Security & Privacy

| Concern | Implementation |
|---------|---------------|
| Database encryption | SQLCipher (`sqflite_sqlcipher`) encrypts all data at rest |
| Encryption key storage | 256-bit key in Android Keystore via `flutter_secure_storage` |
| PIN storage | SHA-256 hash in secure storage, never plaintext |
| Raw SMS handling | Never persisted or transmitted; only extracted fields + SHA-256 hash retained |
| Data transmission | Only structured transaction data sent (never raw SMS), only when sync toggle is ON |
| Anti-phishing | Unknown senders rejected; only recognized bank sender IDs processed |
| Network monitoring | Sync can be verified by observing zero HTTP requests when toggle is OFF |

---

## 8. Localization

Hand-rolled localization (no codegen dependency):

- **English** (`en`): Full translation set (~50 keys)
- **Amharic** (`am`): Full translation set (~50 keys)
- Language chosen during onboarding, changeable in Settings
- Stored in SharedPreferences as `app_language`
- Applied at runtime via `MyMekenet.setLocale()` which rebuilds MaterialApp

---

## 9. Testing

40 tests across 4 test suites:

| Suite | File | Tests | What It Covers |
|-------|------|-------|----------------|
| Localization | localization_test.dart | 5 | EN/AM translations, fallback behavior, delegate support |
| Debt Model | debt_test.dart | 5 | Serialization, deserialization, backward compatibility, UUID generation |
| Telebirr Parser | telebirr_sms_parser_test.dart | 12 | All 10 real samples + non-transaction rejection |
| CBE Parser | cbe_sms_parser_test.dart | 12 | All 11 real samples + non-transaction rejection |
| Awash Parser | awash_sms_parser_test.dart | 5 | All 5 real samples + non-transaction rejection |
| Widget | widget_test.dart | 1 | Test harness validation |

Test assets are real, anonymized SMS samples stored in `test_assets/`.

---

## 10. Tech Stack Summary

| Layer | Technology | Why |
|-------|-----------|-----|
| Mobile framework | Flutter (Dart) | Team fluency; Android SMS access via `another_telephony` |
| On-device database | SQLite + SQLCipher | Encrypted, reliable, well-supported on Android |
| Secure storage | `flutter_secure_storage` | Backed by Android Keystore |
| HTTP client | `http` package | Simple, no heavy dependencies |
| Backend framework | Python + FastAPI | Self-built API with auto-generated docs |
| Backend database | PostgreSQL (Neon) | Managed Postgres for sync/backup |
| Containerization | Docker + docker-compose | Reproducible backend deployment |
| State management | setState + streams | Lightweight; sufficient for MVP scope |
| Localization | Hand-rolled | No codegen dependency; full control |
