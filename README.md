# SHELLAC

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/shellac-dark.png">
    <img alt="SHELLAC" src="docs/images/shellac-light.png">
  </picture>
</p>

The missing library ecosystem for shell

## Install

```bash
git clone https://github.com/rawiriblundell/shellac /opt/shellac
source /opt/shellac/bin/shellac
shellac init
```

No `curl | bash`. No package manager. No build step. `shellac init` detects
whether you have write access to `/etc/profile.d/` and configures a
system-wide or per-user install accordingly, reporting every change it makes.

## TL;DR

```bash
#!/usr/bin/env bash

# Load the shellac framework
source shellac 2>/dev/null || {
  printf -- '%s\n' "shellac not found - https://github.com/rawiriblundell/shellac" >&2
  exit 1
}

# Import the function libraries that shellac provides
# Without a given extension, ".sh" is assumed
include sys/os
# Give a specific extension to load a shell-specific lib
include utils/git.zsh
# Or, if you have a full path for whatever reason
include /opt/mycompany/lib/company_lib.sh
# Or just load all libraries within a module
include text

# Check that we have everything we need including shell version, commands and vars
# This means self-documenting code and fail-fast are handled in one line
requires BASH51 git jq curl osstr=Linux

# Lazy-load a config file in case that's something you need
wants /opt/secrets/squirrels.conf
```

## What does it do?

This project adds a library ecosystem for shell scripts.

`shellac` bootstraps a few environment vars, most importantly:

* `SH_LIBPATH` - this is a colon-separated list of library paths, just like `PATH`
* `SH_LIBPATH_ARRAY` - the same as above, just in an array
* `SHELLAC_LOADED` - sentinel variable set when `shellac` is sourced, preventing re-initialisation
* `_SHELLAC_LOADED_<category>_<name>` - per-library sentinel variables set when each library is sourced, preventing duplicate loads

It adds the following functions:

### `include`

Similar to its `python` cousin `import` and its `perl` cousin `use`, this is intended for loading libraries.

Both full paths and relative paths (resolved via `$SH_LIBPATH`) are supported:

```bash
include /opt/contoso/lib/sh/monolithic.sh # loads /opt/contoso/lib/sh/monolithic.sh
include text/padding                      # resolved from SH_LIBPATH
include text                              # loads every library in the text/ module
```

### `requires`

This function serves multiple purposes.  A lot of shell scripts:

* just *assume* that binaries are present
* don't fail nicely if these binaries aren't
* don't really serve themselves well in terms of internal documentation
* don't fail early

`requires()` fixes all of that.

It works through multiple items so you only need to declare it once.  It would typically be used to check for the existence of commands in `PATH` like this:

```bash
requires git jq sed awk
```

But it can also check that pre-requisite variables are as desired (or "as required", you might say), for example:

```bash
requires EDITOR=/usr/bin/vim
```

It can also check for a particular version of `bash`, for example to require `bash 4.1` or newer:

```bash
requires BASH41
```

It also accepts full paths to executables, config files, and libraries on `SH_LIBPATH`.

By dealing with this at the very start of the script, we ensure that we fail early.  It abstracts away messy `command -v`/`which`/`type` tests, and when someone reads a line like:

```bash
requires BASH42 git jq storcli /etc/multipath.conf
```

It's clear what the script *requires* in order to run i.e. it's self-documenting code.

### `wants`

Sources a file if it exists; silent no-op if not.  A lazy-loader for config files.

Some scripts contain logic to detect environmental facts — OS version quirks, available tools, site-specific paths — that rarely change between runs.  Wrapping that detection behind a variable and caching the result in a config file means subsequent invocations skip straight past it.  Load that config file with `wants` at the top of your script and the short-circuit is free.

### `shellac`

The `shellac` command provides a management interface for the framework.

**Discovery** — explore what is available before you `include` it:

```bash
shellac modules               # list all modules
shellac libraries             # list all libraries across SH_LIBPATH
shellac functions             # list all available functions
shellac info text             # show functions in the text/ module
shellac info str_toupper      # full documentation for a function
shellac provides str_toupper  # which library file defines a function
```

**Installing third-party libraries:**

