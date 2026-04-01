#!/usr/bin/env bats
# Tests for utils/cmd in lib/sh/utils/cmd.sh

load 'helpers/setup'

setup() {
  TEST_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "${TEST_DIR}"
}

# ---------------------------------------------------------------------------
# cmd_check
# ---------------------------------------------------------------------------

@test "cmd_check: existing command returns 0" {
  run shellac_run 'include "utils/cmd"; cmd_check bash'
  [ "${status}" -eq 0 ]
}

@test "cmd_check: missing command returns 1" {
  run shellac_run 'include "utils/cmd"; cmd_check __no_such_cmd_shellac__'
  [ "${status}" -eq 1 ]
}

@test "cmd_check: multiple existing commands returns 0" {
  run shellac_run 'include "utils/cmd"; cmd_check bash sed awk'
  [ "${status}" -eq 0 ]
}

@test "cmd_check: mix of present and missing returns 1" {
  run shellac_run 'include "utils/cmd"; cmd_check bash __no_such_cmd_shellac__'
  [ "${status}" -eq 1 ]
}

@test "cmd_check: no output without --verbose for found command" {
  run shellac_run 'include "utils/cmd"; cmd_check bash'
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
}

@test "cmd_check --verbose: prints path of found command" {
  run shellac_run 'include "utils/cmd"; cmd_check --verbose bash'
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"bash"* ]]
}

@test "cmd_check --verbose: prints error for missing command" {
  run shellac_run 'include "utils/cmd"; cmd_check --verbose __no_such_cmd_shellac__ 2>&1'
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"not found"* ]]
}

@test "cmd_check -v: short flag works same as --verbose" {
  run shellac_run 'include "utils/cmd"; cmd_check -v bash'
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"bash"* ]]
}

@test "cmd_check: no args returns 0 and prints usage" {
  run shellac_run 'include "utils/cmd"; cmd_check'
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# cmd_list
# ---------------------------------------------------------------------------

@test "cmd_list: with no args outputs commands" {
  run shellac_run 'include "utils/cmd"; cmd_list'
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"bash"* ]]
}

@test "cmd_list: with filter returns matching commands" {
  run shellac_run 'include "utils/cmd"; cmd_list bash'
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"bash"* ]]
}

# ---------------------------------------------------------------------------
# cmd_exec
# ---------------------------------------------------------------------------

@test "cmd_exec: executes a command and includes output" {
  run shellac_run 'include "utils/cmd"; cmd_exec printf "%s" hello'
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"hello"* ]]
}

@test "cmd_exec: output contains timestamp header" {
  run shellac_run 'include "utils/cmd"; cmd_exec true'
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"Timestamp"* ]]
}

@test "cmd_exec: output contains exit code" {
  run shellac_run 'include "utils/cmd"; cmd_exec true'
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"Exit Code"* ]]
}

@test "cmd_exec: failed command shows ERROR" {
  run shellac_run 'include "utils/cmd"; cmd_exec false'
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"ERROR"* ]]
}

@test "cmd_exec -e: exits 1 when command fails" {
  run shellac_run 'include "utils/cmd"; cmd_exec -e false'
  [ "${status}" -eq 1 ]
}

@test "cmd_exec --exit-on-fail: exits 1 when command fails" {
  run shellac_run 'include "utils/cmd"; cmd_exec --exit-on-fail false'
  [ "${status}" -eq 1 ]
}
