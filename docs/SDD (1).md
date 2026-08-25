# SDD: መቀነት (Mekenet)
 
## 1. Architecture Overview
Offline-first, on-device architecture. The core loop — reading an SMS, extracting a transaction, updating profit — never depends on network access. A separate backend service exists only to sync structured data (never raw SMS) when the user explicitly opts in, mainly to enable bank-ready export. **The app is local-first, full stop: Flutter + encrypted SQLite is the product. The backend is an add-on for explicit sync/export, never a dependency of the core experience, and it's a custom service we build and own — Python + FastAPI, not a managed backend-as-a-service.**
 
**Domain/model layer.** The UI never talks to SQLite directly. Models (`ParsedTransaction`, `Transaction`, `Debt`, `PriceMatchRule`) sit behind repositories/services that the UI calls instead. This isn't just clean architecture — it's what lets the frontend and storage devs work in parallel: define the repository interfaces on day 1, and the frontend can build against a mock repository while the real SQLite-backed one is still being built underneath it.
 
**Parser as a pure function.** The parser has the signature `SMS text → ParsedTransaction?` — no side effects, no I/O, nothing but text in, a typed result (or null/unknown) out. The SMS listener is a separate, thin layer that just hands text to this function. Keeping it pure is what makes it trivially unit-testable against a corpus of real messages, and it's why the matcher stays deterministic — rules plus confidence scoring, no ML/AI in the MVP. Ambiguity should always resolve to "unknown, ask the user," never to a confident but wrong guess — a wrong number silently corrupts trust in the whole app, an "unknown" just prompts a tap.
 
**Platform decision:** Android only, built in **Flutter**. The team's real fluency is in Flutter, not native Kotlin — SMS access is still fully achievable via the `telephony` package, which wraps Android's native broadcast receiver in plain Dart, so no one has to learn a new language under an 8-day deadline. iOS is out of scope anyway, since Apple restricts SMS reading almost entirely — this isn't a workaround, it's just how the platform works.
 
## 2. Components
 
| Component | Responsibility | Owner |
|---|---|---|
| SMS Listener | `telephony` package (Flutter/Dart) listens for incoming SMS, hands raw text to the parser | Core engine dev |
| Parser + Matcher | Extracts direction/amount/counterparty; guesses item via the price-match table; flags unmatched for quick-tap | Core engine dev |
| Local Database | Encrypted `sqflite` (+ `sqflite_sqlcipher`); source of truth; app works fully offline against this | Storage/sync dev |
| Mobile UI | Quick-tap picker, profit views, manual expense/debt entry, PIN lock — Flutter | Frontend dev |
| Backend API (Python + FastAPI) | Structured-data sync endpoint, report/export generation — **staged for days 7–8, not built in parallel** | You + backend teammate |
| Backend Database (Postgres) | Stores synced structured transaction data only, never raw SMS | You + backend teammate |
 
## 3. Data Model
 
**Transaction**
```
id: uuid
direction: "income" | "expense"
amount: decimal
source: "sms" | "manual"
raw_sms_hash: string        // hash only, never the raw text — used for de-duplication
counterparty_masked: string // last 4 digits only
item_id: uuid | null
match_confidence: "auto" | "confirmed" | "unmatched"
category: string | null     // for manual expenses: stock / rent / staff / other
timestamp: datetime
synced: boolean
```
 
**Item**
```
id: uuid
name: string
price: decimal
confirm_count: integer      // how many times a user has confirmed this match — drives auto-match confidence
```
 
**PriceMatchRule** (the "learning" table)
```
price: decimal
item_id: uuid
confidence_score: integer   // increments on confirmation, decrements on correction
```
 
**Debt** (manual only — no SMS trail for unpaid amounts)
```
id: uuid
customer_name: string
amount: decimal
status: "open" | "paid"
created_at: datetime
```
 
**ShopProfile**
```
id: uuid
shop_name: string
shop_type: string            // e.g. "kiosk_food" for the pilot's single starter category
pin_hash: string
```
 
