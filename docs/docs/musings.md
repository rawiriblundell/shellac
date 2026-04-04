This is a collection of design tensions that don't have clean resolutions —
cases where shellac's goals pull in opposite directions. They're worth
writing down rather than quietly deciding, because the same questions will
come up again.

---

## Abstraction depth: when to smooth over a wart

Shellac's purpose is to smooth over shell scripting warts and gotchas. But
shellac also wants to be approachable to newcomers, and a library with an
answer to every problem becomes its own problem.

A concrete example: `sort | uniq` versus `sort -u`.

The kneejerk cleanup is to collapse `sort | uniq` to `sort -u`. On GNU
systems that's fine. On Solaris and some older UNIX systems, `uniq -u` has
quirks — duplicates can slip through in ways that `sort | uniq` handles
correctly. So `sort | uniq` isn't sloppy; it's a portability choice with a
reason behind it.

The next thought is to encapsulate this into a `line_unique()` function that
detects the environment and picks the right behaviour. That's a reasonable
shellac instinct. But it's also a rabbit hole: once you start abstracting
every pipeline that has a portability footnote, you end up with a library
that wraps `sort`, `uniq`, `cat`, and eventually `ls`. At that point you've
rebuilt a compatibility layer, not a utility library.

The tension is:

- **Smooth over warts** — that's the point of shellac.
- **Don't abstract everything** — newcomers need to be able to read the
  code and recognise what's happening. A call to `line_unique` is opaque
  where `sort | uniq` is self-evident.
- **Don't silently change semantics** — collapsing `sort | uniq` to
  `sort -u` in a demo document implies they're equivalent. They mostly are,
  but writing it down as a "cleanup" papers over the reason the original
  author wrote it the way they did.

Where to draw the line is a judgement call made case by case. The heuristic
used here: abstract when the wart is invisible (the caller can't easily
detect it themselves), leave it alone when the pattern is readable and the
reason is documentable. `sort | uniq` is readable; the portability reason
belongs in a comment, not a function.

---

## Portable pipelines: head -c and the habit of writing for the lowest common denominator

`head -c N` reads N bytes from stdin. It works on Linux and macOS, fails
silently or produces wrong output on some BSDs and older Solaris. For a lot
of code that will only ever run on modern Linux this doesn't matter. For
shellac, where the goal is code that travels, it does.

A concrete example is generating random strings:

```bash
# Common but not portable
tr -dc '[:graph:]' </dev/urandom | head -c 16

# Portable equivalent
tr -dc '[:graph:]' </dev/urandom | fold -w 1 | head -n 16 | paste -sd '' -
```

The portable version is longer and less obvious at a glance. `fold -w 1`
splits the character stream one character per line; `head -n 16` takes 16
lines; `paste -sd '' -` collapses them back to a single string. Each tool
in that pipeline has well-defined POSIX behaviour. The result is the same
16-character string, produced reliably everywhere.

The instinct to clean up the longer form is understandable. The pipeline
looks like it's doing extra work. But the extra work is the point — it's
trading readability for reach, and in a shared library that's often the
right trade.

`paste` in particular is an unsung hero of portable shell pipelines. Its
`-sd '' -` idiom (serial paste with empty delimiter, reading stdin) collapses
a stream of lines into a single string without spawning extra processes or
relying on shell tricks. Despite being POSIX for decades, it's routinely
unknown even to experienced shell programmers. The common substitute is
`tr -d '\n'` chained with a trailing `echo` or `printf` to restore the
final newline — a pattern that appears in production scripts, dotfiles, and
Stack Overflow answers from people with decades of shell experience.
`fold` has the same problem: it's been in every UNIX since the 1970s, and
most developers reach for Python or awk before they think of it.

The lesson isn't that everyone should memorise obscure POSIX utilities. It's
that the portable form of a pipeline is often already there in the toolbox,
and the "clever" substitute that bypasses it usually has edge cases the
author didn't test.

The habit extends beyond `head -c`. Anywhere a GNU extension provides a
nicer syntax — `grep -P`, `sed -E` on some systems, `date -d` — there's
a portable form that achieves the same thing with more ceremony. Whether to
use it depends on where the code needs to run. Shellac assumes it needs to
run somewhere inconvenient, so the ceremony stays.

