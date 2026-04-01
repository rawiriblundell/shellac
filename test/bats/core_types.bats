#!/usr/bin/env bats
# Tests for core/types in lib/sh/core/types.sh

load 'helpers/setup'

setup() {
  TEST_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "${TEST_DIR}"
}

# ---------------------------------------------------------------------------
# detect_type
# ---------------------------------------------------------------------------

@test "detect_type: empty string returns 'empty'" {
  run shellac_run 'include "core/types"; detect_type ""'
  [ "${status}" -eq 0 ]
  [ "${output}" = "empty" ]
}

@test "detect_type: no argument returns 'empty'" {
  run shellac_run 'include "core/types"; detect_type'
  [ "${status}" -eq 0 ]
  [ "${output}" = "empty" ]
}

@test "detect_type: integer returns 'integer'" {
  run shellac_run 'include "core/types"; detect_type 42'
  [ "${status}" -eq 0 ]
  [ "${output}" = "integer" ]
}

@test "detect_type: negative integer returns 'integer'" {
  run shellac_run 'include "core/types"; detect_type -7'
  [ "${status}" -eq 0 ]
  [ "${output}" = "integer" ]
}

@test "detect_type: 0 returns 'integer' (not bool)" {
  run shellac_run 'include "core/types"; detect_type 0'
  [ "${status}" -eq 0 ]
  [ "${output}" = "integer" ]
}

@test "detect_type: 1 returns 'integer' (not bool)" {
  run shellac_run 'include "core/types"; detect_type 1'
  [ "${status}" -eq 0 ]
  [ "${output}" = "integer" ]
}

@test "detect_type: float returns 'float'" {
  run shellac_run 'include "core/types"; detect_type 3.14'
  [ "${status}" -eq 0 ]
  [ "${output}" = "float" ]
}

@test "detect_type: 'true' returns 'bool'" {
  run shellac_run 'include "core/types"; detect_type true'
  [ "${status}" -eq 0 ]
  [ "${output}" = "bool" ]
}

@test "detect_type: 'false' returns 'bool'" {
  run shellac_run 'include "core/types"; detect_type false'
  [ "${status}" -eq 0 ]
  [ "${output}" = "bool" ]
}

@test "detect_type: 'yes' returns 'bool'" {
  run shellac_run 'include "core/types"; detect_type yes'
  [ "${status}" -eq 0 ]
  [ "${output}" = "bool" ]
}

@test "detect_type: 'no' returns 'bool'" {
  run shellac_run 'include "core/types"; detect_type no'
  [ "${status}" -eq 0 ]
  [ "${output}" = "bool" ]
}

@test "detect_type: 'on' returns 'bool'" {
  run shellac_run 'include "core/types"; detect_type on'
  [ "${status}" -eq 0 ]
  [ "${output}" = "bool" ]
}

@test "detect_type: 'off' returns 'bool'" {
  run shellac_run 'include "core/types"; detect_type off'
  [ "${status}" -eq 0 ]
  [ "${output}" = "bool" ]
}

@test "detect_type: 'TRUE' returns 'bool' (case-insensitive)" {
  run shellac_run 'include "core/types"; detect_type TRUE'
  [ "${status}" -eq 0 ]
  [ "${output}" = "bool" ]
}

@test "detect_type: plain string returns 'string'" {
  run shellac_run 'include "core/types"; detect_type hello'
  [ "${status}" -eq 0 ]
  [ "${output}" = "string" ]
}

@test "detect_type: string with spaces returns 'string'" {
  run shellac_run 'include "core/types"; detect_type "hello world"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "string" ]
}
