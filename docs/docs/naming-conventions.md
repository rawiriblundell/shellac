This document describes the naming standard that has emerged across
`lib/sh/`.

---

## Core principle

The module prefix is the namespace. Everything after it describes
*what* the function does, not *that it retrieves something*. `get_`
is not a verb — it is noise.

This mirrors the pattern used in modern standard libraries:

| Language | Local read | Network I/O |
|---|---|---|
| Python psutil | `net_if_addrs()` | — |
| Node.js | `os.networkInterfaces()` | `dns.lookup()` |
| Go net | `net.Interfaces()` | `net.LookupHost()` |

The shell equivalent: plain noun for local state, descriptive infix
for I/O operations.

---

## Patterns

### `<module>_<noun>` — local passive read

Reads local system state. No network calls, no blocking I/O. Failure
means the platform is unusual or a required tool is absent.

```bash
sys_shell        # what shell is running?
sys_mounts       # what is mounted?
net_ip           # local IP address
net_mac          # MAC address of primary interface
net_dns          # configured DNS servers
```

### `<module>_<noun>_<attr>` — attribute of a domain

Sub-functions under a domain noun. Always callable directly; also
reachable via the dispatcher.

```bash
sys_cpu_cores
sys_cpu_mhz
sys_mem_total
sys_mem_percent
sys_swap_used
sys_info_manufacturer
sys_info_serial
```

### `<module>_<noun>` as dispatcher

The plain noun form doubles as the dispatcher for its attribute
functions. With no argument it prints a summary. With a flag or
subcommand it routes to the appropriate helper.

```bash
sys_cpu                    # summary: manufacturer, model, mhz, count
sys_cpu cores              # single attribute
sys_mem total -M           # single attribute with unit flag
sys_info                   # all: manufacturer, model, serial, bios
sys_info --serial          # single attribute
sys_hogs                   # all three hog reports
sys_hogs mem 20            # single report with line count
```

The subcommand style (`sys_cpu cores`) is used where the noun has
many attributes and a flag would be unwieldy. The flag style
(`sys_info --serial`) is used where the domain is small or the
attributes are heterogeneous.

### `<module>_query_<noun>` — active outbound query

Makes a network call. Failure modes are qualitatively different from
local reads: firewalls, DNS, timeouts, service outages.

```bash
net_query_ip               # what is my public IP?
net_query_ipinfo 8.8.8.8   # geo/org metadata for an IP
net_query_port host 443    # is this port reachable?
net_query_http_code url    # HTTP status of a URL
```

#### net/ local vs query distinction

Functions in `net/` follow both patterns, which reflect a meaningful
difference in what the function does:

| Pattern | What it does | Examples |
|---|---|---|
| `net_<noun>` | Reads local system state — no network I/O | `net_ip`, `net_mac`, `net_dns` |
| `net_query_<noun>` | Makes an outbound network call | `net_query_ip`, `net_query_port`, `net_query_ipinfo` |

Local reads (`net_ip`, `net_mac`) fail only when the platform is unusual
or a required tool is absent. Network queries can fail because of
firewalls, DNS, timeouts, or service outages. Mixing them under a single
verb would obscure that difference.

`net_dns_resolve` is a deliberate exception: it fires a DNS query outbound
but lives in `dns.sh` as a DNS-domain operation rather than a general
query. If a full `net_query` dispatcher is ever built, it would route
internally to `net_dns_resolve`.

### `<module>_info_<attr>` — hardware identity

Hardware identity attributes are a special case of `_attr` where the
parent noun is `info` — the machine's self-description. These live in
`sys/info.sh` and are dispatched by `sys_info`.

```bash
sys_info_manufacturer
sys_info_model
sys_info_serial
sys_info_bios
```

### `svc_<verb>` — service control

Service lifecycle operations use a `svc_` prefix rather than `sys_`
because they are imperative (they *change* state) rather than
descriptive. The verb is mandatory.

```bash
svc_start nginx
svc_restart nginx
svc_status nginx
svc_enabled nginx
svc_active nginx
```

### `_<module>_<noun>` — internal helpers

Functions prefixed with `_` are private to their file. Not part of
the public API; may change without notice.

```bash
_cpuhogs_print_fmt
_mem_read
_mem_convert_kb
_swaphogs_get_proc_info
```

### `is_<condition>` — boolean predicates

Return 0 (true) or 1 (false). No output to stdout. Used in
conditionals.

