#!/usr/bin/env bats
# Tests for utils/choose in lib/sh/utils/choose.sh

load 'helpers/setup'

setup() {
  TEST_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "${TEST_DIR}"
}

# ---------------------------------------------------------------------------
# choose
# ---------------------------------------------------------------------------

@test "choose: returns exactly one argument from the list" {
  run shellac_run 'include "utils/choose"; choose apple banana cherry'
  [ "${status}" -eq 0 ]
  [[ "${output}" = "apple" || "${output}" = "banana" || "${output}" = "cherry" ]]
}

@test "choose: single argument returns that argument" {
  run shellac_run 'include "utils/choose"; choose only'
  [ "${status}" -eq 0 ]
  [ "${output}" = "only" ]
}

@test "choose: no arguments returns 1" {
  run shellac_run 'include "utils/choose"; choose'
  [ "${status}" -eq 1 ]
}

@test "choose: no arguments prints error to stderr" {
  run shellac_run 'include "utils/choose"; choose 2>&1'
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"no elements"* ]]
}

@test "choose: output is a single line" {
  run shellac_run 'include "utils/choose"; choose a b c d e'
  [ "${status}" -eq 0 ]
  [ "$(printf '%s\n' "${output}" | wc -l | tr -d ' ')" = "1" ]
}

@test "choose: two-element list returns one of them" {
  run shellac_run 'include "utils/choose"; choose heads tails'
  [ "${status}" -eq 0 ]
  [[ "${output}" = "heads" || "${output}" = "tails" ]]
}
