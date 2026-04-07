Three real scripts, rewritten with shellac. Each rewrite is functionally
equivalent to the original — the goal is not to reimagine the logic but
to show what shellac handles so the script doesn't have to.

---

## Example 1: regen_knownhosts

A utility that safely regenerates `~/.ssh/known_hosts` after a key
rotation: pulls hosts from bash history, deduplicates, re-scans
fingerprints, and falls back to live SSH for hosts keyscan can't reach.
The shellac version is slightly longer due to the `include` preamble, but
the scaffolding (dependency checks, logging, random stamp generation) is
all gone from the script body.

---

<div markdown="block" style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;">

<div markdown="block">

**Original**

```bash
#!/bin/bash
# Regenerate your known_hosts file after rotating your keys

# --- Functions ---------------------------------------------------------------

# Build a candidate host list from bash history
_get_historical_hosts() {
    grep "^ssh " "${HOME}/.bash_history" |
        awk '{print $2}' |
        sort |
        uniq |
        grep -Ev -- '^-|ssh$|radius2\|^raw$'
}

# Print or add SSH fingerprints for one or more hosts
ssh-fingerprint() {
    local fingerprint
    local keyscanargs=()
    fingerprint="$(mktemp)"

    # Cleanup temp file on return
    trap 'rm -f "${fingerprint:?}"' RETURN

    # Prefer ed25519 where supported
    ssh -Q key 2>/dev/null | grep -q ed25519 &&
        keyscanargs=( -t "ed25519,rsa,ecdsa" )

    case "${1}" in
        (-a|--add|--append)
            shift 1
            ssh-keyscan "${keyscanargs[@]}" "${@}" > "${fingerprint}" 2>/dev/null
            [[ -s "${fingerprint}" ]] || return 1
            cp "${HOME}"/.ssh/known_hosts{,."$(date +%Y%m%d)"}
            sort -u "${fingerprint}" "${HOME}/.ssh/known_hosts.$(date +%Y%m%d)" \
                > "${HOME}/.ssh/known_hosts"
        ;;
        (''|-h|--help)
            printf -- '%s\n' \
                "Usage: ssh-fingerprint (-a|--add|--append) [hostnames]" >&2
            return 1
        ;;
        (*)
            ssh-keyscan "${keyscanargs[@]}" "${@}" > "${fingerprint}" 2>/dev/null
            [[ -s "${fingerprint}" ]] || return 1
            ssh-keygen -l -f "${fingerprint}"
        ;;
    esac
}

# --- Main --------------------------------------------------------------------

# Back up known_hosts with a random stamp so reruns don't collide
local rand_stamp
rand_stamp="$(LC_CTYPE=C tr -dc 'a-zA-Z0-9' < /dev/urandom \
    | fold -w 8 | head -n 1).$(date +%Y%m%d)"
cp "${HOME}/.ssh/known_hosts" "${HOME}/.ssh/known_hosts.${rand_stamp}"
printf -- '======> %s\n' "Backed up known_hosts to known_hosts.${rand_stamp}"

# Split into hashed and unhashed entries
grep  '|1|' "${HOME}/.ssh/known_hosts" \
    > "${HOME}/.ssh/known_hosts.hashed"
grep -v '|1|' "${HOME}/.ssh/known_hosts" |
    awk '{print $1}' |
    tr ',' '\n' \
    > "${HOME}/.ssh/known_hosts.unhashed"

# Resolve hashed entries by matching against bash history
if [[ -s "${HOME}/.ssh/known_hosts.hashed" ]]; then
    while read -r host; do
        if ssh-keygen -F "${host}" >/dev/null 2>&1; then
            grep -q "${host}" "${HOME}/.ssh/known_hosts.unhashed" ||
                printf -- '%s\n' "${host}" >> "${HOME}/.ssh/known_hosts.unhashed"
        fi
    done < <(_get_historical_hosts)
fi

# Merge unhashed list with history, deduplicate
sort -u "${HOME}/.ssh/known_hosts.unhashed" \
    <(_get_historical_hosts) \
    > "${HOME}/.ssh/known_hosts.sorted"

# Clear known_hosts and rebuild from sorted list
: > "${HOME}/.ssh/known_hosts"

while read -r target_host; do
    printf -- '======> %s\n' "Processing ${target_host}..."
    ssh-fingerprint --add "${target_host}" ||
        printf -- '%s\n' "${target_host}" >> "${HOME}/.ssh/failed_fingerprinting"
done < "${HOME}/.ssh/known_hosts.sorted"

# Second pass: attempt live SSH for hosts keyscan couldn't reach
if [[ -s "${HOME}/.ssh/failed_fingerprinting" ]]; then
    printf -- '%s\n' \
        "Working through fingerprint failures — this may take a while" >&2
    while read -r host; do
        if ! ssh -n -o ConnectTimeout=3 -o BatchMode=yes \
                -o StrictHostKeyChecking=accept-new "${host}" true; then
            printf -- '%s\n' \
                "${host}: unable to connect — manual intervention required" >&2
        fi
        grep -q "^${host}" "${HOME}/.ssh/known_hosts" &&
            printf -- '======> %s\n' "${host} added to known_hosts"
    done < "${HOME}/.ssh/failed_fingerprinting"
fi

printf -- '======> %s\n' "Done. Clean up ${HOME}/.ssh when you're satisfied:"
ls -1 "${HOME}/.ssh"
```