```bash
is_aws
is_azure
is_debian_like
is_redhat_like
```

These have not yet been given a module prefix. Candidates:
`sys_is_aws`, `sys_is_azure`. Deferred.

### `str_*`, `text_*`, `line_*` — string, display, and stream operations

These three prefixes encode a meaningful distinction:

- **`str_`** — operates on a string value in memory. Input is an argument,
  output is a transformed value. Character-level. No terminal assumptions.
  `str_toupper`, `str_replace`, `str_ucfirst`, `str_snake_case`.
- **`line_`** — operates on a stream of lines. Input is stdin or a file,
  output is line-structured. `line_first`, `line_indent`, `line_filter`.
- **`text_`** — applies display or presentation formatting, typically for
  terminal output. ANSI colour and styling (`text_bold`, `text_fg`), layout
  (`text_center`, `text_wordwrap`). These functions assume a visual context.

The test: would this function make sense in a non-terminal, non-display
context? Case conversion — yes, `str_toupper`. Centering a line to terminal
width — no, `text_center`.

Functions that transform string values belong in `str_*` regardless of where
they were originally written. `text_*` aliases may be kept for backward
compatibility but are not canonical. Display-oriented wrappers around
`str_*` or `line_*` functions may carry `text_*` aliases where callers
would naturally reach for that prefix.

---

## File naming

Files follow the same noun-first rule: `<noun>.sh`, no `get_` prefix,
no verb. The filename should match the primary function or dispatcher
it contains.

```
sys/cpu.sh            → sys_cpu, sys_cpu_*
sys/mem.sh            → sys_mem, sys_mem_*, sys_swap, sys_swap_*
sys/info.sh           → sys_info, sys_info_*
sys/hogs.sh           → sys_hogs (dispatcher over cpuhogs/memhogs/swaphogs)
net/query.sh          → net_query_*
net/dns.sh            → net_dns, net_dns_resolve
fs/stat_file.sh       → fs_stat, fs_file_age, whoowns
fs/permissions.sh     → fs_permissions
units/temperature.sh  → celsius_to_fahrenheit, temp_convert, … (see exceptions)
units/permissions.sh  → octal_to_rwx, rwx_to_octal, permissions_convert
```

### Module layout patterns

When a module's functions fit naturally into a single file, name it
`base.sh`. The include then reads as `include <module>/base`, which
is unambiguous and avoids the tautological `include path/path` or
`include git/git`.

When the module splits cleanly along read/write lines, use two files
named to reflect that split. The default pair is:

- **`inspect.sh`** — read-only queries, predicates, introspection.
  No state is modified.
- **`manage.sh`** — write operations, idempotent create/update/delete.

Use domain-appropriate names where something more expressive fits.
`users/query.sh` + `users/provision.sh` is clearer than
`users/inspect.sh` + `users/manage.sh` in that context. The
`inspect/manage` pair is the fallback when nothing better presents
itself.

Literal `read`/`write`, verb-only names (`get`, `set`), and HTTP
methods (`GET`, `POST`) are all rejected — they are either too close
to reserved words or carry the wrong connotations.

```
git/base.sh           → single-file module; all git_* functions
path/base.sh          → single-file module; all path_* functions
users/query.sh        → read-only: user_uid, user_gid, user_accounts …
users/provision.sh    → write/idempotent: ensure_user_exists, ensure_group_exists …
```

---

## Sentinel variables

Sentinel variables follow the file path, not the function names:

```bash
_SHELLAC_LOADED_<dir>_<filename_without_extension>
```

Examples:
```bash
_SHELLAC_LOADED_sys_cpu
_SHELLAC_LOADED_sys_info
_SHELLAC_LOADED_net_query
_SHELLAC_LOADED_net_dns
```

When a file is renamed or moved, the sentinel must be updated to
match the new path.

---

## Named exceptions

Some functions are exempt from the module-prefix rule where the prefix
would be tautological or the short form is clearly the better name.

