#!/usr/bin/env bats
# Tests for utils/mkcd in lib/sh/utils/mkcd.sh

load 'helpers/setup'

setup() {
  TEST_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "${TEST_DIR}"
}

# ---------------------------------------------------------------------------
# mkcd
# ---------------------------------------------------------------------------

@test "mkcd: creates a new directory and reports success" {
  run shellac_run "include \"utils/mkcd\"; mkcd \"${TEST_DIR}/newdir\""
  [ "${status}" -eq 0 ]
  [ -d "${TEST_DIR}/newdir" ]
}

@test "mkcd: creates nested directories" {
  run shellac_run "include \"utils/mkcd\"; mkcd \"${TEST_DIR}/a/b/c\""
  [ "${status}" -eq 0 ]
  [ -d "${TEST_DIR}/a/b/c" ]
}

@test "mkcd: existing directory succeeds" {
  mkdir -p "${TEST_DIR}/existing"
  run shellac_run "include \"utils/mkcd\"; mkcd \"${TEST_DIR}/existing\""
  [ "${status}" -eq 0 ]
}

@test "mkcd: changes to the new directory" {
  run shellac_run "include \"utils/mkcd\"; mkcd \"${TEST_DIR}/target\" && printf '%s\n' \"\$(pwd)\""
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"target"* ]]
}

@test "mkcd: no argument exits non-zero" {
  run shellac_run 'include "utils/mkcd"; mkcd'
  [ "${status}" -ne 0 ]
}
