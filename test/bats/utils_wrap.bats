#!/usr/bin/env bats
# Tests for utils/wrap in lib/sh/utils/wrap.sh

load 'helpers/setup'

setup() {
  TEST_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "${TEST_DIR}"
}

# ---------------------------------------------------------------------------
# wrap_code_block
# ---------------------------------------------------------------------------

@test "wrap_code_block: single-word command produces one line" {
  run shellac_run 'include "utils/wrap"; wrap_code_block ls'
  [ "${status}" -eq 0 ]
  [ "$(printf '%s\n' "${output}" | wc -l | tr -d ' ')" = "1" ]
}

@test "wrap_code_block: options each go on their own line" {
  run shellac_run 'include "utils/wrap"; wrap_code_block aws s3api --bucket foo --key bar'
  [ "${status}" -eq 0 ]
  # At least 3 lines: command, --bucket, --key
  local linecount
  linecount="$(printf '%s\n' "${output}" | wc -l | tr -d ' ')"
  (( linecount >= 3 ))
}

@test "wrap_code_block: last line has no trailing backslash" {
  run shellac_run 'include "utils/wrap"; wrap_code_block cmd --opt1 val1 --opt2 val2'
  [ "${status}" -eq 0 ]
  local lastline
  lastline="$(printf '%s\n' "${output}" | tail -1)"
  [[ "${lastline}" != *"\\" ]]
}

@test "wrap_code_block: continuation lines end with backslash" {
  run shellac_run 'include "utils/wrap"; wrap_code_block cmd --opt1 val1 --opt2 val2'
  [ "${status}" -eq 0 ]
  local firstline
  firstline="$(printf '%s\n' "${output}" | head -1)"
  [[ "${firstline}" == *"\\" ]]
}

@test "wrap_code_block: output contains original command text" {
  run shellac_run 'include "utils/wrap"; wrap_code_block mycommand --flag value'
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"mycommand"* ]]
  [[ "${output}" == *"--flag"* ]]
  [[ "${output}" == *"value"* ]]
}
