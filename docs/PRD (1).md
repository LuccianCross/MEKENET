# PRD: መቀነት (Mekenet) — hold your money together
*A daily money record for Addis Ababa small business owners*

## Problem
Owners get paid via telebirr, CBE Birr, cash and such but can't quickly see if they're actually profitable or who owes them. This causes bad restocking, overspending, and trouble getting loans, since lenders want clean records. Many also avoid "bookkeeping" tools out of fear that digital records draw tax attention.

## Who we're solving it for (pilot)
**Primary:** growth-oriented Addis merchants and service businesses (clinics, salons, repair shops, small importers) who already keep some records and want cleaner ones — for loans or their own control.
**Later:** banks/microfinance lenders who want better-documented borrowers.

## What we're building (MVP)
A mobile app that:
- Reads **telebirr** payment SMS on the phone and turns them into a daily money record — no manual entry for the core flow.
- Shows plain-language insight: "you made X birr this week."
- Lets the owner manually add the one thing SMS can't tell us: who owes them money (small, quick-tap add — not automatic, and we say so).
- Keeps data on-device by default. Sync/export is something the user chooses, not something that happens automatically.

## Why now / why us
No open banking API exists in Ethiopia, so this can't be a thin wrapper — the SMS-parsing and offline-first layer is real engineering, and that's the moat. Mobile money interoperability and a more open forex market are both only 1–2 years old, so the conditions for this to matter have only just appeared. Nigeria's Kippa proves this model works at scale — we're late to the pattern, not proving new ground.

## Pilot success criteria (30 days)
- 30 installs, 15 users active ≥3x/week
- 10 users with 2+ consecutive weeks of SMS-based logging
- 5 users who can correctly state last week's income, unprompted
- 3 users who report the app changed a real decision, or used export-to-bank

## Eight-day MVP scope
**In:**
- Telebirr SMS parsing, both directions — money received (income) **and** money sent (automatic expense capture), no extra scope cost since it's the same engine.
- A self-learning item matcher: unmatched sales get a one-tap quick picker; confirmed taps teach the matcher, so repeat amounts auto-tag with zero taps next time.
- Manual "+ Expense" button for cash spending (amount + one-tap category) — the only manual money entry in the app.
- Manual "who owes me" list (the one deliberately manual feature, since unpaid debts leave no SMS trail).
- Offline-first daily/weekly/monthly profit view, syncing only when the user chooses.

**Out (explicitly deferred, not forgotten):**
- Full inventory tracking (per-item catalog, stock alerts). Kippa itself ships this as a separate, later feature, not bundled into core bookkeeping — we're following that same order.
- CBE Birr parsing (fast-follow after pilot).
- Forecasting model, LLM advice layer, lending features, voice input.

## Technical proof points (for the demo, not just the pitch deck)
Given the short build window, credibility comes from *showing* these live, not describing them:
- **Live learning:** an unmatched sale gets tap-confirmed once, then a second identical-amount sale auto-tags itself with zero taps — shown in the demo, not claimed in a slide.
- **Live offline proof:** airplane mode on, add a sale, see it save and calculate correctly, then reconnect and watch it sync.
- **Live privacy proof:** network monitor open during parsing, showing zero requests fire while an SMS becomes a transaction.
- **An honest accuracy number:** the parser run against 30–50 real collected telebirr SMS messages, reporting the real result and known failure modes — not a polished demo that never shows an edge case.
- **A small visible test suite** in the repo covering different SMS formats, signaling real engineering discipline to anyone reviewing the code, not just watching the demo.

## One revenue hypothesis to test, not four
We're testing **whether trusted transaction history is valuable enough for a lender to pay us for it** (the Kippa/Michu model) — not payments processing, which is a different, licensed business we're explicitly not building yet.

## Key risks
- **Trust/tax fear** → target already loan-seeking businesses first; make "we never share your data" provable, not just promised.
- **Zero existing distribution** → recruit through microfinance partners and service-business clusters, not cold general marketing.
- **SMS format changes** → keep a manual "+" add as permanent backup, not just an MVP crutch.

See `README.md` for team roles, architecture, and how work is tracked in GitHub Issues.
