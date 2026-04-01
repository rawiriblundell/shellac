#!/usr/bin/env bats
# Tests for core/die in lib/sh/core/die.sh

load 'helpers/setup'

setup() {
  TEST_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "${TEST_DIR}"
}

# ---------------------------------------------------------------------------
# cmd_die / die
# ---------------------------------------------------------------------------

@test "cmd_die: exits with non-zero status" {
  run shellac_run 'include "core/die"; cmd_die "something went wrong"'
  [ "${status}" -ne 0 ]
}

@test "cmd_die: prints message to stderr" {
  run shellac_run 'include "core/die"; cmd_die "fatal error" 2>&1'
  [[ "${output}" == *"fatal error"* ]]
}

@test "cmd_die: output contains ====>" {
  run shellac_run 'include "core/die"; cmd_die "oops" 2>&1'
  [[ "${output}" == *"====>"* ]]
}

@test "die: alias for cmd_die exits non-zero" {
  run shellac_run 'include "core/die"; die "alias test"'
  [ "${status}" -ne 0 ]
}

@test "die: alias prints message to stderr" {
  run shellac_run 'include "core/die"; die "alias msg" 2>&1'
  [[ "${output}" == *"alias msg"* ]]
}

# ---------------------------------------------------------------------------
# cmd_warn / warn
# ---------------------------------------------------------------------------

@test "cmd_warn: exits 0" {
  run shellac_run 'include "core/die"; cmd_warn "just a warning"'
  [ "${status}" -eq 0 ]
}

@test "cmd_warn: prints message to stderr" {
  run shellac_run 'include "core/die"; cmd_warn "watch out" 2>&1'
  [[ "${output}" == *"watch out"* ]]
}

@test "warn: alias for cmd_warn exits 0" {
  run shellac_run 'include "core/die"; warn "alias warn"'
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# cmd_try / try
# ---------------------------------------------------------------------------

@test "cmd_try: succeeds when command succeeds" {
  run shellac_run 'include "core/die"; cmd_try true'
  [ "${status}" -eq 0 ]
}

@test "cmd_try: exits non-zero when command fails" {
  run shellac_run 'include "core/die"; cmd_try false'
  [ "${status}" -ne 0 ]
}

@test "try: alias succeeds when command succeeds" {
  run shellac_run 'include "core/die"; try true'
  [ "${status}" -eq 0 ]
}

@test "try: alias exits non-zero when command fails" {
  run shellac_run 'include "core/die"; try false'
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# cmd_retry
# ---------------------------------------------------------------------------

@test "cmd_retry: succeeds immediately on a passing command" {
  run shellac_run 'include "core/die"; cmd_retry true'
  [ "${status}" -eq 0 ]
}

@test "cmd_retry: fails after all attempts exhausted" {
  run shellac_run 'include "core/die"; cmd_retry -m 2 false'
  [ "${status}" -ne 0 ]
}

@test "cmd_retry: error message mentions attempt count" {
  run shellac_run 'include "core/die"; cmd_retry -m 2 false 2>&1'
  [[ "${output}" == *"2"* ]]
}

@test "cmd_retry: succeeds when command passes on second attempt" {
  run shellac_run '
    include "core/die"
    _attempt=0
    flaky() { (( _attempt++ )); (( _attempt >= 2 )); }
    cmd_retry -m 3 flaky
  '
  [ "${status}" -eq 0 ]
}