</div>

<div markdown="block">

**With shellac**

```bash
#!/bin/bash
# Regenerate your known_hosts file after rotating your keys

source shellac 2>/dev/null || {
    printf -- '%s\n' "shellac not found - https://github.com/rawiriblundell/shellac" >&2
    exit 1
}

include core/stdlib
include crypto/genpasswd

# Fail fast if required tools are absent
requires ssh ssh-keyscan ssh-keygen

# --- Functions ---------------------------------------------------------------

# Build a candidate host list from bash history
_get_historical_hosts() {
    grep "^ssh " "${HOME}/.bash_history" |
        awk '{print $2}' |
        sort |
        uniq |
        grep -Ev -- '^-|ssh$|radius2\|^raw$'
}

# Print or add SSH fingerprints for one or more hosts
ssh-fingerprint() {
    local fingerprint
    local keyscanargs=()
    fingerprint="$(mktemp)"

    # Cleanup temp file on return regardless of exit code
    trap 'rm -f "${fingerprint:?}"' RETURN

    # Prefer ed25519 where supported
    ssh -Q key 2>/dev/null | grep -q ed25519 &&
        keyscanargs=( -t "ed25519,rsa,ecdsa" )

    case "${1}" in
        (-a|--add|--append)
            shift 1
            ssh-keyscan "${keyscanargs[@]}" "${@}" > "${fingerprint}" 2>/dev/null
            [[ -s "${fingerprint}" ]] || return 1
            cp "${HOME}"/.ssh/known_hosts{,."$(date +%Y%m%d)"}
            sort -u "${fingerprint}" "${HOME}/.ssh/known_hosts.$(date +%Y%m%d)" \
                > "${HOME}/.ssh/known_hosts"
        ;;
        (''|-h|--help)
            warn "Usage: ssh-fingerprint (-a|--add|--append) [hostnames]"
            return 1
        ;;
        (*)
            ssh-keyscan "${keyscanargs[@]}" "${@}" > "${fingerprint}" 2>/dev/null
            [[ -s "${fingerprint}" ]] || return 1
            ssh-keygen -l -f "${fingerprint}"
        ;;
    esac
}

# --- Main --------------------------------------------------------------------

# Back up known_hosts with a random stamp so reruns don't collide
local rand_stamp
rand_stamp="$(secrets_genpasswd 8).$(date +%Y%m%d)"
cp "${HOME}/.ssh/known_hosts" "${HOME}/.ssh/known_hosts.${rand_stamp}"
log_info "Backed up known_hosts to known_hosts.${rand_stamp}"

# Split into hashed and unhashed entries
grep  '|1|' "${HOME}/.ssh/known_hosts" \
    > "${HOME}/.ssh/known_hosts.hashed"
grep -v '|1|' "${HOME}/.ssh/known_hosts" |
    awk '{print $1}' |
    tr ',' '\n' \
    > "${HOME}/.ssh/known_hosts.unhashed"

# Resolve hashed entries by matching against bash history
if [[ -s "${HOME}/.ssh/known_hosts.hashed" ]]; then
    while read -r host; do
        if ssh-keygen -F "${host}" >/dev/null 2>&1; then
            grep -q "${host}" "${HOME}/.ssh/known_hosts.unhashed" ||
                printf -- '%s\n' "${host}" >> "${HOME}/.ssh/known_hosts.unhashed"
        fi
    done < <(_get_historical_hosts)
fi

# Merge unhashed list with history, deduplicate
sort -u "${HOME}/.ssh/known_hosts.unhashed" \
    <(_get_historical_hosts) \
    > "${HOME}/.ssh/known_hosts.sorted"

# Clear known_hosts and rebuild from sorted list
: > "${HOME}/.ssh/known_hosts"

while read -r target_host; do
    log_info "Processing ${target_host}..."
    ssh-fingerprint --add "${target_host}" ||
        printf -- '%s\n' "${target_host}" >> "${HOME}/.ssh/failed_fingerprinting"
done < "${HOME}/.ssh/known_hosts.sorted"

# Second pass: attempt live SSH for hosts keyscan couldn't reach
if [[ -s "${HOME}/.ssh/failed_fingerprinting" ]]; then
    log_warn "Working through fingerprint failures — this may take a while"
    while read -r host; do
        if ! ssh -n -o ConnectTimeout=3 -o BatchMode=yes \
                -o StrictHostKeyChecking=accept-new "${host}" true; then
            warn "${host}: unable to connect — manual intervention required"
        fi
        grep -q "^${host}" "${HOME}/.ssh/known_hosts" &&
            log_info "${host} added to known_hosts"
    done < "${HOME}/.ssh/failed_fingerprinting"
fi

log_info "Done. Clean up ${HOME}/.ssh when you're satisfied:"
ls -1 "${HOME}/.ssh"
```