## 4. Core Data Flow
1. SMS arrives → Receiver passes raw text to Parser (in-memory only).
2. Parser extracts direction, amount, counterparty; computes `raw_sms_hash` for de-dup; discards raw text.
3. Matcher checks `PriceMatchRule` for this amount:
   - Exact, unambiguous match → auto-save as `"auto"`.
   - Amount matches multiple items → save as pending, UI shows only the colliding items as quick-tap options.
   - Amount is a clean multiple of a known price → save as pending with a one-tap confirm suggestion.
   - No match → save as pending, unmatched, full quick-tap list shown.
4. Transaction written to encrypted local DB. UI updates instantly (no network round-trip).
5. Any user tap (confirm/correct) updates `PriceMatchRule.confidence_score`.
6. Sync to our backend API happens only on explicit user action (e.g. "prepare export"), sending structured transaction data — never raw SMS — to a FastAPI endpoint we built ourselves, backed by Postgres.
## 5. Security & Privacy Design
- Raw SMS text is never persisted or transmitted — only extracted fields and a hash.
- Local database is encrypted at rest (`sqflite_sqlcipher`) — **verify this package actually works cleanly in your Flutter setup on day 1**, before anything else depends on it, and have a fallback (e.g. application-level field encryption) ready if it doesn't.
- The encryption key itself lives in secure OS-backed storage (`flutter_secure_storage`, backed by Android Keystore) — never hardcoded in source.
- App is protected by a PIN, set on first launch.
- Cloud sync is opt-in per action, not a background default — this is a provable claim, not a marketing one, and should be demoed live (network monitor showing zero requests during parsing).
## 6. Non-Functional Requirements
- Must run acceptably on low-end Android devices common in the target market (avoid heavy frameworks/animations).
- Core loop (SMS → transaction → profit view) must have zero network dependency.
- Parser must degrade gracefully on an unrecognized SMS format — log it, don't crash, fall back to the manual "+" entry.
## 7. Open Decisions (resolve before Day 2)
- Exact telebirr SMS format samples to build the parser's initial pattern set against (owned by: core engine dev, sourced by: lead's pilot outreach).
- Starter item list for the single pilot vertical (kiosk/food) — 10–15 items, owned by: lead + frontend dev.
- Confidence threshold at which a `PriceMatchRule` is trusted enough to auto-save without any confirm tap.
## 8. Folder Structure
This is the architecture from sections 1–2, made physical — so anyone opening a branch knows exactly where their work belongs. The project is a monorepo with two top-level parts: the Flutter app and the Python backend, kept separate since they're different languages and different concerns.
 
```
mekenet/
  app/                     ← the Flutter project
    lib/
      models/              → Transaction, Debt, Item, PriceMatchRule, ParsedTransaction
                             (shared by everyone — changes here need team agreement first)
      repositories/        → TransactionRepository, DebtRepository — interfaces + real
                             SQLite implementation + a mock version for early frontend work
                             (owner: storage/sync dev)
      services/
        parser/            → the pure SMS-parsing function, isolated and heavily tested
        matcher/           → price-match lookup + confidence-score learning logic
                             (owner: core engine dev)
      screens/             → each app screen — home, quick-tap picker, debts, onboarding
      widgets/             → small reusable pieces (quick-tap chip, PIN pad, etc.)
                             (owner: frontend dev)
      api_client/          → thin HTTP client that calls our backend — no logic, just requests
      utils/                → encryption helpers, formatting helpers (shared)
    test/
      unit/                → fast tests, mainly parser, matcher, and repository logic
      widget/              → screen-level tests
    integration_test/      → full-flow tests (SMS in → transaction saved → profit shown)
    test_assets/           → the real, anonymized SMS sample corpus
 
  server/                  ← the Python + FastAPI backend
    routes/                → API endpoints (sync transactions, generate export/report)
    models/                → Pydantic data models mirroring the app's Transaction shape
    db/                    → Postgres connection + queries
    tests/                 → backend tests
    (owner: you + backend teammate)
 
  README.md, PRD.md, SDD.md, and other docs at the repo root
```
 
**The one rule that matters most:** if you're touching `app/lib/models/`, say so in the daily check-in before you do — it's the one folder everyone else's code depends on, and an unannounced change here is the fastest way to break someone else's branch without meaning to.