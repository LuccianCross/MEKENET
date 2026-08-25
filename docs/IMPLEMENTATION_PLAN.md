# Implementation Plan: Mekenet MVP
 
## Quick glossary (read this first if some of the terms below are new)
- **Repository / repository interface:** a simple set of functions like "save a transaction" or "get transactions from this week" that the app screens use, instead of talking to the database directly.
- **Mock repository:** a fake, pretend version of the above, used temporarily so the app screens can be built before the real database is finished.
- **Pure function:** a small piece of code that only does one simple thing — you give it something, it gives something back, nothing else happens. Our SMS reader is written this way: you give it a text message, it gives you back a transaction (or "I don't know").
- **Migration (database):** a saved record of changes to how data is organized, so the app can update its storage structure safely later without losing data.
- **Encryption:** scrambling the data so it can't be read without a secret key — protects the shop owner's real numbers if the phone is lost or the file is somehow accessed.
- **Unit test / widget test / integration test:** small automatic checks that confirm a piece of code works correctly, run by the computer instead of a person clicking through the app by hand every time.
- **API / endpoint:** a specific "address" the app can send a request to on the backend, like `/sync` or `/export`, to get something done or get data back.
- **Virtual environment (Python):** an isolated space for a Python project's installed packages, so different projects on the same computer don't interfere with each other.
This document breaks the MVP into phases by layer — database, backend, frontend — so it's easy to follow regardless of which part you're working on. Note: layers are documented in this order for clarity, but per the README's 8-day build order, database and parser work actually start in parallel on day 1, not strictly one after another. Check the README for the day-by-day calendar; check this document for the actual steps within each layer.
 
---
 
## Phase 1: Database Design (Storage/sync dev)
 