</div>

</div>

---

## What changed and why

**Loading shellac** — `source shellac` works because bash searches `PATH`
for bare names with no slash, and a standard shellac install puts `bin/`
on `PATH`. `bin/shellac` then self-locates `lib/sh` from its own path, so
no hardcoded install prefix is needed. If shellac is absent the script
fails immediately with a useful message rather than a cascade of
"command not found" errors.

**`include core/stdlib`** — the curated baseline: control flow, logging,
dependency checking, trap helpers, and more. Three of the four original
includes (`core/die`, `core/trap`, `utils/logging`) are already in
stdlib, so only `crypto/genpasswd` needs to be named separately.

**`requires`** — three tools are non-negotiable. Declaring them upfront
means the script fails with a clear message before touching anything,
rather than mid-run.

**`secrets_genpasswd 8`** — replaces the `tr | fold | head` pipeline.
Same result, readable at a glance.

**`warn` and `log_info` / `log_warn`** — replace ad-hoc `printf ... >&2`
calls. Log functions write to the right stream automatically, carry
consistent formatting, and can be silenced or redirected centrally.

The logic is otherwise unchanged — the rewrite is not a reimagining, just
a demonstration that shellac handles the scaffolding so the script can
focus on what it actually does.

---

## Example 2: gist_pull

A script that syncs all GitHub gists for a given user to local
directories. At 79 lines it is compact, but 22 of those lines are
hand-rolled `die()` and `requires()` functions — which are shellac
verbatim. With `core/stdlib` covering all three individual includes,
`net/query` adding a preflight connectivity check, and `get_url`
eliminated as an unnecessary wrapper, the script drops to 52 lines.

---

<div markdown="block" style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;">

<div markdown="block">

**Original**

