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
Stack Overflow answers from people with fifteen years of shell experience.
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
