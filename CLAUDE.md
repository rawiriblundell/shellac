# Shellac — Claude Code Instructions

These rules apply to all work in this repository.  They extend the global
shell scripting standards and take precedence over them where they overlap.

In all English text — documentation, comments, commit messages — use **two
spaces** after a full stop before the next sentence.  Rawiri aced his Pitman's
qualifications with 100% passing grades and will not descend into single-space
savagery.  Do not "fix" double spaces to single.  They are correct.

---

## Hard prohibitions

- **Never** `set -e`, `set -u`, `set -o pipefail`, or any combination
- **Never** parse `ls` output — use globs or `find`
- **Never** `which` — use `command -v`
- **Never** unquoted variables
- **Never** backticks — use `$()`
- **Never** `echo` — use `printf`
- **Never** `let` or `expr` — use `$(( ))`
- **Never** bare `*` glob — use `./*`
- **Never** pipe to `while` when variables need to persist — use `< <(cmd)`
- **Never** `eval`
- **Never** `function` keyword for function definitions

`printf` **must always** include `--`: `printf -- '%s\n' "${var}"`.
No exceptions — this applies inside pipelines, subshells, and fallback branches.

---

## Variables

- `lower_snake_case` everywhere; `UPPER_CASE` only for env vars and constants
- Always `"${curly_braces}"` — omit only inside `$(( ))` arithmetic
- Library function locals: leading underscore (`_var`), declared **before** assignment on a separate line
- No single-char names except C-style loop index `i` and shell specials (`$#`, `$?`, etc.)
- `for item in` / `for file in` — never `for i in` (reserve `i` for C-style `for (( i=0; ... ))`)

Default values via parameter expansion, not `if`:

```bash
: "${foo:=default}"    # assign if unset or empty
: "${foo=default}"     # assign only if unset
```

---

## Arithmetic

`$(( ))` for all math.  `(( ))` for numeric tests and increments.  Never `-lt`/`-gt`/`-eq` inside `[[ ]]`.

---

## Conditionals

- `[[` for bash; `[` only for POSIX portability
- String equality: `[[ "${a}" = "${b}" ]]` — `=` not `==`
- Numeric: `(( a > b ))` — never `[[ a -gt b ]]`
- Explicit string tests: `[[ -z "${var}" ]]` / `[[ -n "${var}" ]]`
- Prefer `case` over bash regex (`[[ =~ ]]`) where possible — more portable and easier to read
- If you find yourself reaching for `elif`, consider whether a `case` statement fits better.  Two or more branches on the same variable is a strong signal to switch.

---

## Case statement format

```bash
case "${variable}" in
    (option1)
        ...
    ;;
    (option2|option3)
        ...
    ;;
    (*)
        ...
    ;;
esac
```

Opening `(` on the pattern line; `;;` vertically aligned with it.  Always include `(*)`.

---

## Error handling

Check return codes explicitly.  All errors and warnings go to stderr:

```bash
printf -- '%s\n' "Error: something failed" >&2
return 1
```

---

## Shellac library rules

### File guard (sentinel)

Every library file starts with:

```bash
[ -n "${_SHELLAC_LOADED_<module>_<library>+x}" ] && return 0
_SHELLAC_LOADED_<module>_<library>=1
```

Path → sentinel: replace `/` and `-` with `_`, strip extension.
`net/cidr.sh` → `_SHELLAC_LOADED_net_cidr`.
Both `.sh` and `.bash` variants of the same module share the same sentinel name.

### `requires` declarations

- **Library-level** (after the sentinel): all functions share the same external dependency
- **Function-level** (inside the function body): dependencies vary within the file
- **None**: pure-shell files (builtins, keywords, parameter expansion only)

Do not add `requires` for bash builtins (`printf`, `read`, `test`, etc.), shell
keywords (`if`, `while`, `case`, etc.), shellac functions from other modules
(use `include` for those), or words appearing only in string literals.

Bash version tokens: `requires BASH4` (assoc arrays, mapfile, case `${,,}`/`${^^}`),
`requires BASH43` (namerefs: `local -n`, `declare -n`).

### Self-reference

Use native primitives inside library code — not shellac wrappers:

- `command -v tool >/dev/null 2>&1` — not `is_command`
- `[[ -n "${var}" ]]` — not `var_is_set`
- `typeset -f name >/dev/null 2>&1` — not `is_function`

Permitted exceptions to the self-reference rule:
- `requires` — infrastructure, always permitted
- `include` — permitted when a library has a genuine functional dependency on
  another module (e.g. `crypto/uuid.sh` needs `time/epoch`); not a licence to
  pull in convenience wrappers

### Compartmentalisation

Each library file must be self-contained.  Do not call other shellac library
functions from within a library function — use `include` at the consumer level.
This keeps individual functions extractable and avoids dependency chains.

Permitted exceptions: `requires` (infrastructure) and `include` when a genuine
inter-module dependency exists.  `core/stdlib.sh` is a manifest file by design
and consists almost entirely of `include` calls — do not treat it as a model
for ordinary library files.

### Documentation

Public functions use shdoc annotations:

```bash
# @description One-line summary. Continuation lines indented with three spaces.
#
# @arg $1 string Description
# @arg $2 int    Description (optional)
#
# @example
#   my_function foo    # => expected output
#
# @stdout What is printed
# @exitcode 0 Success
# @exitcode 1 Failure
my_function() {
```

Private/internal functions: `# @internal` instead of `# @description`.

### Attribution

When adapting code from a third-party source, add a comment in the file:

```bash
# Adapted from ProjectName (LICENSE) https://url
```

And add an entry to `NOTICE.md` under the appropriate section.

### Shellcheck

All library files must be shellcheck-clean.  Any `# shellcheck disable=SCXXXX`
directive must be accompanied by a comment explaining why it is correct to
suppress that warning.

### Testing

Tests live in `test/bats/` and use bats-core.  Run the full suite with:

```bash
bats test/bats/
```

New functions need tests.  Existing tests must continue to pass.

### Discovery

Before adding a new function, check whether it already exists:

```bash
shellac modules                   # list all modules
shellac info <module>             # list libraries and functions in a module
shellac info <function>           # full documentation for a function
shellac provides <function>       # which library defines a function
```
