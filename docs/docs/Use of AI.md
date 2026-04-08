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

The baseline for these estimates: solo maintenance ran at roughly 30 minutes
per evening, with ~20% of each session spent re-orienting after context
switches. High-overhead research tasks (multi-repo audits, cross-language
comparisons) rarely got started at that pace — the setup cost exceeded what
fits in a 30-minute window, so they stayed on the "someday" list.

The daily breakdown below shows hours saved per session against that baseline.
The force multiplier (solo hours ÷ AI hours) is consistently high on
research-heavy days and lower on pure implementation days, which is expected.
Cumulative over 23 active days: **~27×**.

### Highlights (23 active days, 2026-03-12 to 2026-04-09)

- **315 commits**, 44 GitHub issues opened, 59 closed (including 16 pre-existing issues cleared during the collaboration)
- Functions: ~700 → **828** (+128 unique functions added)
- **84 bats test files** covering the full module surface (1,432 tests); those
  tests found and fixed **16 source bugs** spanning arithmetic exit codes,
  circular namerefs, timezone-dependent date arithmetic, missing includes, and
  logic errors
- **58-repo license audit** and **4-language stdlib gap analysis** — both tasks
  too high-overhead to attempt in 30-minute solo sessions
- Codebase-wide `echo` → `printf` sweep; camelCase → `snake_case` rename
  across `lib/sh/`; bash4-isms audit and fixes across 21 files
- Complete MkDocs overhaul including CI pipeline; 5 documentation pages written
  from scratch
- Architecture work: `include()` `.bash`/`.sh` extension convention; `requires`
  placement audit; `is_builtin`, `is_keyword`, `is_alias` introspection functions
- **13 functions** adapted from pure-bash-bible (MIT) across `array/`, `numbers/`,
  `sys/`, `path/`, and `text/` — all pure bash, no external deps
- Project `CLAUDE.md` created; `CONTRIBUTING.md` coding style section restructured
  from basics up through minutiae for human and AI readability

### Daily breakdown

Methodology: commits per day are used as a proxy for work density. Solo
evening estimates are assigned proportionally to commit weight and task type
(research-heavy days get higher estimates; implementation days track closer to
commit count). AI hours are estimated from session activity. Hours saved =
(solo_evenings × 0.5h) − AI_hours. Force× = solo_hours ÷ AI_hours, where
solo_hours = solo_evenings × 0.5h.

| Date   | Commits | Solo Eve | AI Hrs | Hrs Saved | Force× |
|--------|---------|----------|--------|-----------|--------|
| Mar 12 |   6     |  6.0     |  1.0   |   2.0     |  26×   |
| Mar 13 |   4     |  2.5     |  0.5   |   0.75    |  11×   |
| Mar 14 |  15     |  9.5     |  1.0   |   3.75    |  41×   |
| Mar 15 |  16     |  8.5     |  1.5   |   2.75    |  37×   |
| Mar 16 |  47     | 15.0     |  2.5   |   5.0     |  64×   |
| Mar 17 |  48     | 12.0     |  2.5   |   3.5     |  52×   |
| Mar 18 |  11     |  6.5     |  1.0   |   2.25    |  28×   |
| Mar 19 |  48     | 16.0     |  2.5   |   5.5     |  69×   |
| Mar 20 |  10     |  4.0     |  1.0   |   1.0     |  17×   |
| Mar 21 |   9     |  5.0     |  1.0   |   1.5     |  21×   |
| Mar 22 |   1     |  2.5     |  0.5   |   0.75    |  11×   |
| Mar 23 |   1     |  1.5     |  0.5   |   0.25    |   6×   |
| Mar 24 |  16     |  6.0     |  1.5   |   1.5     |  26×   |
| Mar 29 |  12     |  8.5     |  1.0   |   3.25    |  37×   |
| Mar 30 |   2     |  1.5     |  0.5   |   0.25    |   6×   |
| Mar 31 |  12     |  9.5     |  1.5   |   3.25    |  41×   |
| Apr 01 |   3     | 12.0     |  2.0   |   4.0     |  52×   |
| Apr 02 |   8     |  6.0     |  1.0   |   2.0     |  26×   |
| Apr 03 |  19     |  8.5     |  1.5   |   2.75    |  37×   |
| Apr 04 |   8     |  4.0     |  1.0   |   1.0     |  17×   |
| Apr 07 |  10     |  7.5     |  1.5   |   2.25    |  32×   |
| Apr 08 |   3     |  5.5     |  1.0   |   1.75    |  28×   |
| Apr 09 |   6     |  7.0     |  1.5   |   2.0     |  23×   |
| **Total** | **315** | **164.5** | **30.0** | **52.25** | **~27×** |

#### Force multiplier per day (each █ ≈ 5×)

```
Mar 12  █████                        26×
Mar 13  ██                           11×
Mar 14  ████████                     41×
Mar 15  ███████                      37×
Mar 16  ████████████                 64×
Mar 17  ██████████                   52×
Mar 18  █████                        28×
Mar 19  █████████████                69×
Mar 20  ███                          17×
Mar 21  ████                         21×
Mar 22  ██                           11×
Mar 23  █                             6×
Mar 24  █████                        26×
Mar 29  ███████                      37×
Mar 30  █                             6×
Mar 31  ████████                     41×
Apr 01  ██████████                   52×
Apr 02  █████                        26×
Apr 03  ███████                      37×
Apr 04  ███                          17×
Apr 07  ██████                       32×
Apr 08  █████                        28×
Apr 09  ████▌                        23×
```

#### Hours saved per day (each █ ≈ 0.5h)

```
Mar 12  ████                         2.0h
Mar 13  █▌                           0.75h
Mar 14  ███████▌                     3.75h
Mar 15  █████▌                       2.75h
Mar 16  ██████████                   5.0h
Mar 17  ███████                      3.5h
Mar 18  ████▌                        2.25h
Mar 19  ███████████                  5.5h
Mar 20  ██                           1.0h
Mar 21  ███                          1.5h
Mar 22  █▌                           0.75h
Mar 23  ▌                            0.25h
Mar 24  ███                          1.5h
Mar 29  ██████▌                      3.25h
Mar 30  ▌                            0.25h
Mar 31  ██████▌                      3.25h
Apr 01  ████████                     4.0h
Apr 02  ████                         2.0h
Apr 03  █████▌                       2.75h
Apr 04  ██                           1.0h
Apr 07  ████▌                        2.25h
Apr 08  ███▌                         1.75h
Apr 09  ████                         2.0h
```

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
