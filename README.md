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
- **Full Name:** Lombame Lemma
- **CTC Number:** CTC-888-26
- **Full Name:** Helen Tesfaye
- **CTC Number:** CTC-1586-26
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
 
1. **Day 1:** Repository interfaces + SQLite skeleton defined (storage dev) — this is issue #1, since frontend builds against a mock of it starting day 2. Verify `sqflite_sqlcipher` actually works before committing to it. Parser work starts collecting real telebirr SMS samples (core dev + lead).
2. **Day 2:** Parser as a pure function, built and unit-tested against real samples; SMS listener wired up (core dev). Lead recruiting pilot users and gathering more real SMS.
3. **Day 3: prove the core loop end-to-end on a real device** — real SMS → parser → transaction → saved to SQLite. This is the single most important milestone in the whole build; everything after this is refinement, not risk.
4. **Day 4:** Real local database wired in (replacing the frontend's mock repository); matcher/learning logic; manual expense add.
5. **Day 5:** Core UI — profit view, quick-tap picker, "who owes me," trust-first onboarding (plain-language permission explanation, PIN setup, explicit backup/export toggle).
6. **Day 6:** Full integration + offline-mode testing (this needs to be real, not staged, since it's a live demo point); short conversation with a loan officer or microfinance contact about what they'd actually want in an export, before it's built.
7. **Day 7:** Supabase sync + export, built around what was learned on day 6; privacy proof prepared (exact synced fields documented, network monitor check).
8. **Day 8:** Accuracy measurement against the full SMS corpus (report the honest number); focused 2–3 hour bug bash, triaged by severity; full demo rehearsal.
## Scope Discipline
If it's not in the PRD's "In scope" list, it's a new issue tagged `icebox`, not something added mid-sprint. new ideas are welcome.
