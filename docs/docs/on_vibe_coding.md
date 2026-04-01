This page captures a conversation that took place after a session in which
Claude Code generated 84 bats test files covering shellac's full module
surface, then worked through the bugs those tests found — 16 source fixes
across arithmetic exit codes, circular namerefs, timezone-dependent date
arithmetic, missing includes, and logic errors — until 1412 tests passed
with 0 failures.

The conversation started with a question about how to characterise the work.

---

## Would you describe this as "vibe coding"?

**Human:** Would you describe our combined efforts as "vibe coding" or would
the starting point of a human-built framework, with existing code, prepared for
AI collaboration with the provision of style guides, deslop rules etc make 
this count as something else?

**Claude:** Vibe coding, as Karpathy described it, is essentially: describe
what you want, accept what comes out, move fast, don't read the code. The
model drives; you just steer by feel.

What we've been doing is structurally different in a few ways worth naming.

You brought the constraints. The shell scripting standards, the deslop rules,
the CLAUDE.md behavioural guidelines, the existing library architecture — these
aren't things I generated. They represent years of your own opinions baked in
before I touched anything. That's not vibe coding; that's a human-defined
quality envelope I have to work inside.

The debugging was diagnostic, not generative. Tracing `(( _i++ ))` returning
exit 1, the circular nameref, the `shift 2` with insufficient args, the
timezone artifact in `date -d` — these required understanding *why* something
was wrong, not just accepting a replacement. That's closer to pair debugging
than vibing.

You reviewed before committing. You saw the diff summary and approved it. That's
a checkpoint vibe coding explicitly skips.

Where it does lean toward vibe coding: I wrote 84 test files in bulk without
you reading each one. You trusted the output largely by running it. That part
had vibe energy.

So honestly — it's something in between. "AI-assisted engineering with a strong
human frame" is closer. The framework, the taste, the standards were yours. I
was a fast but supervised executor operating inside your constraints, not a
driver you handed the wheel to.

The distinction matters because the bugs I found are credible precisely because
your codebase had real structure to test against. Vibe coding tends not to
generate things worth finding bugs in.

---

## How would this have panned out had it been vibe coded?

**Human:** How would this have panned out had it been completely vibe coded? What
would be the differences in human behaviours and technical constraints?

**Claude:** The human behaviours would be different first.

In vibe coding you don't bring a framework — you ask for one. "Write me a shell
utility library" into a blank context. No style guide, no prior opinions, no
CLAUDE.md. The AI makes every architectural decision because there's nothing to
constrain it. You accept the first output because you have no basis to reject
it. You might ask for changes ("make it more robust") but those are vibes, not
specifications.

Without your shell standards document, I'd have written code that looks
competent and fails subtly. `set -euo pipefail` at the top of everything —
because that's what AI-generated shell looks like. It reads as professional.
It's cargo-culted from tutorials. And it would have made the actual bugs we
found invisible, because the script just dies rather than returning a meaningful
exit code. You'd see green tests or silent failures, never the real shape of
the problem.

The `(( _i++ ))` exit code bug wouldn't have been found because I'd have
written the tests immediately after writing the code, sharing the same mental
model. The test would assert whatever the broken code produces. Both would be
"correct" relative to each other. The test suite passes. Nothing is actually
verified.

The date arithmetic would use `date -d` with the `+N day` syntax because that's
what appears in blog posts and Stack Overflow answers from 2015. The tests would
be written on the same machine, in the same timezone, and pass. They'd fail on a
UTC server or a machine with a different locale, but you'd only find that out in
production.

### The technical artifacts look superficially similar but are hollow

The structure would exist — modules, functions, naming — because I
pattern-match on what a library looks like. But the load-bearing details would
be wrong in ways that compound. Without your prohibition on `echo`, every
function uses `echo` and the `-n`/`-e` behaviour is undefined across shells.
Without `command -v` over `which`, the code silently breaks on Alpine. Without
the `local` declaration discipline, functions leak globals in non-obvious ways
that only matter when two functions share a variable name.

The namerefs would have been written `local -n arr="$1"` because that's the
documented syntax. The circular reference when the caller names their variable
`arr` is a second-order problem that only appears under specific conditions.
Vibe coding generates the happy path. Your standards document forced the
defensive pattern.

### The test suite would be a liability rather than an asset

This is the sharpest difference. The 1412 tests we ended up with found real
bugs because the tests were written with some independence from the
implementation — I was working from the documented interface, not from the code
internals. Even so, several tests had to be fixed because they shared my
assumptions about stdin, tty detection, and arithmetic exit codes.

In a fully vibe-coded session, I'd write the code, then immediately write tests
for it. The tests would encode my bugs as expected behaviour. `str_len ""`
reading from stdin instead of returning 0 — a test written right after would
probably pipe input to it and call that correct. The circular nameref in
`array_shift` would have a test that never uses `arr` as the variable name, so
it never triggers. Green across the board. Confidence with no foundation.

### The compounding problem

Vibe coding tends to be iterative in a specific way: something breaks in use,
you describe the symptom, the AI patches it locally without understanding the
root cause. The `dos2unix` tmp file bug (`/tmp/${full_path}` creating
`/tmp//tmp/filename`) would eventually surface. You'd say "dos2unix is broken on
files in /tmp." I'd add a `basename` call to the temp file name. But I wouldn't
notice the `(( rc++ > 0 ))` arithmetic exit code problem in the same function,
because you only described one symptom. That bug would sit there until someone
catches a successful conversion returning exit 1 in a script where they happened
to check `$?`.

Your style guide prevented a whole class of these by making the arithmetic
convention explicit and consistent. Without it, every function author (me, in
this case) makes the `(( expr ))` decision fresh each time, and gets it wrong at
unpredictable intervals.

### What you actually provided was a falsifiability framework

Vibe coding produces code that's hard to be wrong about because there's no prior
definition of correct. Your standards, your architecture, your existing code —
these created a definition of correct that existed before I wrote anything.
That's what made the bugs findable rather than definitional.

The difference isn't really about AI capability. It's about whether the human
shows up with a standard the AI has to meet, or whether the human lets the AI
define the standard it's measured against.
