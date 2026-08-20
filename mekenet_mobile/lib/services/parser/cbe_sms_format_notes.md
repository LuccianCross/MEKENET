# CBE SMS Format Notes

CBE does not use a single template. There are three separate message formats depending on transaction type, and each has different keywords, so a single "debited"/"credited" check will miss most of them.

## Sent vs Received

Own-account transfer (CBE → CBE): sent is the word "transferred", received is the word "received".

Interbank transfer, CBE → other bank: always outbound, sent is the phrase "transferred to other bank". There's no "received" case here since this format is only ever used for money leaving the account.

Interbank transfer, other bank → CBE: always inbound, received is the phrase "has been credited". There's no "sent" case here.

Important: "debited" doesn't appear in any real sample collected so far. "credited" only shows up in the interbank-in format — it's not a general-purpose "received" keyword the way the current parser assumes.

## Date Format

Own-account transfers (both directions) and interbank-out messages have no date/time in the text at all — see the open question below about whether that's really missing or got dropped during collection.

Interbank-in messages do include a timestamp, formatted as `YYYY-MM-DD HH:MM:SS`, e.g. `2026-08-07 20:41:52`.

## Quirks

Own-account transfers always include a fee breakdown: a service charge, 15% VAT on that charge, and a 5% "Disaster Recovery" fee, followed by a "total" figure that's the amount plus all fees combined.

Interbank-out messages have an inconsistent fee breakdown — some list charge + VAT + EDRRF, others list only VAT, with no charge or EDRRF at all.

The interbank-out template literally says "In Commercial Bank of Ethiopia" even though the money is going to a different bank. This is confirmed present in the real SMS, not a copy error — don't try to extract a "destination bank name" from that phrase.

Amount formatting is inconsistent, sometimes even within the same format: `ETB110.00` (no space, 2 decimals) vs `ETB 500` (space, no decimals) vs `ETB2,000.00` / `ETB 2,000` (with or without a thousands separator). The regex needs to tolerate all of these.

Spacing around numbers is inconsistent too — some messages have a double space before the amount (`ETB  500`). Probably just inconsistent templating on CBE's end, so don't rely on exact whitespace.

One real sample has a stray extra parenthesis around the name field — `(name))`. That's a genuine artifact of the source SMS, not something introduced during anonymizing.

The sign-off differs by format: own-account messages end with "Thanks for Banking with CBE" (sometimes with a "for feedback" link, sometimes without), while interbank messages end with "Contact Center 8980" instead.

## Open Questions

Confirm whether the own-account transfer messages genuinely omit date/time, or whether that got dropped when the samples were collected.

The single interbank-in ("has been credited") sample has no bank name in its signature. Confirm it's actually CBE and not Awash — see the matching note in the Awash format notes, since both banks appear to share an identical template for this transaction type.