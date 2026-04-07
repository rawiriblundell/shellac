Shellac is developed using Claude Code (Anthropic's CLI tool for Claude) as a
collaborative pair. This page documents how that collaboration works and what
guides it — both to be transparent about the process and because the approach
itself reflects shellac's values: clear conventions, explicit contracts, no
magic.

---

## What we've worked on together

The AI involvement spans the full development lifecycle rather than isolated
tasks:

- **Library implementation** — writing, reviewing, and refining functions
  across modules (`crypto/`, `net/`, `ssl/`, `array/`, `text/`, `numbers/`,
  `fs/`, `git/`) following the project's naming conventions and shdoc
  annotation format
- **Bug finding and fixing** — catching latent issues like the `ssl_view_cert`
  `state` case passing the cert file path to `openssl -checkend` instead of a
  seconds threshold (`${2:-0}` → `${3:-0}`)
- **Capability audits** — surveying candidate functions from similar projects
  (`bash-oo-framework`, `bash-oop`, `bash-toml`, and others), classifying them
  by license, reviewing for clean-room implementation candidates, and raising
  GitHub issues for the accepted ones
- **Coverage gap analysis** — comparing shellac's 750+ functions against the
  standard libraries of Python, Ruby, Go, and Node.js to identify meaningful
  gaps worth filling
- **Test coverage** — generating 84 bats test files covering the full module
  surface (1,412 tests); working through the failures to find and fix 16
  source bugs spanning arithmetic exit codes, circular namerefs,
  timezone-dependent date arithmetic, missing includes, and logic errors
- **Naming refactors** — migrating value-transform functions in `text/style.sh`
  to canonical `str_*` names; adding `text_*` aliases to display-oriented
  functions in `str_*` and `line_*`; replacing internal `is_command` calls
  with `command -v` to improve individual function extractability
- **New introspection functions** — `is_builtin`, `is_keyword`, and `is_alias`
  added to `core/is.sh`, completing the shell-type introspection set alongside
  the existing `is_function`, `is_command`, and `is_in_path`
- **Bug fix: `include --force`** — the `--force` flag correctly bypassed
  `include`'s own loaded-check but not the guard sentinel at the top of the
  target file itself; fixed by unsetting the sentinel before sourcing in all
  three resolution branches; `sh_stack_add` tracing improved in the relative
  path branch to aid debugging
- **Dependency scanner** — a shellac-native script for auditing external
  command dependencies across library files, developed iteratively from a
  grep pipeline to a fully idiomatic shellac implementation; documented as
  Example 3 in `shellac_in_practice.md` and drove the addition of
  `is_builtin`/`is_keyword` as practical tools for filtering scan results
- **Documentation** — writing `shellac_in_practice.md` (three real scripts
  rewritten side-by-side, including a worked example of progressive shellac
  adoption developed iteratively during a live session), `musings.md` (design
  tensions that don't have clean resolutions), `on_vibe_coding.md` (a
  conversation about AI-assisted engineering versus vibe coding), and structural
  docs like `.pages` nav ordering
- **GitHub issues** — drafting and filing issues for new modules, with
  counterparts in other languages documented for context
- **MkDocs configuration** — adding `md_in_html` for side-by-side code layout
  in documentation

---

## How the collaboration works

The working pattern is closer to senior-developer/technical-lead than
autocomplete. Concrete examples:

- When asked to suggest candidates from third-party libraries, the AI reviewed
  licenses, cloned repos, identified functions worth considering, and presented
  a categorised list for the human to accept or reject — rather than silently
  importing anything
- When the AI suggested cleaning up a `sort | uniq` pipeline, the human surfaced the
  portability reason behind it (Solaris `uniq` quirks) rather than collapsing
  it to `sort -u`, and the conversation produced `musings.md` instead
- When a suggested refactor would have changed semantics (the `shellac_in_practice.md`
  loading pattern), the AI caught it and corrected its own draft

The human sets direction, makes final calls on what to accept, and owns the
codebase. The AI does research, drafts, flags tradeoffs, and surfaces things
worth knowing — but does not make unilateral decisions about design. AI is used as a
collaborative tool, not a copy-and-paste crux.

---

## What works well

- **Explicit conventions** — the shell scripting standards and naming
  conventions give the AI a clear target. It doesn't have to guess the
  preferred style for `local` declarations, case statement formatting,
  `printf` vs `echo`, or variable naming.
- **Tight feedback loops** — short exchanges ("yes, do it", "skip those",
  "that's already covered by X") keep the work moving without over-explaining.
- **GitHub Issues as session continuity** — AI sessions have no persistent
  memory of prior work beyond what's in the codebase and standing instructions.
  GitHub Issues fill that gap: accepted candidates, planned modules, and
  outstanding work are filed as issues so the next session can pick up where
  the last left off without relying on conversation history. The issue tracker
  is the shared backlog, not the AI's recall.
- **Asking before doing** for anything that touches shared state (GitHub
  issues, commits, external writes)
- **Surgical changes** — the AI is instructed to touch only what was asked,
  not to "improve" adjacent code or add unrequested features. When changes
  create orphaned imports or dead code, those get cleaned up; pre-existing
  issues get mentioned but not silently deleted.

---

## Productivity metrics

These figures are presented at two snapshots and are intended as an honest,
methodology-transparent estimate rather than marketing copy.

### Snapshot 1: 10-day mark (2026-03-12 to 2026-03-21)

| Category | Detail |
|----------|--------|
| Commits | 214 in 10 active days |
| GitHub issues opened | 28 (nos. 32–59) |
| GitHub issues closed | 19 — bugs, style sweeps, audits, rename, tests, standardisation passes |
| Functions in codebase | 734 unique |

Work covered in that period: targeted bug fixes in three files; codebase-wide
`echo` → `printf` sweep; camelCase → snake\_case rename across `lib/sh/`;
case pattern style enforcement; `text/` global scope removal; third-party
library audit; project rename; tests framework; `net/` and `fs/`
standardisation; major refactors of `core/is.sh` and `units/temperature.sh`;
new functions (`array/readlist`, `text/encode`, `fs/base64`,
`net_wait_for_port`, `ssl_view_cert` days case); complete MkDocs overhaul
including CI pipeline; five documentation pages written from scratch; license
audit of 58 competing projects; cross-language stdlib coverage gap analysis.

### Snapshot 2: 21-day mark (2026-03-12 to 2026-04-02)

| Category | Detail |
|----------|--------|
| Commits | 267 in 18 active days (+52 since snapshot 1) |
| GitHub issues opened | 30 (nos. 32–61, +2 since snapshot 1) |
| GitHub issues closed | 29 (+10 since snapshot 1) |
| Functions in codebase | 741 unique (+7 since snapshot 1) |

Additional work since snapshot 1: 84 bats test files covering the full module
surface (1,412 tests, growing to 1,432 with subsequent additions); 16 source fixes found by those tests spanning arithmetic
exit codes, circular namerefs, timezone-dependent date arithmetic, missing
includes, and logic errors; `str_*`/`text_*` naming refactor in `style.sh`
with backward-compatible aliases; `is_command` → `command -v` replacement to
improve individual function extractability; `on_vibe_coding.md` and two new
`musings.md` entries on prefix boundary tension and DRY versus extractability.

### Manual baseline

Prior to this collaboration the codebase was maintained at roughly 30 minutes
per evening, with occasional spikes when interest ran high. At that pace,
accounting for context-switching overhead (~20% of each session spent
re-orienting) and the realistic tendency for high-overhead research tasks to
get deprioritised indefinitely:

#### Snapshot 1 estimate (10-day work)

| Work category | Estimated evenings solo |
|---------------|------------------------|
| Code refactors + bug fixes | 10–13 |
| New functions | 6–8 |
| Style sweeps (echo, camelCase, case patterns) | 8–12 |
| `text/` global scope + other audits | 5–7 |
| Project rename | 3–5 |
| Tests framework | 4–6 |
| MkDocs overhaul + CI | 6–8 |
| Documentation (5 pages) | 8–12 |
| License audit + cross-language gap analysis | 8–12 |
| GitHub issues (28, several with detailed specs) | 6–7 |
| **Total** | **64–90 evenings** |

At 30 minutes per evening that is **9–12 months of calendar time**. Several
of the research tasks (the 58-repo license audit, the four-language stdlib
comparison) likely would not have been attempted at all solo — the setup cost
exceeds what fits in a 30-minute window, so they would have stayed on the
"someday" list.

#### Snapshot 2 estimate (additional 8 active days)

| Work category | Estimated evenings solo |
|---------------|------------------------|
| 84 bats test files (written; running; iterating) | 10–14 |
| 16 source fixes found by tests | 4–6 |
| `str_*`/`text_*` naming refactor | 2–3 |
| Documentation (`on_vibe_coding`, musings entries) | 4–5 |
| `is_command` → `command -v`; other small fixes | 1–2 |
| **Additional total** | **21–30 evenings** |
| **Cumulative total** | **85–120 evenings** |

Cumulative at 30 minutes per evening: **10–14 months of calendar time**.
The test suite in particular — 84 files across the full module surface — has a
high solo cost not just in writing time but in the tendency to stay perpetually
half-done. A partial test suite that doesn't cover the whole surface doesn't
tell you much; the full-coverage pass is the valuable artifact.

### Force multiplier

| Method | Snapshot 1 | Snapshot 2 (cumulative) |
|--------|-----------|------------------------|
| Calendar ratio | 9–12 months ÷ 10 days = ~27–36x | 10–14 months ÷ 18 days = ~17–23x |
| With scope premium (tasks not attempted solo) | × 1.5–2x → **40–70x** | × 1.5–2x → **25–45x** |

**Snapshot 1 central estimate: 40–60x.** **Snapshot 2 central estimate: 30–40x.**

The cumulative multiplier is lower than the 10-day figure for an honest
reason: the denominator grew. The first 10 days were dense with high-leverage,
high-scope-premium work — a 58-repo license audit, a four-language stdlib
comparison, a complete test framework from scratch. The next 8 active days
were still productive but weighted toward implementation and refinement rather
than research tasks with outsized setup cost. A sustained 40–60x is not
realistic; a sustained 30–40x over a longer working period is.

The multiplier is not primarily about typing speed. It comes from: no
context-switching overhead between sessions; research tasks that are
economical at AI speed but prohibitive at human-alone speed; and the ability
to run a full audit, draft documentation, and file detailed issues in a single
sitting rather than across weeks.

---

## Guiding inputs

The AI operates under a set of standing instructions that persist across
sessions. They're reproduced here for transparency.

### Global development standards (`~/.claude/CLAUDE.md`)

Covers system environment context (AlmaLinux, multi-datacenter, Ansible
automation), general behavioural guidelines (think before coding, simplicity
first, surgical changes, goal-driven execution), and a pointer to Karpathy's
guidelines for reducing common LLM coding mistakes.

Key principles extracted:

- State assumptions explicitly; if multiple interpretations exist, present them
  rather than picking silently
- No features beyond what was asked; no abstractions for single-use code; no
  error handling for impossible scenarios
- When editing existing code: don't improve adjacent code, match existing style
  even if you'd do it differently, only clean up orphans your own changes created
- Transform tasks into verifiable goals; state a brief plan for multi-step work

### Shell scripting standards (`~/.claude/rules/shell-scripting.md`)

A detailed set of rules for bash. Critical prohibitions:

- **Never** `set -euo pipefail` or `set -e` — handle errors explicitly
- **Never** parse `ls` output — use globs or `find`
- **Never** `which` — use `command -v`
- **Never** unquoted variables
- **Never** backticks — use `$()`
- **Never** `echo` — use `printf -- '%s\n'`
- **Never** `let` or `expr` — use `$(( ))`
- **Never** bare `*` glob — use `./*`
- **Never** pipe to `while` when variables need to persist — use process
  substitution
- **Never** `eval`

Mandatory practices include: `lower_snake_case` for all variables, always
`${curly_braces}`, `local` declarations separate from assignments (to avoid
masking exit codes), `(( ))` for all numeric comparisons, and the specific case
statement format with opening parentheses on patterns and `;;` vertically
aligned.

### Shellac library standards (`~/.claude/rules/shellac.md`)

Shellac-specific rules that layer on top of the general bash standards:

- `requires` placement: library-level when every function shares the same
  external dependency; function-level when dependencies vary within a file;
  none at all for pure-shell files. Derived from the full library audit
  documented in `musings.md`.
- What counts as an external dependency — excludes builtins, keywords,
  shellac functions (use `include` for those), and words in string literals.
  `is_builtin` and `is_keyword` from `core/is` are the canonical test.
- Self-reference rules: no shellac wrappers where a native primitive works;
  `requires` is explicitly exempted as infrastructure.

### De-slop guide (`~/.claude/rules/deslop.md`)

A writing editor prompt for stripping AI writing patterns from drafts: em
dashes, corrective antithesis ("Not X. But Y."), dramatic pivot phrases ("But
here's the thing"), soft hedging language, staccato rhythm, gift-wrapped
endings, throat-clearing intros, copy-paste metaphors, overexplaining the
obvious, and generic examples.

Source: [Mooch Agency Deslop](https://www.mooch.agency/deslop-a60e4b10f9df43f3bf6ea366eed1b31f)
