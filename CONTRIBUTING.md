# Contributing

Contributions are welcome!

This file documents the conventions and standards for contributing to shellac.
A companion file, [CLAUDE.md](CLAUDE.md), covers the same ground in a compact
format intended for use with [Claude Code](https://claude.com/claude-code) —
if you work with AI-assisted tooling, drop that file into your session and the
rules will be applied automatically.  It is also a useful quick-reference if
you find this document too long to skim.

## License

Any contributed code that is accepted into this repo will be published under the same license as the repo i.e. Apache 2.0 License.  You may choose to submit code under a compatible license like MIT.

I realise that some people might have issues with the license selection.  If you're contributing modules or functions that aren't already covered, and you want to use a different license that you don't feel is compatible, consider instead hosting them on your own github repo and sending me a link.  I'll find somewhere to share it here and promote it.

It might be nice in the future to have a very simple library fetch mechanism.  This would grab a simple manifest file from this repo, maybe perform some simple tasks based on the manifest, but ultimately its purpose would be to fetch any non-core libraries and place them into `SH_LIBPATH`.  What to call it though?  Something like `pip`?  How about... Shell Library Into Place or `slip`?

Whichever way you go, please do declare a FOSS license, otherwise potentially restrictive and messy Copyright rules apply by default.

### License Header

If you wish to contribute code under a compatible license, please include a license header in your file(s) and update [NOTICE](NOTICE.md).  If you wish to defer to the project's license, please include the contents of [license_header](license_header) at the top of your file(s).

## Third party code

Any code imported from another project or site must use a compatible license such as MIT.  Attribution will be given and tracked in [NOTICE](NOTICE.md).

### Code copied from websites

Code that is published on a website is almost always the copyright of its author, or the website owner, depending on the site's terms and conditions.  Copyright is also automatic from the moment a work is created, and does not need a copyright declaration (although having one does help).  Blindly copying and pasting code is, therefore, a copyright violation.

Please do not copy code from websites unless they have an explicit license statement detailing a compatible license, OR you have express written permission from the copyright holder to re-use their code in a way that is compatible with, or directly under, the terms of a compatible license.

Some reference terms and conditions:

* https://www.ycombinator.com/legal/ (search for the word "copyright")
* https://www.redditinc.com/policies/user-agreement-september-12-2021 (Section 05 "Your Content")
* https://slashdotmedia.com/terms-of-use/ (End of Section 6 and all of Section 7)
* https://docs.github.com/en/github/site-policy/github-terms-of-service#d-user-generated-content
* https://stackoverflow.com/help/licensing (Nice and simple)

See also: https://tosdr.org/

Simply emailing the author of a copyrighted material, introducing yourself, explaining your desired usage of their material, and asking them politely to consider a FOSS/OSI license will often result in positive reciprocation.

## Code of Conduct

See [CODE_OF_CONDUCT](CODE_OF_CONDUCT.md)

## How to contribute

This isn't going to be an exhaustive Git or GitHub how-to.  That's documented far better elsewhere.

First, if you have larger changes in mind, [open an Issue](https://github.com/rawiriblundell/shellac/issues/new) and let's discuss it.

If we're happy with the direction, or if you're going to submit something smaller, the next steps are:

1. Create a new branch off `main`: `git checkout -b my_new_feature`
2. Work on your changes.  Prefer smaller, focused commits over large ones — they're easier to review and easier to trace later.
3. Submit a Pull Request with a brief explanation of what you're submitting and why.

## Linting

All code must be parsed through [shellcheck](https://www.shellcheck.net/).

Be aware that while Shellcheck is an excellent tool, it's not perfect.  It can and does produce false positives.  If you do come across a scenario where it is wrong, you can disable an alert by using a `disable` directive.

```bash
# This function is sourced outside of this library, where it does parse args
# shellcheck disable=SC2120
foo() {
```

Any time you use a `shellcheck disable` directive, you must also accompany it with a comment justifying its use.

## Portability

This project aims for portability.  Not [strictly portable](https://www.gnu.org/software/autoconf/manual/autoconf-2.60/html_node/Portable-Shell.html) by any measure, but portable enough to refactor up or down the scale when needed.

Fundamentally speaking, our baseline is POSIX, plus named arrays as a minimum.  But let's not beat around the bush: `bash` is going to be the first-class citizen, and other shells?  Not so much.

`echo` is a portability nightmare.  Prefer `printf` instead.

`ksh` is actually a very good shell that is quietly installed in far more places than you'd expect, so consider targeting that.  If it runs in `ksh`, it'll likely run in `bash`.

Ubuntu's [DashAsBinSh](https://wiki.ubuntu.com/DashAsBinSh) wiki page can give you some ideas on more portable scripting, and `dash` is a readily available shell that you can test your code within.  Do be aware that `dash` is more restrictive than our target.

## Coding Style

Style references in rough priority order:

1. The rules below — these take precedence
2. [ChromiumOS Shell Style Guide](https://chromium.googlesource.com/chromiumos/docs/+/HEAD/styleguide/shell.md)
3. [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

### Formatting

Two or four spaces per indent level — pick one and stay consistent within a file.  Hard tabs are not acceptable.

Aim for 80 characters per line; 120 is the hard limit.

`do` and `then` go on the same line as their control construct:

```bash
for file in ./*; do
    ...
done

if [[ -n "${var}" ]]; then
    ...
fi
```

Long pipelines split at the pipe character, which stays at the end of each line:

```bash
some_command |
    second_stage |
    third_stage
```

### Variables

All variables use `lower_snake_case`.  Never camelCase.  `UPPER_CASE` is reserved for environment variables and shell builtins (`PATH`, `HOME`, `RANDOM`, etc.) — collisions with those cause subtle, hard-to-trace bugs.

Always use curly braces: `"${variable}"` not `"$variable"`.  The exception is inside `$(( ))` arithmetic, where `$(( time + 10 ))` is fine.

Always quote variable expansions and command substitutions: `"${var}"` and `"$(command)"`.  Unquoted variables are word-split and glob-expanded, which is almost never what you want.

Use descriptive names.  `${block_device}` is a name; `${f}` is not.  Single-character names are acceptable only for C-style loop counters (`i`) and shell special parameters (`$1`, `$#`, `$?`).

`for i in ...` loops are expressly discouraged — use `for file in`, `for item in`, `for host in`, etc.  Reserve `i` for C-style `for (( i=0; i<count; i++ ))`.

#### Scoping

Shell has three pseudo-scopes worth keeping in mind:

- **Environment** (`UPPER_CASE`) — `$PATH`, `$HOME`, shell builtins.  Don't create new uppercase variables unless you intend them to live in the environment.
- **Script** (`lower_snake_case`) — script-level variables.
- **Function / local** (`_lower_snake_case`) — variables local to a function, prefixed with an underscore to signal they are private to that function.

#### Local variables

All library functions must declare variables with `local`.  Always declare and assign on separate lines — combining them with `local var="$(cmd)"` discards the exit code of the command:

```bash
# Right
my_func() {
    local _name
    local _result
    _name="${1}"
    _result="$(some_command)"
}

# Wrong — the exit code of some_command is lost
my_func() {
    local _result="$(some_command)"
}
```

#### Constants

Declare first, then make readonly on a separate line:

```bash
config_file="/etc/myapp/config"
readonly config_file
```

### Output

Never use `echo`.  Use `printf` instead — `echo`'s behaviour across shells and its `-n`/`-e` flags are not portable.

Always include `--` after the format string:

```bash
printf -- '%s\n' "${var}"      # right
printf '%s\n' "${var}"         # wrong — missing --
```

This applies inside pipelines, subshells, and fallback branches too — no exceptions.

Never use backticks for command substitution.  Use `$()`:

```bash
result="$(some_command)"      # right
result=`some_command`         # wrong — doesn't nest, harder to read
```

### Arithmetic

Use `$(( ))` for all arithmetic.  Never `let` or `expr`:

```bash
(( count += 1 ))              # right
result=$(( a + b ))           # right
let count++                   # wrong
result=$(expr "$a" + "$b")    # wrong — expr is an external command
```

### Functions

Function names use `lower_snake_case` following a `<module>_<noun>` convention.  See [naming conventions](docs/naming-conventions.md) for the full rationale.

Never use the `function` keyword — it is non-portable and obsolete:

```bash
my_function() {               # right
    ...
}

function myFunction() {       # wrong
    ...
}
```

Private/helper functions that are not part of the public API start with a single underscore: `_my_helper()`.

For functions that need strong variable isolation (e.g. they `cd` and must not affect the caller's working directory), use subshell syntax:

```bash
isolated_task() (
    cd /some/directory || return 1
    do_work
)
```

### Conditionals

Use `[[` for all bash conditionals.  Use `[` only when writing for POSIX `sh`.

Use `=` for string equality (not `==`).  For numeric comparisons, always use `(( ))` — never `-lt`, `-gt`, `-eq` inside `[[`:

```bash
[[ "${a}" = "${b}" ]]         # string equality — right
(( a > b ))                   # numeric comparison — right
[[ a -gt b ]]                 # numeric inside [[ — wrong
```

Be explicit with string tests:

```bash
[[ -z "${var}" ]]             # preferred — clearly "zero length"
[[ -n "${var}" ]]             # preferred — clearly "non-zero length"
[[ "${var}" ]]                # valid but less explicit
```

Prefer `case` over `[[ =~ ]]` regex matching where pattern matching suffices — it is faster and more portable.

### Case statement formatting

This exact format is required — opening `(` on the pattern line, `;;` vertically aligned with it:

```bash
case "${variable}" in
    (option1)
        # commands
    ;;
    (option2|option3)
        # commands
    ;;
    (*)
        # default
    ;;
esac
```

Always include a `(*)` default case unless there is a clear reason not to.

### Pipelines and loops

Never pipe into a `while read` loop if the variables inside need to persist — pipes create a subshell, so those variables are discarded when the pipe ends:

```bash
# Wrong — $count is 0 after the loop
some_command | while read -r line; do
    (( count++ ))
done

# Right — process substitution keeps variables in scope
while read -r line; do
    (( count++ ))
done < <(some_command)
```

Never use bare `*` for glob expansion — files starting with `-` will be misinterpreted as options.  Use `./*`:

```bash
for file in ./*; do ...        # right
for file in *; do ...          # wrong
```

### Error handling

Check return codes explicitly.  Do not rely on `set -e` or `set -euo pipefail` — see [The Unofficial Strict Mode](#the-unofficial-strict-mode) below for why.

All error messages, warnings, and diagnostics go to stderr:

```bash
printf -- '%s\n' "Error: something failed" >&2
return 1
```

Idiomatic guard patterns:

```bash
if ! command_that_might_fail; then
    printf -- '%s\n' "Error: operation failed" >&2
    return 1
fi

# Inline for simple cases
cd /target || { printf -- '%s\n' "cd failed" >&2; exit 1; }
```

Use parameter expansion for default values rather than `if` blocks:

```bash
: "${foo:=default}"           # assign default if unset or empty
: "${foo=default}"            # assign default only if unset
```

### Idempotence

Scripts should be safe to run more than once.  Check state before making changes:

```bash
# Wrong — appends a duplicate entry on every run
printf -- '%s\n' "nameserver 1.2.3.4" >> /etc/resolv.conf

# Right
ns_line="nameserver 1.2.3.4"
if ! grep -qF "${ns_line}" /etc/resolv.conf; then
    printf -- '%s\n' "${ns_line}" >> /etc/resolv.conf
fi

mkdir -p /opt/myapp            # right — idempotent
mkdir /opt/myapp               # wrong — fails on second run
```

### Security

- Never log sensitive data (passwords, keys, tokens, PII)
- Never use `eval` — if eval is the answer, you are asking the wrong question
- Never use `which` — use `command -v`
- Never use SUID/SGID on shell scripts — use `sudo` for elevation
- Always use `--` to separate options from filenames: `rm -- "${file}"`
- Validate and sanitize all external input

### Compartmentalisation

Each library file should be as self-contained as possible.  Don't call other shellac library functions from within a library function — use `include` at the consumer level instead.  This keeps individual functions extractable and avoids dependency chains that make the codebase harder to reason about.

There are two permitted exceptions:

- **`requires`** — infrastructure, always permitted anywhere in a library file.
- **`include`** — permitted within a library file when there is a genuine functional dependency that cannot be inlined (e.g. `crypto/uuid.sh` depends on `time/epoch`, `sys/hogs.sh` aggregates `sys/cpuhogs`, `sys/memhogs`, and `sys/swaphogs`).  It is not a licence to pull in convenience wrappers; use it only when the library genuinely cannot function without the other.

`core/stdlib.sh` is a special case — its entire purpose is to be an include manifest, so it consists almost entirely of `include` calls by design.

## Library structure

Shellac organises code in a three-level hierarchy: **module** (directory) → **library** (`.sh` file) → **function**.  See [docs/structure.md](docs/structure.md) for the full explanation.

When adding a new library file, include a sentinel at the top to prevent double-sourcing:

```bash
[ -n "${_SHELLAC_LOADED_<module>_<library>+x}" ] && return 0
_SHELLAC_LOADED_<module>_<library>=1
```

The sentinel name follows the file path with slashes and hyphens replaced by underscores and the `.sh` extension removed.  For example, `net/cidr.sh` → `_SHELLAC_LOADED_net_cidr`.

You can browse the existing library structure using the shellac CLI:

```bash
shellac modules                   # list all modules
shellac info <module>             # list libraries and functions in a module
shellac info <module/library>     # list functions in a single library
shellac info <function>           # full documentation for a function
shellac provides <function>       # which library defines a function
```

## Documenting functions

Public functions must be documented with shdoc annotations immediately above the function definition:

```bash
# @description One-line summary. Continuation lines are indented with three
#   spaces and a hash.
#
# @arg $1 string Description of the first argument
# @arg $2 int    Description of the second argument (optional)
#
# @example
#   my_function foo    # => expected output
#
# @stdout What the function prints to stdout
# @exitcode 0 Success
# @exitcode 1 Failure condition
my_function() {
    ...
}
```

Private/internal functions use `# @internal` instead of `# @description` and are suppressed from `shellac info` and `shellac functions` output.

## Testing

Tests live in `test/bats/` and use the [bats-core](https://github.com/bats-core/bats-core) framework.

Run the full suite from the repo root:

```bash
bats test/bats/
```

All submissions should include tests for new functions or behaviour.  Existing tests must continue to pass.  The `lint.bats` file runs shellcheck across all library files automatically — new code must be shellcheck-clean or include a justified `# shellcheck disable` directive.

## Shellac library rules

### `requires` declarations

Every library file must declare its external command dependencies with `requires`.  Placement depends on the file's structure:

**Library-level** (after the sentinel, before any function definitions): use when every function in the file shares the same external dependency, or the file is single-purpose and useless without that tool.  Example: `calc.sh` always needs `bc`.

**Function-level** (inside the function body): use when functions in the same file have different external dependencies, or when a significant portion of the file has no external dependencies at all.

**No `requires`**: pure-shell files — parameter expansions, arithmetic, and builtins only.

Do not add `requires` for:
- Bash builtins: `printf`, `read`, `cd`, `test`, `kill`, `wait`, etc.
- Shell keywords: `if`, `while`, `case`, `do`, `then`, `in`, `esac`, etc.
- Shellac functions from other modules (use `include` for those instead)
- Words that appear only in string literals or comments

Bash version tokens are supported: `requires BASH4` (associative arrays, `mapfile`, case `${,,}`/`${^^}`), `requires BASH43` (namerefs: `local -n`, `declare -n`).

The `musings.md` entry on `requires` placement documents the full rationale and edge cases.

### Self-reference

Library files must not call shellac wrappers where a native shell or POSIX primitive does the same job:

- `command -v tool >/dev/null 2>&1` — not `is_command tool`
- `[[ -n "${var}" ]]` — not `var_is_set`
- `typeset -f name >/dev/null 2>&1` — not `is_function`

`requires` itself is infrastructure and is explicitly permitted as a cross-library call.

### Attribution

When adapting code from a third-party source, add a comment directly in the file:

```bash
# Adapted from ProjectName (LICENSE) https://url
```

And add an entry to `NOTICE.md` under the appropriate license section listing which files and functions were derived from that source.

## The Unofficial Strict Mode

There is a lot of advice on the internet to "always use The Unofficial Strict Mode."

It is usually presented by its advocates as a brilliant one-time invocation that will magically fix every shell scripting issue.  Typically written as:

```bash
set -euo pipefail
```

The Unofficial Strict Mode is textbook [Cargo Cult Programming](https://en.wikipedia.org/wiki/Cargo_cult_programming), and developers with less shell experience tend to copy and paste it, probably because the name gives them the illusion that it's some kind of `use strict`, which it isn't.  It's potentially more like `use chaos`.  It is non-portable, even within `bash` itself — the behaviours of its various components have changed across `bash` versions.  It replaces a set of well-known and understood issues with a set of less well-known and less-understood ones, and gives a false sense of security.  Newcomers to shell scripting also fall into the trap of believing the claims of its advocates, to their potential peril.

`errexit`, `nounset` and `pipefail` are imperfect implementations of otherwise sane ideas, and unfortunately they often amount to unreliable interfaces that are less familiar and less understood than simply living without them and curating defensive scripting habits.  It's perfectly fine to *want* them to work as advertised, and I think we all would like that, but they don't, and therefore shouldn't be recommended so blindly, nor advertised as a "best practice" — they aren't.

Some light reading into the matter:

* http://mywiki.wooledge.org/BashFAQ/105
* http://mywiki.wooledge.org/BashFAQ/112
* https://mywiki.wooledge.org/BashPitfalls#set_-euo_pipefail
* https://www.in-ulm.de/~mascheck/various/set-e/
* https://lists.nongnu.org/archive/html/bug-bash/2017-03/msg00171.html
* https://gist.github.com/dimo414/2fb052d230654cc0c25e9e41a9651ebe (i.e. `set -u` is an absolute disaster)
* https://www.reddit.com/r/bash/comments/5zdzil/shell_scripts_matter_good_shell_script_practices/
* https://www.reddit.com/r/bash/comments/5ddvd2/til_you_can_turn_tracing_x_on_and_off_dynamically/da3xjkk/
* https://www.reddit.com/r/commandline/comments/g1vsxk/the_first_two_statements_of_your_bash_script/fniifmk/
* https://www.reddit.com/r/commandline/comments/4b3cqu/use_the_unofficial_bash_strict_mode_unless_you/
* https://www.reddit.com/r/programming/comments/25y6yt/use_the_unofficial_bash_strict_mode_unless_you/
* https://www.reddit.com/r/programming/comments/4daos8/good_practices_for_writing_shell_scripts/d1pgv4p/
* https://bean.solutions/i-do-not-like-the-bash-strict-mode.html
* https://www.mulle-kybernetik.com/modern-bash-scripting/state-euxo-pipefail.html
* https://news.ycombinator.com/item?id=8054440
* http://www.oilshell.org/blog/2020/10/osh-features.html
* https://fvue.nl/wiki/Bash:_Error_handling

Now don't get me wrong: I recognise and genuinely like the *intent* behind the Unofficial Strict Mode.  But its subcomponents are so broken that the use of this mode often causes more trouble than it's worth.

And if you look at the [original blog post](https://redsymbol.net/articles/unofficial-bash-strict-mode/) describing it, note that more than half of the page is dedicated to documenting workarounds for its flaws.

A number of other library/framework/module projects use and advocate for it.  This project will not do that.

This project will nonetheless provide the capability via a library named `strict.sh`.

## Questions?

If something in this document is unclear, or you're unsure whether a proposed change fits the project, [open an issue](https://github.com/rawiriblundell/shellac/issues/new) and ask.  There are no stupid questions.