---

## Capability guards: graceful fallback versus silent wrong answers

`array_sort_natural` uses `sort -V` (GNU coreutils version sort) to order
strings containing embedded numbers the way humans expect. On systems
without it, the function falls back to standard lexicographic `sort` with a
warning to stderr.

That seems reasonable. It keeps the function usable everywhere and tells
the caller something went wrong. The problem is that lexicographic sort
doesn't just produce a different order — it produces the wrong order for
the use case. A caller sorting `( v1.9 v1.10 v2.0 )` and getting back
`( v1.10 v1.9 v2.0 )` has a bug, whether or not they saw the warning.

The alternative is to make `sort -V` a hard requirement: check at include
time, fail loudly, and leave it to the caller to decide whether to proceed.
That's less convenient but honest. A function that returns wrong answers
silently is worse than one that refuses to run.

The tension is:

- **Degrade gracefully** — a missing tool shouldn't kill an otherwise
  working script.
- **Don't silently produce wrong results** — a fallback that changes
  semantics isn't a fallback, it's a different function with the same name.

The right call depends on what "wrong" means for the specific function. For
`array_sort_natural`, the order matters by definition — that's why the
caller asked for natural sort. The fallback is semantically incorrect and
the warning may be missed. A hard failure with a clear message would be
more honest.

For other capability guards the calculus is different. A function that
tries `openssl` and falls back to `python3 -c` for base64 decoding is
producing the same result either way. The fallback is safe. The guard
exists only to prefer the faster path.

The heuristic used here: if the fallback produces a different answer, it is
not a fallback. Guard hard, fail loudly, and let the caller handle it.

---

## str_*, line_*, text_*: where the prefix boundaries blur

The three prefixes were intended to encode a meaningful distinction:

- **`str_`** — operates on a string value in memory. Input is an argument,
  output is a transformed value. Character-level. `str_len`, `str_replace`,
  `str_ucfirst`, `str_snake_case`.
- **`line_`** — operates on a stream of lines. Input is stdin or a file,
  output is line-structured. `line_first`, `line_grep`, `line_sort`,
  `line_count`.
- **`text_`** — transforms text for presentation or display. `text_bold`,
  `text_center`, `text_underline`, `text_fg`.

That model is clean on paper. In practice, `text_` has blurred into a
catch-all for "things that transform how text looks," which includes both
ANSI terminal formatting (`text_bold`, `text_fg`) and plain case conversion
(`text_toupper`, `text_tolower`, `text_capitalise`). The case conversion
functions live in `text/style.sh` alongside escape-code wrappers, but
they are not display formatting — they are value transformations.

Meanwhile, `str_ucfirst`, `str_ucwords`, and `str_title_case` do the same
category of work with a `str_` prefix from `text/case_convert.sh`. The
result is a gap in the model: full uppercase is `text_toupper`, but
capitalise-first-word is `str_ucfirst`. The caller wanting to uppercase a
string has no obvious prefix to reach for.

The cross-language context makes this sharper. Python, Ruby, JavaScript, and
Go all put case conversion on the string type itself: `s.upper()`,
`s.upcase`, `s.toUpperCase()`, `strings.ToUpper(s)`. There is no
distinction between "string operation" and "text presentation" at the
language level — it is all one namespace. Shell has no string type, so
shellac has to impose that organization through naming. But the naming
currently reflects the file the function was written in more than the
semantic category it belongs to.

The tension is:

- **`str_` is the right prefix** for case conversion — these are value
  transformations, not presentation effects. `str_toupper` would be
  consistent with `str_ucfirst` and cross-language convention.
- **`text_toupper` and `text_tolower` already exist** and are in use.
  Renaming or aliasing them risks breaking callers and fragmenting the
  documentation.
- **`text_` should mean "display/presentation"** — if it expands to cover
  any function that touches the content of a string, the prefix loses its
  signal value.

