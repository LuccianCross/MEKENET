# መቀነት (Mekenet) — Hold Your Money Together

<p align="center">
  <em>Turns a shop owner's mobile-money SMS into a daily money record — automatically.</em>
</p>

---

## About

**Mekenet** (Amharic for *"woven cloth"* — the fabric that holds things together) is an offline-first Android app that gives small business owners in Ethiopia a clear, daily picture of their money without manual bookkeeping.

Small traders in Addis Ababa get paid through **telebirr, CBE Birr, Awash**, and cash — but they can't quickly see their real profit or who owes them. That leads to poor restocking decisions and trouble getting loans, since lenders want clean records. Mekenet solves this by reading bank SMS notifications on the phone and turning them into structured transactions automatically.

**Design principle: trust first.** Records stay on the device by default, nothing leaves the phone without explicit consent, and exports are always user-initiated — never automatic.

## Features

- **Automatic SMS parsing** — multi-bank parsers (telebirr, CBE, Awash) convert payment SMS into structured transactions in real time. No manual data entry for the core flow.
- **User-controlled history import** — on first launch, the user chooses whether to import past transactions from their inbox (with progress UI) or only track new messages. Changeable anytime in Settings.
- **Offline-first daily money record** — everything works with no internet; cloud sync is opt-in and retry-safe.
- **Plain-language insights** — today/week/month income and expenses, 7-day trends, and income breakdown by category.
- **"Who owes me" ledger** — a deliberately manual debt tracker, since unpaid debts don't generate an SMS.
- **Quick manual entry** — fast expense/income add with learned category suggestions.
- **Bank-ready export** — user-initiated CSV/report generation for loan applications ("send report to bank").
- **Privacy protection** — PIN lock with salted hashing + lockout, no cloud backup of local data, encrypted-preference storage for sensitive values.
- **Amharic & English** — full localization with Geez typography.

## Architecture

```
┌─────────────────────────┐         HTTPS          ┌──────────────────────┐
│  mekenet_mobile (Flutter)│  ─── opt-in sync ───▶  │  server (FastAPI)    │
│                         │                        │                      │
│  SMS listener ─▶ parser │                        │  /sync  /export      │
│        ▼                │                        │  API-key auth        │
│  SQLite (offline-first) │                        │  rate limiting       │
│        ▼                │                        │  Postgres            │
│  UI (home/debts/reports)│                        │  Docker              │
└─────────────────────────┘                        └──────────────────────┘
```

| Layer | Technology |
|---|---|
| Mobile app | Flutter (Dart), Android |
| Local storage | SQLite (offline-first repository pattern) |
| SMS ingestion | Android `RECEIVE_SMS` via `another_telephony` |
| Backend | Python · FastAPI · SQLAlchemy |
| Database | PostgreSQL (server), SQLite (device) |
| Auth | Per-device API key (`X-API-Key`) with constant-time comparison |
| Deployment | Docker + docker-compose |

### Project structure

```
INSA_final_project/
├── mekenet_mobile/          # Flutter mobile app
│   ├── lib/
│   │   ├── screens/         # home, quick add, debts, settings, PIN, onboarding
│   │   ├── services/
│   │   │   ├── parser/      # telebirr / CBE / Awash SMS parsers (+ bank identification)
│   │   │   └── sms/         # SMS listener, consent-gated inbox import
│   │   ├── repositories/    # storage abstraction over SQLite
│   │   ├── api_client/      # thin backend client (sync/export)
│   │   ├── database/        # SQLite setup
│   │   └── widgets/         # shared UI components
│   └── test/                # 40 tests incl. real-SMS parser fixtures
├── server/                  # FastAPI backend
│   ├── routes/              # /sync, /export endpoints
│   ├── middleware/          # API-key auth, rate limiting
│   ├── models/              # transaction model shared shape
│   ├── db/                  # database session/engine
│   ├── tests/               # 32 backend tests
│   ├── Dockerfile
│   └── docker-compose.yml
└── docs/                    # PRD, SDD, architecture, implementation plan
```

## Getting started

### Prerequisites

- Flutter SDK (stable channel)
- An Android device or emulator (API 21+)
- Python 3.12+ with `venv` (backend only)

### Mobile app

```bash
cd mekenet_mobile
flutter pub get
flutter run
```

The app runs fully offline. On first launch you'll set up a PIN and choose whether to import your SMS history.

### Backend

```bash
cd server
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env            # then fill in DATABASE_URL and MEKENET_API_KEY
uvicorn main:app --reload
```

Interactive API docs are auto-generated at [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs).

### Docker

```bash
cd server
docker compose up --build
```

### Running tests

```bash
# mobile (40 tests)
cd mekenet_mobile && flutter test

# backend (32 tests)
cd server && python -m pytest -q
```

## Security & privacy

- **Local by default** — transactions live in on-device SQLite; cloud sync only happens if the user enables it.
- **Consent-gated inbox access** — reading SMS history requires an explicit one-tap choice; declining still enables live tracking.
- **PIN security** — salted SHA-256 hashing, stored in secure storage, with progressive lockout after repeated failures.
- **No silent uploads** — exports are user-initiated; there is no background transmission of financial data.
- **Hardened releases** — dedicated upload keystore, R8/minification, ProGuard rules, cloud backup disabled at the manifest level.

## Roadmap

- [ ] Deploy backend to production hosting behind HTTPS
- [ ] Configurable server URL flow for production builds
- [ ] Play Store distribution (requires Google's restricted SMS-permission process) or direct APK distribution
- [ ] Accuracy report against a larger real-world SMS corpus

> **Platform note:** iOS is not planned — Apple does not allow third-party apps to read SMS, which is the core input of the product.

## Team — Classroom R3004

| Name | CTC Number | Role |
|---|---|---|
| Lewi Kibru | CTC-6064-26 | Team lead · product, review, go-to-market |
| Lombame Lemma | CTC-888-26 | Core engine · SMS parser |
| Helen Tesfaye | CTC-1586-26 | Storage & sync |
| Mekdes Tesfaye | CTC-1711-26 | Frontend · mobile UI |
| Kenawak Berhanu | CTC-6591-26 | Backend & export |

## Contributing

This project was built as an eight-day team sprint — see [`docs/IMPLEMENTATION_PLAN.md`](docs/IMPLEMENTATION_PLAN.md) and [`docs/ARCHITECTURE.MD`](docs/ARCHITECTURE.MD) for design context, and [`TEAM_RULES.md`](TEAM_RULES.md) for the branch/PR workflow:

```bash
git checkout main && git pull origin main
git checkout -b feature/your-branch-name
# ... work, then:
git push origin feature/your-branch-name   # open a PR referencing the issue
```
