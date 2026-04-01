#!/usr/bin/env bats
# Tests for core/assert in lib/sh/core/assert.sh

load 'helpers/setup'

setup() {
  TEST_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "${TEST_DIR}"
}

# ---------------------------------------------------------------------------
# assert_not_empty
# ---------------------------------------------------------------------------

@test "assert_not_empty: non-empty value succeeds" {
  run shellac_run 'include "core/assert"; assert_not_empty "hello"'
  [ "${status}" -eq 0 ]
}

@test "assert_not_empty: empty string returns 1" {
  run shellac_run 'include "core/assert"; assert_not_empty ""'
  [ "${status}" -eq 1 ]
}

@test "assert_not_empty: missing argument returns 1" {
  run shellac_run 'include "core/assert"; assert_not_empty'
  [ "${status}" -eq 1 ]
}

@test "assert_not_empty: error message includes variable name" {
  run shellac_run 'include "core/assert"; assert_not_empty "" "MY_VAR" 2>&1'
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"MY_VAR"* ]]
}

@test "assert_not_empty: default name used when no name given" {
  run shellac_run 'include "core/assert"; assert_not_empty "" 2>&1'
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"value"* ]]
}

# ---------------------------------------------------------------------------
# assert_is_installed
# ---------------------------------------------------------------------------

@test "assert_is_installed: existing command succeeds" {
  run shellac_run 'include "core/assert"; assert_is_installed bash'
  [ "${status}" -eq 0 ]
}

@test "assert_is_installed: missing command returns 1" {
  run shellac_run 'include "core/assert"; assert_is_installed __no_such_cmd_shellac__'
  [ "${status}" -eq 1 ]
}

@test "assert_is_installed: error message names the missing command" {
  run shellac_run 'include "core/assert"; assert_is_installed __no_such_cmd_shellac__ 2>&1'
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"__no_such_cmd_shellac__"* ]]
}

# ---------------------------------------------------------------------------
# assert_value_in_list
# ---------------------------------------------------------------------------

@test "assert_value_in_list: value in list succeeds" {
  run shellac_run 'include "core/assert"; assert_value_in_list "staging" dev staging prod'
  [ "${status}" -eq 0 ]
}

@test "assert_value_in_list: value not in list returns 1" {
  run shellac_run 'include "core/assert"; assert_value_in_list "qa" dev staging prod'
  [ "${status}" -eq 1 ]
}

@test "assert_value_in_list: error message includes the rejected value" {
  run shellac_run 'include "core/assert"; assert_value_in_list "qa" dev staging prod 2>&1'
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"qa"* ]]
}

@test "assert_value_in_list: single-item list matches" {
  run shellac_run 'include "core/assert"; assert_value_in_list "only" only'
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# assert_exactly_one_of
# ---------------------------------------------------------------------------

@test "assert_exactly_one_of: exactly one non-empty succeeds" {
  run shellac_run 'include "core/assert"; assert_exactly_one_of "value" "" ""'
  [ "${status}" -eq 0 ]
}

@test "assert_exactly_one_of: all empty returns 1" {
  run shellac_run 'include "core/assert"; assert_exactly_one_of "" "" ""'
  [ "${status}" -eq 1 ]
}

@test "assert_exactly_one_of: two non-empty returns 1" {
  run shellac_run 'include "core/assert"; assert_exactly_one_of "a" "b" ""'
  [ "${status}" -eq 1 ]
}

@test "assert_exactly_one_of: error message reports count" {
  run shellac_run 'include "core/assert"; assert_exactly_one_of "a" "b" "" 2>&1'
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"2"* ]]
}
