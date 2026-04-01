#!/usr/bin/env bats
# Tests for utils/retry_backoff in lib/sh/utils/retry_backoff.sh

load 'helpers/setup'

setup() {
  TEST_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "${TEST_DIR}"
}

# ---------------------------------------------------------------------------
# cmd_retry_backoff
# ---------------------------------------------------------------------------

@test "cmd_retry_backoff: succeeds immediately on a passing command" {
  run shellac_run 'include "utils/retry_backoff"; cmd_retry_backoff 3 true'
  [ "${status}" -eq 0 ]
}

@test "cmd_retry_backoff: returns 1 after all attempts fail" {
  run shellac_run 'include "utils/retry_backoff"; cmd_retry_backoff 2 false'
  [ "${status}" -eq 1 ]
}

@test "cmd_retry_backoff: error message mentions attempts" {
  run shellac_run 'include "utils/retry_backoff"; cmd_retry_backoff 2 false 2>&1'
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"2"* ]]
}

@test "cmd_retry_backoff: no command returns 2" {
  run shellac_run 'include "utils/retry_backoff"; cmd_retry_backoff 3'
  [ "${status}" -eq 2 ]
}

@test "cmd_retry_backoff: succeeds when command passes on second attempt" {
  run shellac_run '
    include "utils/retry_backoff"
    _n=0
    flaky() { (( _n++ )); (( _n >= 2 )); }
    cmd_retry_backoff 3 flaky
  '
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# cmd_retry_constant
# ---------------------------------------------------------------------------

@test "cmd_retry_constant: succeeds immediately on a passing command" {
  run shellac_run 'include "utils/retry_backoff"; cmd_retry_constant 3 0 true'
  [ "${status}" -eq 0 ]
}

@test "cmd_retry_constant: returns 1 after all attempts fail" {
  run shellac_run 'include "utils/retry_backoff"; cmd_retry_constant 2 0 false'
  [ "${status}" -eq 1 ]
}

@test "cmd_retry_constant: no command returns 2" {
  run shellac_run 'include "utils/retry_backoff"; cmd_retry_constant 3 0'
  [ "${status}" -eq 2 ]
}

@test "cmd_retry_constant: error message includes attempt count" {
  run shellac_run 'include "utils/retry_backoff"; cmd_retry_constant 2 0 false 2>&1'
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"2"* ]]
}

# ---------------------------------------------------------------------------
# cmd_retry_until
# ---------------------------------------------------------------------------

@test "cmd_retry_until: succeeds when command passes immediately" {
  run shellac_run 'include "utils/retry_backoff"; cmd_retry_until 10 1 true'
  [ "${status}" -eq 0 ]
}

@test "cmd_retry_until: returns 1 when timeout reached" {
  run shellac_run 'include "utils/retry_backoff"; cmd_retry_until 1 1 false'
  [ "${status}" -eq 1 ]
}

@test "cmd_retry_until: no command returns 2" {
  run shellac_run 'include "utils/retry_backoff"; cmd_retry_until 5'
  [ "${status}" -eq 2 ]
}
