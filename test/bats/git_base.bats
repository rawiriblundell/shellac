#!/usr/bin/env bats
# Tests for git_remote_get and other functions in lib/sh/git/base.sh
# Runs inside /opt/shellac which is a git repo with an 'origin' remote.

load 'helpers/setup'

# ---------------------------------------------------------------------------
# git_is_repo
# ---------------------------------------------------------------------------

@test "git_is_repo: returns 0 inside a git repo" {
  run shellac_run 'include "git/base"; git_is_repo'
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# git_root
# ---------------------------------------------------------------------------

@test "git_root: returns a non-empty path" {
  run shellac_run 'include "git/base"; git_root'
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]
}

# ---------------------------------------------------------------------------
# git_remote_get
# ---------------------------------------------------------------------------

@test "git_remote_get: returns a non-empty URL for origin" {
  run shellac_run 'include "git/base"; git_remote_get'
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]
}

@test "git_remote_get: default is same as explicit origin" {
  run shellac_run 'include "git/base"
    a=$(git_remote_get)
    b=$(git_remote_get origin)
    [ "${a}" = "${b}" ]'
  [ "${status}" -eq 0 ]
}

@test "git_remote_get: exits 1 for non-existent remote" {
  run shellac_run 'include "git/base"; git_remote_get _no_such_remote_'
  [ "${status}" -eq 1 ]
}

@test "git_remote_get: URL contains expected repo slug" {
  run shellac_run 'include "git/base"; git_remote_get'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"shellac"* ]]
}

# ---------------------------------------------------------------------------
# git_current_branch
# ---------------------------------------------------------------------------

@test "git_current_branch: returns a non-empty branch name" {
  run shellac_run 'include "git/base"; git_current_branch'
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]
}

# ---------------------------------------------------------------------------
# git_short_sha
# ---------------------------------------------------------------------------

@test "git_short_sha: returns a 7-character hex string" {
  run shellac_run 'include "git/base"; git_short_sha'
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9a-f]{7,}$ ]]
}
