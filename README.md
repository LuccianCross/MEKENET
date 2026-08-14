# Project Title
መቀነት (Mekenet) — hold your money together
 
## Short Description
A mobile app that turns a shop owner's mobile-money SMS into a daily money record, automatically — no manual bookkeeping required for the core flow.
 
## The Problem
Small business owners in Addis Ababa get paid via telebirr, CBE Birr, and cash, but can't quickly see their real profit or who owes them. This leads to bad restocking decisions, overspending, and trouble getting loans, since lenders want clean records. Many also avoid existing "bookkeeping" apps out of fear that digital records will draw tax attention — so the solution has to earn trust, not just track numbers.
 
## Main Features We Plan to Develop
- **Automatic SMS parsing** — reads telebirr payment notifications on the phone and converts them into structured transactions, with no manual data entry required.
- **Offline-first daily money record** — works with no internet connection, syncing to the cloud only when the user chooses.
- **Plain-language insights** — e.g. "you made X birr this week," without technical or financial jargon.
- **Manual "who owes me" list** — the one deliberately manual feature, since unpaid debts don't generate an SMS.
- **User-controlled export** — a "send report to bank" option for loan applications, never automatic.
## Team Info |Classroom Number: R3004
- **Full Name:** Lewi Kibru(leader)
- **CTC Number:** CTC-6064-26

*(add your info here)*
 
---
 
## Team & Ownership (project tracking)
 
| Area | Owner | GitHub label |
|---|---|---|
| Mobile app (UI) | Frontend dev | `mobile` |
| SMS parser (core engine) | Core engine dev | `parser` |
| Local storage / offline sync | Storage/sync dev | `storage` |
| Backend & export | Backend dev | `backend` |
| Review, Fix, Product, design & go-to-market | lead | `product` / `gtm` |
 
Every issue gets exactly one of these five labels, so it's always clear whose queue it's in.
 
## How We Track Work
- **Milestones:** `Week 1 — build the MVP`.
- **Issue naming:** `[label] short description` — e.g. `[parser] handle telebirr "received" SMS format`.
- **Every issue needs:** one owner, one milestone, and a done-condition in the description (what "closed" actually means).
- **Daily 10-minute check-in** (async in chat is fine): what you closed, what you're blocked on. Blockers get flagged same-day, not at the end of the week.
## Eight-Day Build Order
Cut down from two weeks to eight days — narrower scope, not more hands per hour. No CBE Birr, no inventory, no forecasting. The goal each day is something that visibly works, not something that's "mostly done."
 
1. **Days 1–2:** Storage schema + local record structure (storage dev) in parallel with SMS parser skeleton, both directions — income and expense (core engine dev). These two agree on a shared transaction data shape before either goes further — this is issue #1.
2. **Days 3–4:** Mobile UI wired to local storage (frontend dev); parser reaching real telebirr SMS samples, income and expense (core dev); lead collecting 30–50 real SMS samples from teammates/friends and recruiting first pilot users.
3. **Day 5:** The self-learning matcher (quick-tap picker + auto-tag on repeat amounts) and the manual "+ Expense" / "who owes me" UI (frontend + core dev together — this is the single most demo-impressive piece, worth a full day).
4. **Day 6:** Backend sync/export (backend dev); offline-mode hardening so the airplane-mode demo is real, not staged; lead running first real interviews/pilot walkthroughs.
5. **Day 7:** Run the parser against the real SMS corpus and report an honest accuracy number; write the visible test suite; fix whatever the real data breaks.
6. **Day 8:** Full team rehearsal of the live demo — learning, offline, and privacy proof points, back to back — plus final bug fixes.
## Scope Discipline
If it's not in the PRD's "In scope" list, it's a new issue tagged `icebox`, not something added mid-sprint. new ideas are welcome.