```bash
#!/bin/bash
# Pull all the gists for a given user

#TO-DO: Identify local copies that have been deleted and sync

user="${1:?No github user defined}"
base_uri="https://api.github.com/users/${user}/gists"
gist_path="${2:-${HOME}/git/gists}"
gist_manifest="${gist_path}/manifest.json"

# Get the top level PID and setup a trap so that we can call die() within subshells
trap "exit 1" TERM
_self_pid="${$}"
export _self_pid

# shellcheck disable=SC2059
die() {
  [ -t 0 ] && _diefmt='\e[31;1m====>%s\e[0m\n'
  printf "${_diefmt:-====>%s\n}" "${0}:(${LINENO}): ${*}" >&2
  kill -s TERM "${_self_pid}"
}

requires() {
  local cmd err_count
  err_count=0
  for cmd in "${@}"; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
      err "${cmd} is required but was not found in PATH"
      (( ++err_count ))
    fi
  done
  (( err_count > 0 )) && exit 1
  return 0
}

get_url() {
  case "${1}" in
    (--save)  CURL_OPTS=( -O ); shift 1 ;;
  esac
  curl "${CURL_OPTS[@]}" -s "${1:?No URL defined}"
}

main() {
  requires curl jq

  mkdir -p "${gist_path}" || die "Could not create ${gist_path}"

  get_url "${base_uri}" > "${gist_manifest}"

  readarray -t gist_id_list < <(jq -r '.[].id' "${gist_manifest}")

  (
    cd "${gist_path}" || die "Could not enter ${gist_path}..."
    for gist_id in "${gist_id_list[@]}"; do
      printf -- '%s\n' "Syncing ${gist_id}..."
      gist_uri="https://gist.github.com/${gist_id}.git"
      [[ ! -d "${gist_id}" ]] && git clone "${gist_uri}"
      (
        cd "${gist_id}" || die "Could not enter ${gist_path}/${gist_id}"
        gist_filename=$(
          jq -r --arg gist_id "${gist_id}" '
            .[] |
              select(.id==$gist_id) |
              .files[].filename' "${gist_manifest}"
        )
        ln_target="${gist_path}/${gist_id}/${gist_filename}"
        ln_link="${gist_path}/${gist_filename}"
        ln -s "${ln_target}" "${ln_link}" >/dev/null 2>&1
      )
    done
  )
}

main "${@}"
```

</div>

<div markdown="block">

**With shellac**

```bash
#!/bin/bash
# Pull all the gists for a given user

#TO-DO: Identify local copies that have been deleted and sync

source shellac 2>/dev/null || {
    printf -- '%s\n' "shellac not found - https://github.com/rawiriblundell/shellac" >&2
    exit 1
}

include core/stdlib
include net/query

requires curl jq git

user="${1:?No github user defined}"
base_uri="https://api.github.com/users/${user}/gists"
gist_path="${2:-${HOME}/git/gists}"
gist_manifest="${gist_path}/manifest.json"

main() {
  net_query_internet || die "No internet connectivity"

  try mkdir -p "${gist_path}"

  curl -s "${base_uri}" > "${gist_manifest}"

  readarray -t gist_id_list < <(jq -r '.[].id' "${gist_manifest}")

  (
    try cd "${gist_path}"
    for gist_id in "${gist_id_list[@]}"; do
      log_info "Syncing ${gist_id}..."
      gist_uri="https://gist.github.com/${gist_id}.git"
      [[ ! -d "${gist_id}" ]] && git clone "${gist_uri}"
      (
        try cd "${gist_id}"
        gist_filename=$(
          jq -r --arg gist_id "${gist_id}" '
            .[] |
              select(.id==$gist_id) |
              .files[].filename' "${gist_manifest}"
        )
        ln_target="${gist_path}/${gist_id}/${gist_filename}"
        ln_link="${gist_path}/${gist_filename}"
        ln -s "${ln_target}" "${ln_link}" >/dev/null 2>&1
      )
    done
  )
}

main "${@}"
```

</div>

</div>

---

### What changed and why

**`include core/stdlib`** — replaces three separate includes (`core/die`,
`core/requires`, `utils/logging`) with one. `core/stdlib` is the curated
baseline: control flow, dependency checking, logging, and more. The
original's `die()` and `requires()` are shellac verbatim, hand-rolled
inline — `core/stdlib` deletes 22 lines of boilerplate that were
reimplementing what was already available.

**`requires` moves to the top** — in the original it's called inside
`main()`, after variables are already assigned. With shellac it sits at
the top of the script, before any work begins. `git` is also added — the
original calls `git clone` but never checks for it.

**`get_url` is removed** — it was a six-line wrapper around `curl -s`
called exactly once, with the `--save` branch never used. Inlining the
`curl` call removes the function entirely.

**`net_query_internet`** — preflight connectivity check before hitting
the API. The original would let `curl` silently fail and pass an empty
or error JSON to `jq`. `net_query_internet || die` makes the failure
immediate and readable.

**`try`** — `mkdir -p ... || die "..."` and `cd ... || die "..."` collapse
to `try mkdir -p ...` and `try cd ...`. Same semantics, less noise.

---

## Example 3: find_requires

A script that scans all `.sh` files under the current directory and
reports which external commands each file depends on. It already uses
shellac — `array_join` and `is_in_path` — but still leans on a chain of
external processes (`find`, `grep`, `tr`, `sort`, `uniq`) where shellac
has direct equivalents. The rewrite shows what progressive adoption looks
like: not a first conversion, but leaning in further.

