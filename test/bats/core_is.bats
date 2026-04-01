#!/usr/bin/env bats
# Tests for core/is in lib/sh/core/is.sh

load 'helpers/setup'

setup() {
  TEST_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "${TEST_DIR}"
}

# ---------------------------------------------------------------------------
# bool_is_false
# ---------------------------------------------------------------------------

@test "bool_is_false: '1' is false" {
  run shellac_run 'include "core/is"; bool_is_false 1'
  [ "${status}" -eq 0 ]
}

@test "bool_is_false: 'false' is false" {
  run shellac_run 'include "core/is"; bool_is_false false'
  [ "${status}" -eq 0 ]
}

@test "bool_is_false: 'FALSE' is false (case-insensitive)" {
  run shellac_run 'include "core/is"; bool_is_false FALSE'
  [ "${status}" -eq 0 ]
}

@test "bool_is_false: 'no' is false" {
  run shellac_run 'include "core/is"; bool_is_false no'
  [ "${status}" -eq 0 ]
}

@test "bool_is_false: 'off' is false" {
  run shellac_run 'include "core/is"; bool_is_false off'
  [ "${status}" -eq 0 ]
}

@test "bool_is_false: '0' is not false" {
  run shellac_run 'include "core/is"; bool_is_false 0'
  [ "${status}" -eq 1 ]
}

@test "bool_is_false: 'true' is not false" {
  run shellac_run 'include "core/is"; bool_is_false true'
  [ "${status}" -eq 1 ]
}

@test "bool_is_false: empty string is not false" {
  run shellac_run 'include "core/is"; bool_is_false ""'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# bool_is_true
# ---------------------------------------------------------------------------

@test "bool_is_true: '0' is true" {
  run shellac_run 'include "core/is"; bool_is_true 0'
  [ "${status}" -eq 0 ]
}

@test "bool_is_true: 'true' is true" {
  run shellac_run 'include "core/is"; bool_is_true true'
  [ "${status}" -eq 0 ]
}

@test "bool_is_true: 'TRUE' is true (case-insensitive)" {
  run shellac_run 'include "core/is"; bool_is_true TRUE'
  [ "${status}" -eq 0 ]
}

@test "bool_is_true: 'yes' is true" {
  run shellac_run 'include "core/is"; bool_is_true yes'
  [ "${status}" -eq 0 ]
}

@test "bool_is_true: 'on' is true" {
  run shellac_run 'include "core/is"; bool_is_true on'
  [ "${status}" -eq 0 ]
}

@test "bool_is_true: 'y' is true" {
  run shellac_run 'include "core/is"; bool_is_true y'
  [ "${status}" -eq 0 ]
}

@test "bool_is_true: '1' is not true" {
  run shellac_run 'include "core/is"; bool_is_true 1'
  [ "${status}" -eq 1 ]
}

@test "bool_is_true: 'false' is not true" {
  run shellac_run 'include "core/is"; bool_is_true false'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# bool (stdin path — always non-tty in shellac_run)
# ---------------------------------------------------------------------------

@test "bool: reads from stdin and returns 0 for 'true'" {
  run shellac_run 'include "core/is"; printf "true" | bool'
  [ "${status}" -eq 0 ]
}

@test "bool: reads from stdin and returns 1 for 'false'" {
  run shellac_run 'include "core/is"; printf "false" | bool'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# bool_is_valid
# ---------------------------------------------------------------------------

@test "bool_is_valid: '0' is valid" {
  run shellac_run 'include "core/is"; bool_is_valid 0'
  [ "${status}" -eq 0 ]
}

@test "bool_is_valid: '1' is valid" {
  run shellac_run 'include "core/is"; bool_is_valid 1'
  [ "${status}" -eq 0 ]
}

@test "bool_is_valid: 'true' is valid" {
  run shellac_run 'include "core/is"; bool_is_valid true'
  [ "${status}" -eq 0 ]
}

@test "bool_is_valid: 'off' is valid" {
  run shellac_run 'include "core/is"; bool_is_valid off'
  [ "${status}" -eq 0 ]
}

@test "bool_is_valid: 'maybe' is not valid" {
  run shellac_run 'include "core/is"; bool_is_valid maybe'
  [ "${status}" -eq 1 ]
}

@test "bool_is_valid: empty string is not valid" {
  run shellac_run 'include "core/is"; bool_is_valid ""'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# var_is_set
# ---------------------------------------------------------------------------

@test "var_is_set: non-empty value returns 0" {
  run shellac_run 'include "core/is"; var_is_set "hello"'
  [ "${status}" -eq 0 ]
}

@test "var_is_set: empty string returns 1" {
  run shellac_run 'include "core/is"; var_is_set ""'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# var_is_blank
# ---------------------------------------------------------------------------

@test "var_is_blank: empty string returns 0" {
  run shellac_run 'include "core/is"; var_is_blank ""'
  [ "${status}" -eq 0 ]
}

@test "var_is_blank: non-empty string returns 1" {
  run shellac_run 'include "core/is"; var_is_blank "notempty"'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# is_command
# ---------------------------------------------------------------------------

@test "is_command: bash exists" {
  run shellac_run 'include "core/is"; is_command bash'
  [ "${status}" -eq 0 ]
}

@test "is_command: non-existent command returns 1" {
  run shellac_run 'include "core/is"; is_command __no_such_cmd_shellac__'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# is_function
# ---------------------------------------------------------------------------

@test "is_function: defined function returns 0" {
  run shellac_run 'include "core/is"; myfunc() { :; }; is_function myfunc'
  [ "${status}" -eq 0 ]
}

@test "is_function: undefined name returns 1" {
  run shellac_run 'include "core/is"; is_function __no_such_func_shellac__'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# is_interactive
# ---------------------------------------------------------------------------

@test "is_interactive: returns 1 in non-interactive subprocess" {
  run shellac_run 'include "core/is"; is_interactive'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# is_root
# ---------------------------------------------------------------------------

@test "is_root: returns the correct result based on actual EUID" {
  local expected_status=1
  (( EUID == 0 )) && expected_status=0
  run shellac_run 'include "core/is"; is_root'
  [ "${status}" -eq "${expected_status}" ]
}

# ---------------------------------------------------------------------------
# var_is_one_of
# ---------------------------------------------------------------------------

@test "var_is_one_of: value in set returns 0" {
  run shellac_run 'include "core/is"; var_is_one_of "b" a b c'
  [ "${status}" -eq 0 ]
}

@test "var_is_one_of: value not in set returns 1" {
  run shellac_run 'include "core/is"; var_is_one_of "z" a b c'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# var_exactly_one_set
# ---------------------------------------------------------------------------

@test "var_exactly_one_set: exactly one non-empty returns 0" {
  run shellac_run 'include "core/is"; var_exactly_one_set "x" "" ""'
  [ "${status}" -eq 0 ]
}

@test "var_exactly_one_set: all empty returns 1" {
  run shellac_run 'include "core/is"; var_exactly_one_set "" "" ""'
  [ "${status}" -eq 1 ]
}

@test "var_exactly_one_set: two non-empty returns 1" {
  run shellac_run 'include "core/is"; var_exactly_one_set "a" "b" ""'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# is_array
# ---------------------------------------------------------------------------

@test "is_array: indexed array returns 0" {
  run shellac_run 'include "core/is"; declare -a myarr=(1 2 3); is_array myarr'
  [ "${status}" -eq 0 ]
}

@test "is_array: regular variable returns 1" {
  run shellac_run 'include "core/is"; myvar="hello"; is_array myvar'
  [ "${status}" -eq 1 ]
}