| Function | File | Why exempt |
|---|---|---|
| `toarray` | `array/toarray.sh` | `array_toarray` reads as a stutter; the filename already provides the namespace |
| `mapfile` | `array/mapfile.sh` | Deliberate shadow of the bash builtin; must match the builtin name to act as a drop-in |
| `cpuhogs`, `memhogs`, `swaphogs` | `sys/*.sh` | Short, well-known names; `sys_cpuhogs` adds no clarity. `sys_hogs` is the namespaced entry point. |
| `celsius_to_fahrenheit`, `octal_to_rwx`, etc. | `units/*.sh` | The `<unit>_to_<unit>` pattern is self-describing; a module prefix adds nothing. `units_celsius_to_fahrenheit` is worse in every way. |
| `whoowns` | `fs/stat_file.sh` | `fs_whoowns` adds no clarity; the name reads as a natural English question. Thin wrapper over `fs_stat owner`. |
| `greet` | `misc/greet.sh` | `misc_greet` adds nothing; the function is a self-contained imperative with no attribute to qualify. |
| `validate_config` | `utils/validate_config.sh` | Parked pending a decision on where config validation belongs. May move to a `config/` module or gain a `util_` prefix in a future pass. |
| `secrets_genpasswd`, `secrets_genphrase` | `crypto/genpasswd.sh`, `crypto/genphrase.sh` | Password/passphrase generation lives in `crypto/` under the `secrets_*` sub-namespace (cf. Go `crypto/rand`, Python `secrets`). Short forms `genpasswd` and `genphrase` are kept as aliases. |
| `confirm` | `utils/prompt.sh` | Alias for `prompt_confirm`; kept for natural English readability and backwards compatibility. Lives alongside `prompt_response` and `prompt_password` in the prompt cluster. |
| `detect_type` | `core/types.sh` | Every language converges on `type()` or `typeof` for this concept. The shell builtin `type` is already taken (command lookup), making `detect_type` the closest available form. `core_detect_type` adds no clarity. |
| `readlist` | `array/readlist.sh` | Deliberately echoes the `readarray`/`mapfile` builtin naming. `array_readlist` would be a stutter. Defaults to `READLIST` as the target array, mirroring `mapfile`→`MAPFILE`. |
| `int` | `numbers/numeric.sh` | Alias for `num_parse`; equivalent to Go's `strconv.Atoi`. `num_int` would be a stutter; the short form is the universal cross-language name. |
| `is_integer`, `is_float`, `is_numeric`, `is_positive_integer` | `numbers/numeric.sh` | Backward-compatible aliases for `num_is_integer --regex`, `num_is_float --regex`, `num_is_numeric`, `num_is_positive_integer`. The `is_*` names are the canonical public predicates; `num_is_*` exposes the additional `--regex` flag. |

Note: `math_ceiling`, `math_floor`, `math_round`, `math_trunc` (`numbers/rounding.sh`) use `math_` rather than `num_`. Python, Go, and JavaScript all converge on a `math` namespace for these operations; `num_` is the canonical project prefix but `math_` is the cross-language convention and wins here. The short forms (`ceiling`, `floor`, `round`, `trunc`) are kept as aliases.

Note: `sum` and `average` (`numbers/sum.sh`) are stream aggregators rather than unary math operations. No language puts these in a `math.*` namespace. They stay as named exceptions; `array_sum` in the array module handles the array case.

Note: `strict_euopipefail`, `strict_nowhitesplitting` (`core/`) are intentional exceptions. The project discourages `set -e` / `pipefail` patterns, but these are provided for users who want them. The `strict_` prefix is the namespace; no module prefix is added.

Note: `cmd_check`, `cmd_list` (`utils/cmd.sh`) use `cmd_` rather than `util_cmd_`. This is a deferred decision — `cmd_` reads naturally and is unambiguous, but may gain a `util_` prefix if the `utils/` module develops a broader convention. Revisit when other `utils/` functions are reviewed.

Note: functions in `units/` that read filesystem or system state are **not** exempt — those belong in the appropriate module. `get_permissions()` was moved to `fs/permissions.sh` as `fs_permissions()` for this reason. The boundary is: if the function converts between representations, it lives in `units/`; if it reads external state to produce a value, it belongs in `fs/`, `sys/`, or `net/`.

The test: if adding the prefix makes the name *longer without making it clearer*,
the short form is the right call.

---

## What we explicitly rejected

| Pattern | Reason |
|---|---|
| `get_<noun>` | POSIX/C legacy. No semantic value. Dropped everywhere. |
| `get_<domain>info_<attr>` | `info` infix is noise; the module prefix is sufficient context. |
| `net_get_<noun>` | PowerShell-style verbosity. The absence of `query_` already implies local/passive. |
| `<noun>::<verb>` | Double-colon namespace is not idiomatic shell. |
