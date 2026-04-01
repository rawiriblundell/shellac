#!/usr/bin/env bats
# Tests for utils/repeat in lib/sh/utils/repeat.sh

load 'helpers/setup'

setup() {
  TEST_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "${TEST_DIR}"
}

# ---------------------------------------------------------------------------
# repeat
# ---------------------------------------------------------------------------

@test "repeat: runs a command the specified number of times" {
  run shellac_run 'include "utils/repeat"; repeat 3 printf "x\n"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'x\nx\nx')" ]
}

@test "repeat: count of 1 runs command once" {
  run shellac_run 'include "utils/repeat"; repeat 1 printf "once\n"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "once" ]
}

@test "repeat: count of 0 runs command zero times" {
  run shellac_run 'include "utils/repeat"; repeat 0 printf "never\n"'
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
}

@test "repeat: non-numeric first arg returns 1" {
  run shellac_run 'include "utils/repeat"; repeat abc printf "x\n"'
  [ "${status}" -eq 1 ]
}

@test "repeat: error message mentions the bad argument" {
  run shellac_run 'include "utils/repeat"; repeat abc printf "x\n"'
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"abc"* ]]
}

@test "repeat: empty first arg returns 1" {
  run shellac_run 'include "utils/repeat"; repeat "" printf "x\n"'
  [ "${status}" -eq 1 ]
}

@test "repeat: passes arguments correctly to the command" {
  run shellac_run 'include "utils/repeat"; repeat 2 printf "%s\n" hello'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'hello\nhello')" ]
}