This has been partially resolved. The value-transformation functions in
`style.sh` — `text_toupper`, `text_tolower`, `text_capitalise`, `text_c2n`,
`text_n2c`, `text_n2s` — have been renamed to `str_*` canonical names, with
`text_*` kept as thin aliases for backward compatibility. The ANSI formatting
functions (`text_bold`, `text_fg`, etc.) and display layout functions
(`text_center`, `text_wordwrap`) remain `text_*`, which is where they belong.

The alias approach also ran in the other direction: `str_truncate`,
`str_padding`, and `line_indent` — all display/presentation operations —
gained `text_*` aliases (`text_truncate`, `text_padding`, `text_indent`).

The rule that emerged from the cleanup: `text_*` means the function is
primarily about how something looks on screen. `str_*` means it transforms
a string value. When in doubt, ask whether the function would make sense in
a non-terminal context. Case conversion: yes. Centering text to terminal
width: no.

New functions should follow this consistently. The `text_*` aliases in
`style.sh` exist to avoid breaking callers — they are not an invitation to
keep writing `text_` for value transformations.

---

## Self-reference: DRY versus extractability

One of the criticisms shellac levels at other shell library projects is
constant self-reference. A function calls another function from the same
project, which calls another, and before long the dependency graph is deep
enough that pulling out a single function means pulling out half the library.
The irony is that shellac can do this too, if it's not deliberate about it.

The canonical example that came up: `is_command` is a thin wrapper around
`command -v`:

```bash
is_command() {
    command -v "${1:-$RANDOM}" >/dev/null 2>&1
}
```

Using `is_command` inside `text/style.sh` to check for `awk` or `tr` means
anyone who wants to lift `str_toupper` into their own script also needs
`is_command` — which lives in `core/is.sh`, which is part of shellac's
core. A function that could have been self-contained now has a load-order
dependency on the library it came from.

`command -v tool >/dev/null 2>&1` is POSIX, readable, and needs nothing. It's
three extra characters over `is_command tool`. The extra characters cost
nothing; the dependency does.

The tension is:

- **DRY** — the library already has `is_command`, using it is consistent.
- **Extractability** — each function should be copy-pasteable without
  dragging in infrastructure. That's part of what makes shellac different
  from the libraries it criticises.

In a library context DRY is the wrong frame. The goal is not to avoid
repeating `>/dev/null 2>&1` — it's to avoid creating coupling that reduces
the value of the individual function. Three categories of cross-library
reference are worth distinguishing:

**Avoidable** — calling a shellac wrapper where a native shell or POSIX
primitive does the same job. `is_command` → `command -v`. These should not
appear in library code. Replace them on sight.

**Functional** — a function whose purpose is to compose other library
functions. `crypto/genpasswd.sh` calling `random_int` is reasonable because
`genpasswd` is inherently a higher-level function; it builds on `random` by
design. These dependencies should be explicit `include` statements so the
load order is declared, not assumed.

**Aggregator** — a module whose entire purpose is to bundle others.
`sys/hogs.sh` includes `sys/cpuhogs`, `sys/memhogs`, and `sys/swaphogs`
and re-exports them as a single entry point. That's the point of the
module; the dependency is the feature.

The heuristic: if the dependency is invisible to the function's caller and
could be replaced with a primitive, replace it. If the dependency is the
reason the function exists, keep it and declare it explicitly.

---

## requires placement: library level versus function level

`requires` exists to fail loudly when a dependency is missing rather than
let execution continue into a cryptic error message or, worse, a silent
wrong answer. The question that comes up when adding requires guards to
library files is where to put them: at the top of the file so they fire
at load time, or inside individual functions so they fire at call time.

The instinct is to put them at the top of the file. A file named
`ssl_inspect.sh` obviously requires `openssl`. A single `requires openssl`
on line three is visible, obvious, and easy to audit. That instinct is
correct for files where every function uses the same tool.

The instinct breaks down as soon as the tool list is not uniform. Take
`ssl_passwd.sh`: one function calls `openssl passwd`, another calls
`/usr/bin/passwd`. A library-level `requires openssl passwd` blocks the
caller who only needed the system `passwd` path and happens to be on a
system without `openssl`. They didn't ask for `openssl`. The guard is
penalising them for a function they never called.

