#!/usr/bin/env bats
# Tests for core/status in lib/sh/core/status.sh

load 'helpers/setup'

setup() {
  TEST_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "${TEST_DIR}"
}

# ---------------------------------------------------------------------------
# cmd_status
# ---------------------------------------------------------------------------

@test "cmd_status: 'true' arg matches a passing command" {
  run shellac_run 'include "core/status"; true; cmd_status true'
  [ "${status}" -eq 0 ]
}

@test "cmd_status: 'false' arg matches a failing command" {
  run shellac_run 'include "core/status"; false; cmd_status false'
  [ "${status}" -eq 0 ]
}

@test "cmd_status: '0' arg matches a passing command" {
  run shellac_run 'include "core/status"; true; cmd_status 0'
  [ "${status}" -eq 0 ]
}

@test "cmd_status: '1' arg matches a failing command" {
  run shellac_run 'include "core/status"; false; cmd_status 1'
  [ "${status}" -eq 0 ]
}

@test "cmd_status: 'yes' arg matches a passing command" {
  run shellac_run 'include "core/status"; true; cmd_status yes'
  [ "${status}" -eq 0 ]
}

@test "cmd_status: 'no' arg matches a failing command" {
  run shellac_run 'include "core/status"; false; cmd_status no'
  [ "${status}" -eq 0 ]
}

@test "cmd_status: 'true' arg fails when last command failed" {
  run shellac_run 'include "core/status"; false; cmd_status true'
  [ "${status}" -ne 0 ]
}

@test "cmd_status: 'false' arg fails when last command succeeded" {
  run shellac_run 'include "core/status"; true; cmd_status false'
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# cmd_status_true
# ---------------------------------------------------------------------------

@test "cmd_status_true: returns 0 when last command succeeded" {
  run shellac_run 'include "core/status"; true; cmd_status_true'
  [ "${status}" -eq 0 ]
}

@test "cmd_status_true: returns 1 when last command failed" {
  run shellac_run 'include "core/status"; false; cmd_status_true'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# cmd_status_false
# ---------------------------------------------------------------------------

@test "cmd_status_false: returns 0 when last command failed" {
  run shellac_run 'include "core/status"; false; cmd_status_false'
  [ "${status}" -eq 0 ]
}

@test "cmd_status_false: returns 1 when last command succeeded" {
  run shellac_run 'include "core/status"; true; cmd_status_false'
  [ "${status}" -eq 1 ]
}
