#!/usr/bin/env bats
# Tests for utils/validate_config in lib/sh/utils/validate_config.sh

load 'helpers/setup'

setup() {
  TEST_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "${TEST_DIR}"
}

# ---------------------------------------------------------------------------
# validate_config
# ---------------------------------------------------------------------------

@test "validate_config: valid key=value file returns 0" {
  printf '%s\n' 'foo=bar' 'baz=qux' > "${TEST_DIR}/valid.cfg"
  run shellac_run "include \"utils/validate_config\"; validate_config \"${TEST_DIR}/valid.cfg\""
  [ "${status}" -eq 0 ]
}

@test "validate_config: blank lines are ignored" {
  printf '%s\n' 'foo=bar' '' 'baz=qux' > "${TEST_DIR}/blanks.cfg"
  run shellac_run "include \"utils/validate_config\"; validate_config \"${TEST_DIR}/blanks.cfg\""
  [ "${status}" -eq 0 ]
}

@test "validate_config: comment lines are ignored" {
  printf '%s\n' '# this is a comment' 'foo=bar' > "${TEST_DIR}/comments.cfg"
  run shellac_run "include \"utils/validate_config\"; validate_config \"${TEST_DIR}/comments.cfg\""
  [ "${status}" -eq 0 ]
}

@test "validate_config: line with spaces returns 1" {
  printf '%s\n' 'foo = bar' > "${TEST_DIR}/spaces.cfg"
  run shellac_run "include \"utils/validate_config\"; validate_config \"${TEST_DIR}/spaces.cfg\""
  [ "${status}" -eq 1 ]
}

@test "validate_config: line without equals returns 1" {
  printf '%s\n' 'foobar' > "${TEST_DIR}/noequals.cfg"
  run shellac_run "include \"utils/validate_config\"; validate_config \"${TEST_DIR}/noequals.cfg\""
  [ "${status}" -eq 1 ]
}

@test "validate_config: empty file returns 0" {
  > "${TEST_DIR}/empty.cfg"
  run shellac_run "include \"utils/validate_config\"; validate_config \"${TEST_DIR}/empty.cfg\""
  [ "${status}" -eq 0 ]
}

@test "validate_config: no argument exits non-zero" {
  run shellac_run 'include "utils/validate_config"; validate_config'
  [ "${status}" -ne 0 ]
}

@test "validate_config: mixed valid and invalid returns 1" {
  printf '%s\n' 'good=value' 'bad line here' > "${TEST_DIR}/mixed.cfg"
  run shellac_run "include \"utils/validate_config\"; validate_config \"${TEST_DIR}/mixed.cfg\""
  [ "${status}" -eq 1 ]
}
