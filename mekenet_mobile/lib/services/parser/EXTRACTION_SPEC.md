# What the parser needs to pull out of a telebirr SMS

Draft for team review — edit freely once we see the real message samples in test_assets/telebirr_sms_samples.md. Some of this will need adjusting once we see actual message wording/formats.

# Fields to extract
# Amount
How much money moved, as a number.
Strip currency symbol/commas (e.g. "Birr 1,250.00" -> 1250.00).
# Direction
Was money sent (out) or received (in)?
Two values only: sent / received.
Inferred from wording like "You have received" vs "You have transferred/paid".
Confirmed from the real samples: fee/VAT lines only ever appear on "sent" messages, so that's a second signal we can cross-check against.
# Timestamp
Roughly when it happened.
Telebirr messages include a date/time string (DD/MM/YYYY HH:MM:SS) — parse to a real date, don't just store raw text.
If a message has no time, fall back to the time the SMS was received on-device (approximate is fine — that's why the task says "roughly when").
# Counterparty
Who the other party was (name and/or masked phone number), if present.
Optional — nice to have, not required for a valid transaction.
# Transaction ID
Telebirr's own reference/confirmation number, if present.
Useful for de-duplication later.
# Balance after transaction
Remaining balance, if the message states it.
Optional.
# Out of scope for this parser (for now)
Anything that isn't a transaction confirmation (promos, balance-check replies, OTPs, etc.) — those should be filtered out before parsing, or the parser should safely return "not a transaction" rather than guessing.
Airtime top-ups / bill payments — flag as a separate open question for the team: do we treat these as their own direction category, or fold into "sent"?
# Open questions for the team
Do we need sub-categories of "sent" (e.g. merchant payment vs peer-to-peer transfer vs bill pay), or is in/out enough for v1?
What's our fallback behavior when a message doesn't match any known format?