1. **Finalize the schema.** Use the data model in `SDD.md` as the source of truth: `Transaction`, `Item`, `PriceMatchRule`, `Debt`, `ShopProfile`. Don't add fields that aren't in the SDD without updating it first — the SDD is what the rest of the team is building against.
2. **Define repository interfaces before writing the real implementation.** e.g. `TransactionRepository` with methods like `save()`, `getByDateRange()`. Publish these on day 1 so the frontend dev can build against a mock version immediately, instead of waiting on the real SQLite layer.
3. **Verify `sqflite_sqlcipher` actually works in your setup, day 1, before committing to it.** If it's flaky, fall back to application-level field encryption rather than losing a day mid-week to a dependency problem.
4. **Set up local storage.** Add `sqflite` and `sqflite_sqlcipher` to the Flutter project. Create the database file with encryption enabled from the start, with the encryption key stored via `flutter_secure_storage` — never hardcoded.
5. **Write migrations.** Even for an 8-day MVP, use a versioned migration (not a single hardcoded `CREATE TABLE`), since the schema will change at least once as the team finds edge cases.
6. **Write CRUD functions.** One simple function per operation you actually need (insert transaction, get transactions by date range, update a `PriceMatchRule`'s confidence, etc.) — not a generic ORM-style abstraction layer. Simple and direct beats "flexible" here.
7. **Unit test this layer first.** Before anyone else builds on top of it: insert a transaction, read it back, confirm encryption is actually active (the raw `.db` file should be unreadable without the key). This is the foundation everyone else depends on — bugs here cost the whole team time later.
**Done when:** another teammate can call your CRUD functions and get correct data back, without needing to understand how the database works internally.
 
---
 
## Phase 2: Backend (lead + backend teammate, staged for days 6–8)
 
1. **Set up the Python project.** A virtual environment, `fastapi`, `uvicorn` (runs the server), and a Postgres driver — see `PROJECT_SETUP.md` for exact commands. Get the default `/health` endpoint running and visible at `/docs` before building anything real — that's your proof the setup works.
2. **Set up Postgres and create the transactions table**, mirroring the structured (non-raw) fields from the local schema in `SDD.md`. Keep the connection string in a `.env` file, never committed to the repo.
3. **Keep auth minimal.** For a pilot, a simple per-device identifier is enough — don't build a full user account system for an 8-day MVP.
4. **Keep sync dead simple.** The pilot is one phone per shop owner, syncing on explicit request — you don't have a multi-device conflict problem yet, so don't build for one. Dedup using the transaction's own id and `raw_sms_hash`, which you already have. MVP is append-only: edits stay local, deletes are a soft flag, nothing more elaborate than that.
5. **Write a one-page privacy spec.** State plainly: parsing happens on-device, raw SMS never leaves the phone, only structured fields sync, and only when the user taps export. This becomes both an internal reference and demo material.
6. **Build the `/sync` endpoint**, accepting structured transaction data only, writing it to Postgres.
7. **Build the `/export` endpoint.** Turns synced data into a simple, readable report (PDF or shareable text) — this is the one feature real users (loan officers) will actually look at, so it's worth an extra pass on formatting.
8. **Test using FastAPI's `/docs` page directly** — you can send real requests to your own endpoints from the browser without writing a separate testing tool. Given the scope, that plus one or two automated tests covering "does a sync actually write correctly" is enough — don't over-invest in test infrastructure for a backend this small.
**Done when:** a teammate can trigger sync from the app, see the data land correctly in Postgres, and get a real, readable export back from `/export` — and you can point to the privacy spec to show exactly what did and didn't leave the device.
 
---
 
## Phase 3: Frontend (Frontend dev + Core engine dev)
 
1. **SMS permission and listening.** Add the `telephony` package, handle the Android permission request flow, confirm you can see raw incoming SMS text in a debug log before building anything on top of it.
2. **Parser logic, as a pure function.** Signature: `SMS text → ParsedTransaction?` — no side effects, no I/O. The SMS listener is a thin separate layer that just calls this. Build it against a small hand-collected sample of real messages from day one — don't guess at the format from memory. When ambiguous, return `unknown` rather than a confident wrong guess — a wrong number silently breaks trust in the whole app; an "unknown" just prompts one tap.
3. **Parser corpus & maintenance.** Store anonymized real SMS samples in a `test_assets/` folder as a 30–50 message golden test corpus. Run the parser test suite on every change, tracking four numbers: classification accuracy, field extraction accuracy, unknown-format rate, and false-positive rate. Add an in-app "Fix this SMS" flow alongside the manual "+" button, so the app stays usable the moment parsing fails on something new.
4. **Matcher/learning logic.** Implement the price-match lookup and the confidence-scoring update on each user tap, per the flow in `SDD.md` section 4.
5. **Trust-first onboarding.** First-run screens should be plain-language, not technical: explain the SMS permission in one sentence before asking for it, state "we never share your data" explicitly, walk through PIN setup, and make the backup/export toggle visibly opt-in rather than buried in settings. This isn't polish — it's the answer to the trust problem the whole PRD is built around.
6. **Core screens.** Home/profit view, quick-tap picker, manual expense add, debt list, PIN lock — build against the CRUD functions from Phase 1, not directly against the database.
7. **Wire it together and test on a real device early.** An emulator won't reliably receive real SMS — get this running on an actual Android phone as early as day 3–4, not day 8.
**Done when:** a real SMS on a real phone turns into a correct transaction and shows up in the profit view, with zero manual typing for a matched sale.
 
---
 
## Testing Strategy (written for a team new to testing)
 
Think of testing as a pyramid, not a single thing you do at the end:
 
- **Most of your tests should be small, fast unit tests** — testing one function in isolation, like "does this specific SMS text produce the right amount and direction." These catch the most bugs for the least effort, and you should write them as you finish each risky piece, not save them for the end.
- **A smaller number of widget tests** — testing that a screen renders and responds correctly (e.g., tapping a quick-tap chip actually saves the right item). Flutter's `flutter_test` package handles both unit and widget tests out of the box.
- **A handful of integration tests** — full flows, like "SMS in, transaction saved, profit updated," using the `integration_test` package on a real or emulated device. These are slower and more brittle, so you only need a few, covering the core loop.
- **Manual, real-device testing throughout** — no amount of automated testing replaces actually running the app on a real phone with real SMS. This is not a lesser form of testing; for this app specifically, it's the most important kind, since SMS behavior varies by device and Android version.
**Practical setup for your 8 days:**
- Folder structure: `test/unit/`, `test/widget/`, `integration_test/`.
- Use `mocktail` to fake the SMS receiver and database in unit tests, so you're testing your logic, not waiting on a real phone every time.
- Priority order given limited time: parser and matcher logic first (highest risk, most reused, cheapest to test), then the CRUD layer, then a couple of widget tests on the quick-tap picker, then one integration test for the full core loop. Skip heavy CI/CD setup or a large end-to-end suite — not worth the time investment for an 8-day pilot.
- **Concrete acceptance targets:** parser accuracy ≥90% against your real SMS corpus, unknown-format rate under 5%. Report the actual number either way — a specific, honest miss is more credible than a vague claim of success. The core-loop integration test ("SMS in → transaction saved → profit updated") should pass on at least 2 different Android phones, since SMS handling varies by device and Android version.
- Don't aim for full TDD (writing tests before code) if the team hasn't done it before — that's a real skill that takes practice. Instead: write the test right after you finish the risky piece of logic, while it's fresh, before moving to the next thing.
---
 
## Phase 4: Integration, Testing & Demo Prep (Full team, days 6–8)
 
1. Run the full team through the four live demo proof points from the PRD: live learning, offline mode, privacy proof (include showing the exact fields that sync, per the privacy spec), honest accuracy number.
2. Run the parser against your real 30–50 message SMS corpus and record the actual accuracy — this becomes both a test result and a demo talking point.
3. **Instrument basic events** (install, SMS parsed, correction tapped, report viewed) — without this, you can't actually verify the PRD's pilot success criteria later, you'd just be guessing.
4. **Validate export requirements with a real loan officer or microfinance contact before building the final format**, not after — a short conversation or rough mockup about what they'd actually want to see, timed before Phase 2's export function is built, saves you from formatting the wrong thing well.
5. Focused bug bash: 2–3 hours, not a full day, triaged by severity — fix critical/high issues first, log the rest rather than chasing everything.
6. Rehearse the demo end-to-end at least twice before presenting.