```bash
# From a local file — installs to ~/.local/lib/sh/ (or /usr/local/lib/sh/ as root)
shellac add-lib /tmp/contoso.sh

# Explicit target directory
shellac add-lib /tmp/contoso.sh /opt/mycompany/lib/sh

# From a GitHub, GitLab, or Bitbucket raw URL — namespaced under the repo owner
shellac add-lib https://raw.githubusercontent.com/contoso/lib/main/pandas.sh
# installed to: ~/.local/lib/sh/contoso/pandas.sh
# load with:    include contoso/pandas

# From any other URL — namespaced under "external"
shellac add-lib https://example.com/pandas.sh
# installed to: ~/.local/lib/sh/external/pandas.sh
# load with:    include external/pandas

# Override the namespace with -m (useful for self-hosted forges)
shellac add-lib -m contoso https://mygitea.example.com/contoso/pandas.sh
# installed to: ~/.local/lib/sh/contoso/pandas.sh
# load with:    include contoso/pandas

# Remove an installed library
shellac rm-lib ~/.local/lib/sh/contoso/pandas.sh
```

`add-lib` prompts for confirmation before installing.  Set `SHELLAC_INSTALL_YES=1`
to bypass the prompt in automation.  The target directory is registered in
`SH_LIBPATH` automatically so the installed library is immediately discoverable.

**Path management** — if you maintain libraries outside the default search paths:

```bash
shellac add-libpath /opt/mycompany/lib/sh   # register a custom library directory
shellac rm-libpath  /opt/mycompany/lib/sh   # deregister it
```

## Why

Shell is the first language most *nix practitioners reach for, the go-to for sysadmins, and often the right tool for the job.  Yet most shell scripts are written as if no ecosystem exists — because for the most part, it doesn't.  There's no `pip` or `CPAN` for `bash`, no standard library to lean on.  So most scripts copy and paste the same sub-optimal code from StackOverflow, repeat the same anti-patterns, and carry the same bugs, over and over.

The people quickest to reach for Python or Ruby are often unaware that what they're really reaching for is the library ecosystem those languages carry.  The language itself isn't the point — the abstraction is.  Shell can have that too.

A concrete example — converting a string to uppercase:

```bash
s.upper()                                            # Python
s.upcase                                             # Ruby
strings.ToUpper(s)                                   # Go
s.toUpperCase()                                      # JavaScript

"${var^^}"                                           # bash 4+ only; cryptic to anyone who hasn't memorised parameter expansion
printf '%s' "${var}" | tr '[:lower:]' '[:upper:]'    # portable; requires knowing tr is a character translator, not a string function

str_toupper "${var}"                                 # shellac
```

Every other language names the operation.  Shell gives you a sigil or a pipeline through a utility designed for something else.  `str_toupper` does what it says.  That's the difference a library makes.

There are existing shell library projects, but most have at least one of these problems: restrictive licensing, Linux-only, so deeply self-referential the code is unreadable, or naming conventions that make you feel like you're writing enterprise Java (`____awesome__shell_library____+5000____class::::text__split__` is hyperbole, but not by much).

This project aims for something simpler: a permissively licensed, broadly portable library of solid shell functions, loadable on demand, with sane names, and only a sparing use of self-references.

## Why use libraries and not just a package of scripts

The main reasons for using functions over standalone scripts are:

* Once loaded into memory, functions are called directly without forking a new process.  For anything called repeatedly, that adds up.
* Functions impose structure — code is organised into named, testable units rather than a flat sequence of commands.

In this project, libraries are simply collections of functions.

### Story time

At a former job I inherited a slow shell script — a very long pipeline of chained `grep -v` calls.  I refactored it: put the filter strings in an array, built a function named `array::join()` to join them into a single `grep -Ev` pattern.  Cleaner, documented, measurably faster.  The PR was not well received.  Apparently the function was proof that shell is the language of the Nazis; I had brought shame upon the company, and so forth.

Had my PR instead been:

```bash
+ include arrays.sh

+ strings_to_filter=(
+    string-1
+    string-2
+    ... (many lines later)...
+    string-n
+ )

+ filter_string=$(array::join '|' "${strings_to_filter[@]}")
+ grep -Ev "${filter_string}" "${some_file}"
```

There would have been no controversy at all.

If you're a Pythonista or a `perl` guru: when did you last read the source code of a library you depend on?  And when did you last include the lines-of-code of said libraries into your lines-of-code arguments?  "Approximately never" is the honest answer.  QED.

## Further reading

* [Library structure](docs/structure.md) — module/library/function hierarchy explained
* [Naming conventions](docs/naming-conventions.md) — why functions are named the way they are
* [Contributing](CONTRIBUTING.md) — coding standards and how to submit changes
* [Notice](NOTICE.md) — third-party attributions and licences

## License

[Apache 2.0](LICENSE)
