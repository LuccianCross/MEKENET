# Awash SMS Format Notes

Coverage warning: all 4 samples collected so far are incoming ("received") transactions. There's currently no confirmed real sample of an outgoing Awash SMS, so the "sent" keyword below is unverified.

## Sent vs Received

Received is signaled by the word "Credited" or the phrase "has been credited".

Sent is unknown — there's no real sample yet. The current parser assumes the word "sent", but that hasn't been confirmed against an actual message, so don't treat it as verified.

Worth noting: the word "received" itself doesn't appear in any real Awash sample collected so far, even though the parser currently checks for it.

## Date Format

`YYYY-MM-DD HH:MM:SS`, e.g. `2026-07-31 14:28:33`.

## Quirks

Two of the four samples end with an explicit "Awash Bank." sign-off. The other two end with "Contact center 8980" and no bank name at all.

Those two unsigned samples are structurally identical to CBE's interbank-in template — same wording ("ETB {amt} has been credited to your account from {name} on : {date} with Txn ID: {id}"), same "Contact center 8980" phrase. That could mean either bank shares a common SMS-gateway vendor template for interbank-in transactions, or these two samples were actually CBE messages that got mixed into the Awash set during collection. Worth confirming against the original screenshots before trusting this as genuinely Awash-specific — see the matching note in the CBE format notes.

The signed ("Awash Bank.") samples use "Credited" (capital C) as part of "has been Credited with ETB...". The unsigned samples use lowercase "credited" as part of "has been credited to your account from...". Different phrasing even if these turn out to be the same underlying event type.

## Open Questions / Gaps

No outgoing/debit sample exists yet. At least 2-3 real "sent" messages from an Awash user are needed before the parser's outbound-detection logic can be verified at all.

Confirm whether the two unsigned "has been credited... Contact center 8980" samples are actually Awash or were misattributed CBE messages.

Only 4 total samples so far — below the 10-15 target. More real messages, in both directions, would meaningfully improve parser test coverage.