The same problem appears in larger files. `uuid.sh` spans eight UUID
versions with meaningfully different implementations. `uuid_v1` uses
`ip` or `ifconfig` for the MAC address component. `uuid_v3` and `uuid_v5`
need `md5sum` and `sha1sum` respectively. `uuid_v7` and `uuid_v8` use
`dd` and `awk`. A library-level requires covering all of that would demand
five or six tools upfront, blocking any caller who only wanted
`uuid_v4` — which is pure random and needs none of them.

Library-level requires is a claim that the file is not useful without that
tool. It's appropriate when it's true: `calc.sh` without `bc`, `service.sh`
without `systemctl`, `ssl_diag.sh` without `openssl`. Files with a single
dominant dependency that every function shares. For these, one line at the
top of the file is honest.

Function-level requires is appropriate when functions within the same file
have different external dependencies, or when the library provides fallback
chains. Putting `requires` at the top of the function means the check fires
at the point where the tool is actually needed. A caller who loads the file
but only calls one variant isn't blocked by tools they never touch.

There's a subtlety with automated detection of what a file "requires". The
obvious approach — scan for command names in the source — produces a noisy
list. It picks up builtins (`test`, `echo`, `getopts`, `type`, `alias`,
`false`, `hash`) that are always present and should never appear in requires.
It picks up words that happen to match command names: `file` from variable
names and `# shellcheck shell=bash` in `#!/bin/false` shebangs; `pass` from
the password manager appearing in comments; `last` from a function named
`last`; `w` from a local variable. It picks up self-references in wrapper
files that are themselves the replacement for the tool they appear to require
(`seq.sh` requiring `seq`, `tac.sh` requiring `tac`, `mapfile.sh` requiring
`mapfile`). And it misses the distinction between a tool that is a hard
dependency and one that appears only in an optional fallback branch.

Automated scanning is useful for generating a first-pass candidate list, but
it requires a human pass before anything is committed. The signal-to-noise
ratio in a raw scan is low enough that acting on it directly would introduce
more incorrect guards than correct ones.

The rule that came out of a full audit of the shellac library files:

**Library level** when every function in the file uses the same external
tool, or when the file is so single-purpose that it is useless without it.

**Function level** when the file contains functions with different external
dependencies, when the file provides fallback chains across multiple tools,
or when a significant portion of the file's functions have no external
dependencies at all.

**No requires at all** when the file is pure shell — parameter expansions,
arithmetic, string tests, no external command calls. Requiring nothing is
not a gap in the defensive posture; it is accurate documentation of what
the code actually needs.

This raises an apparent contradiction with the self-reference rule
established earlier: shellac library code should avoid cross-library calls,
because extracting a single function shouldn't drag in half the library.
`requires` is a cross-library call. Every function that uses it depends on
`core/requires.sh`.

The justification is that `requires` is not utility code — it is
infrastructure. The earlier self-reference rule targets calls like using
`is_command` when `command -v` does the same job inline. The concern there
is coupling: a caller who wants `str_toupper` shouldn't need `core/is.sh`
just because the author preferred a shellac wrapper over a POSIX primitive.
`requires` doesn't have a meaningful inline equivalent. The alternative is
an open-coded block:

```bash
my_function() {
  if ! command -v openssl >/dev/null 2>&1; then
    printf -- '%s\n' "my_function: openssl not found" >&2
    return 127
  fi
  # ...
}
```

That is not more extractable — it's just longer and less consistent. The
shellac convention for dependency checking is `requires`, and that
convention has value precisely because it's uniform. If library code
sometimes uses `requires` and sometimes open-codes `command -v` blocks,
callers can't rely on either form being present when they extract a
function. Consistency wins here, and the coupling cost is accepted
deliberately.

What this means in practice: if you lift a shellac function into your own
script and it contains a `requires` call, you need to handle it. The
options are straightforward — either bring `core/requires.sh` along with
it, replace the `requires` call with an inline `command -v` guard, or
remove it entirely if you're confident the dependency is present in your
environment. The `requires` call will fail with `command not found` (exit
127) if `core/requires.sh` hasn't been loaded. It won't fail silently.
That's intentional — a missing `requires` implementation is at least
loud, even if the error message points to the wrong problem.