---

<div markdown="block" style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;">

<div markdown="block">

**Partial shellac**

```bash
#!/bin/bash

source shellac

include core/is
include array/join

exclude_list=(
    - '\.' '\.\.' '\.\./\.\.' '\[' '\]' '\{' '\}' '/'
    alias
    bash
    case cd clear clock command
    dir do done
    echo esac
    false fi file
    getopts
    hash
    if in
    last less link local
    kill
    more
    pass passwd printf
    rand read rename replacements return
    script shellcheck shift sleep source split sum
    test then timeout top true trust type
    w wait waitpid wheel which while write
)

grep_filter=$(array_join '|' "${exclude_list[@]}")

while read -r file; do
    found_cmds=""
    while read -r; do
        is_in_path "${REPLY}" && found_cmds+="${REPLY} "
    done < <(
        grep -Ev "^$|^#" "${file}" |
            tr " " "\n" |
            grep -Ev -- "${grep_filter}" |
            grep . |
            sort |
            uniq
    )
    (( "${#found_cmds}" > 0 )) && printf -- '%s: requires %s\n' "${file}" "${found_cmds}"
done < <(find . -name "*.sh")
```

</div>

<div markdown="block">

**Idiomatic shellac**

```bash
#!/bin/bash

source shellac

include core/is
include array/join
include array/set

exclude_list=(
    - . .. ../.. '[' ']' '{' '}' '/'
    alias
    bash
    case cd clear clock command
    dir do done
    echo esac
    false fi file
    getopts
    hash
    if in
    last less link local
    kill
    more
    pass passwd printf
    rand read rename replacements return
    script shellcheck shift sleep source split sum
    test then timeout top true trust type
    w wait waitpid wheel which while write
)

shopt -s globstar nullglob

# Recursively match all .sh files
for file in ./**/*.sh; do
    # Word-split each non-blank, non-comment line into candidates
    declare -a candidates=()
    while IFS= read -r line; do
        case "${line}" in
            ('#'*|'') continue ;;
        esac
        read -ra words <<< "${line}"
        candidates+=( "${words[@]}" )
    done < "${file}"

    # Deduplicate candidates
    array_unique candidates

    # Collect words that resolve to an external command
    declare -a found_cmds=()
    for word in "${candidates[@]}"; do
        var_is_one_of "${word}" "${exclude_list[@]}" && continue
        # Catch any builtins etc that we might have missed from exclude_list
        is_builtin "${word}" && continue
        is_keyword "${word}" && continue
        # Last, check if the word resolves to an item in $PATH
        is_in_path "${word}" && found_cmds+=( "${word}" )
    done

    (( ${#found_cmds[@]} > 0 )) || continue
    printf -- '%s: requires %s\n' "${file}" "$(array_join ' ' "${found_cmds[@]}")"
done
```

</div>

</div>

---

### What changed and why

**`find . -name "*.sh"` → `shopt -s globstar nullglob` + `for file in ./**/*.sh`** —
`find` spawns a subprocess and feeds a `while read` loop via process
substitution. A bash glob with `globstar` is native, needs no subshell,
and `nullglob` means an empty match produces nothing rather than a
literal `**/*.sh` entry.

**The grep/tr/sort/uniq pipeline → inline loop + `array_unique`** —
`grep -Ev "^$|^#" | tr " " "\n" | grep -Ev ... | grep . | sort | uniq`
is five external processes per file. The rewrite reads the file once with
a `while read` loop, uses `read -ra` to word-split each line (no `tr`),
skips blanks and comments with a `case` statement, and deduplicates with
`array_unique`. No subshells, no pipelines.

**`grep_filter` regex → `var_is_one_of` exact match** — the original
builds a regex alternation string (`bash|shellcheck|...`) and passes it
to `grep -Ev`. This works, but it does substring matching: a word like
`interface` would match the `in` pattern. `var_is_one_of` does exact
whole-word comparison, which is both more correct and eliminates the
need for the escaped entries (`'\{'`, `'\['`) in the exclude list — they
become plain `{` and `[`.

**`found_cmds` string → array + `array_join`** — `found_cmds+="${REPLY} "`
appends to a string with a trailing space. An array carries no trailing
whitespace and `array_join` formats it cleanly for output.
