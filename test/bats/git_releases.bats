#!/usr/bin/env bats
# Tests for git_fetch_release and helpers in lib/sh/git/releases.sh

load 'helpers/setup'

# ---------------------------------------------------------------------------
# _git_fetch_release_arch_aliases
# ---------------------------------------------------------------------------

@test "_git_fetch_release_arch_aliases: x86_64 returns three aliases" {
  run shellac_run 'include "git/releases"; _git_fetch_release_arch_aliases x86_64'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"x86_64"* ]]
  [[ "${output}" = *"amd64"* ]]
  [[ "${output}" = *"x64"* ]]
}

@test "_git_fetch_release_arch_aliases: aarch64 returns aarch64 and arm64" {
  run shellac_run 'include "git/releases"; _git_fetch_release_arch_aliases aarch64'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"aarch64"* ]]
  [[ "${output}" = *"arm64"* ]]
}

@test "_git_fetch_release_arch_aliases: arm returns armv7l armv7 arm" {
  run shellac_run 'include "git/releases"; _git_fetch_release_arch_aliases arm'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"armv7l"* ]]
  [[ "${output}" = *"arm"* ]]
}

@test "_git_fetch_release_arch_aliases: unknown arch returns itself" {
  run shellac_run 'include "git/releases"; _git_fetch_release_arch_aliases riscv64'
  [ "${status}" -eq 0 ]
  [ "${output}" = "riscv64" ]
}

# ---------------------------------------------------------------------------
# git_fetch_release argument validation
# ---------------------------------------------------------------------------

@test "git_fetch_release: missing repo argument exits non-zero" {
  run shellac_run 'include "git/releases"; git_fetch_release'
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# _git_fetch_release_json (network; skipped when offline)
# ---------------------------------------------------------------------------

@test "_git_fetch_release_json: latest cli/cli returns JSON with tag_name" {
  curl -fsSL --max-time 5 "https://api.github.com/repos/cli/cli/releases/latest" \
    >/dev/null 2>&1 || skip "no network access to GitHub API"
  run shellac_run '
    include "git/releases"
    json=$(_git_fetch_release_json cli/cli latest)
    printf "%s\n" "${json}" | jq -r .tag_name'
  [ "${status}" -eq 0 ]
  [[ "${output}" = v* ]]
}

@test "_git_fetch_release_json: non-existent repo exits 1" {
  curl -fsSL --max-time 5 "https://api.github.com" >/dev/null 2>&1 \
    || skip "no network access to GitHub API"
  run shellac_run '
    include "git/releases"
    _git_fetch_release_json no-such-owner-xyz/no-such-repo-xyz latest'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# git_fetch_release end-to-end (network; skipped when offline)
# ---------------------------------------------------------------------------

@test "git_fetch_release: downloads a real asset from cli/cli latest" {
  curl -fsSL --max-time 5 "https://api.github.com/repos/cli/cli/releases/latest" \
    >/dev/null 2>&1 || skip "no network access to GitHub API"
  run shellac_run '
    include "git/releases"
    dir=$(mktemp -d)
    trap "rm -rf ${dir}" EXIT
    cd "${dir}" || exit 1
    git_fetch_release cli/cli latest x86_64
    ls "${dir}"'
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]
}
