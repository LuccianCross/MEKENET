# Team Rules

Short, on purpose. If you only read one document before starting, read this one.

## The non-negotiables
1. **Never push directly to `main`.** Every change goes through a branch and a Pull Request, no exceptions — even for "tiny" fixes. The repo is now public, so `main` is protected by GitHub itself: direct pushes are blocked automatically. This rule is now a backstop, not the only line of defense — but keep following it anyway, since GitHub's rule only catches the push itself, not sloppy habits.
2. **Every PR needs at least one other person's review before merging.** GitHub is set to require this — a PR literally can't merge without it. If you're stuck waiting on a review, say so in the daily check-in.
3. **Every GitHub Issue has exactly one owner and one label** (`mobile`, `parser`, `storage`, `backend`, `product`/`gtm`). If it doesn't fit a label, ask before starting it.
4. **If it's not in the PRD's "in scope" list, it doesn't get built this week.** New ideas go into an issue tagged `icebox`, not into the current sprint. Say it in the check-in, don't just start building it.
5. **Show up to the daily check-in.** Two minutes each: what you finished, what's blocking you. If you're blocked, say it loudly — a blocker you mention on day 2 costs an hour; the same blocker discovered on day 6 costs the whole sprint.
6. **If you're touching `models/`, say so in the check-in before you do.** This is the one folder everyone else's code depends on, and an unannounced change here is the fastest way to break someone else's branch without meaning to.
7. **Follow the folder structure**. This is the architecture from sections 8 in the SDD, made physical — so anyone opening a branch knows exactly where their work belongs.

## Branch & commit conventions
- Branch names: `feature/[label]-short-description`, e.g. `feature/parser-telebirr-income`.
- Commit messages: short, imperative instructions — `"Add regex for telebirr expense format"`, not `"fixed stuff"`.
- Link your PR to its issue with `Closes #[issue number]` in the description, so it auto-closes on merge.

## If something breaks
- Don't sit on it hoping it resolves itself — flag it in the team chat the same day.
- If you're not sure whose area a bug is in, tag whoever owns the closest label and let them redirect it if needed.

## The spirit of these rules
Five people, eight days, most of us new to working like this together — the rules exist to make sure nobody's individually confused or blocked, not to slow anyone down. If a rule is actively getting in the way of real progress, say so to the lead directly instead of quietly ignoring it.
