#!/usr/bin/env bats
# Tests for core/requires in lib/sh/core/requires.sh

load 'helpers/setup'

setup() {
  TEST_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "${TEST_DIR}"
}

# ---------------------------------------------------------------------------
# Basic command checks
# ---------------------------------------------------------------------------

@test "requires: existing command succeeds" {
  run shellac_run 'include "core/requires"; requires bash'
  [ "${status}" -eq 0 ]
}

@test "requires: multiple existing commands succeed" {
  run shellac_run 'include "core/requires"; requires bash sed awk'
  [ "${status}" -eq 0 ]
}

@test "requires: missing command returns 1" {
  run shellac_run 'include "core/requires"; requires __no_such_cmd_shellac__'
  [ "${status}" -eq 1 ]
}

@test "requires: error lists missing command" {
  run shellac_run 'include "core/requires"; requires __no_such_cmd_shellac__ 2>&1'
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"__no_such_cmd_shellac__"* ]]
}

@test "requires: mix of present and missing returns 1" {
  run shellac_run 'include "core/requires"; requires bash __no_such_cmd_shellac__'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# Readable file checks
# ---------------------------------------------------------------------------

@test "requires: readable file path succeeds" {
  run shellac_run "include \"core/requires\"; requires \"${TEST_DIR}\""
  [ "${status}" -eq 0 ]
}

@test "requires: non-existent file returns 1" {
  run shellac_run "include \"core/requires\"; requires \"${TEST_DIR}/does_not_exist\""
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# Requirements file (-r flag)
# ---------------------------------------------------------------------------

@test "requires -r: reads requirements from file" {
  printf '%s\n' 'bash' 'sed' > "${TEST_DIR}/reqs.txt"
  run shellac_run "include \"core/requires\"; requires -r \"${TEST_DIR}/reqs.txt\""
  [ "${status}" -eq 0 ]
}

@test "requires -r: skips comment lines" {
  printf '%s\n' '# this is a comment' 'bash' > "${TEST_DIR}/reqs2.txt"
  run shellac_run "include \"core/requires\"; requires -r \"${TEST_DIR}/reqs2.txt\""
  [ "${status}" -eq 0 ]
}

@test "requires -r: missing requirements file returns 1" {
  run shellac_run "include \"core/requires\"; requires -r \"${TEST_DIR}/no_such_file.txt\""
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# Bash version check
# ---------------------------------------------------------------------------

@test "requires: BASH32 succeeds on current bash (>= 3.2)" {
  run shellac_run 'include "core/requires"; requires BASH32'
  [ "${status}" -eq 0 ]
}

@test "requires: BASH99 fails on current bash (< 9.9)" {
  run shellac_run 'include "core/requires"; requires BASH99'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# ZSH version check (injecting fake ZSH_VERSION)
# ---------------------------------------------------------------------------

@test "requires: ZSH57 succeeds when ZSH_VERSION is 5.7.1" {
  run shellac_run 'include "core/requires"; ZSH_VERSION="5.7.1"; requires ZSH57'
  [ "${status}" -eq 0 ]
}

@test "requires: ZSH52 succeeds when ZSH_VERSION is 5.7.1 (older requirement)" {
  run shellac_run 'include "core/requires"; ZSH_VERSION="5.7.1"; requires ZSH52'
  [ "${status}" -eq 0 ]
}

@test "requires: ZSH60 fails when ZSH_VERSION is 5.7.1 (newer requirement)" {
  run shellac_run 'include "core/requires"; ZSH_VERSION="5.7.1"; requires ZSH60'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# KSH version check (injecting fake KSH_VERSION)
# ---------------------------------------------------------------------------

@test "requires: KSH57 succeeds when KSH_VERSION is mksh R57" {
  run shellac_run 'include "core/requires"; KSH_VERSION="@(#)MIRBSD KSH R57 2019/09/30"; requires KSH57'
  [ "${status}" -eq 0 ]
}

@test "requires: KSH50 succeeds when KSH_VERSION is mksh R57 (older requirement)" {
  run shellac_run 'include "core/requires"; KSH_VERSION="@(#)MIRBSD KSH R57 2019/09/30"; requires KSH50'
  [ "${status}" -eq 0 ]
}

@test "requires: KSH60 fails when KSH_VERSION is mksh R57 (newer requirement)" {
  run shellac_run 'include "core/requires"; KSH_VERSION="@(#)MIRBSD KSH R57 2019/09/30"; requires KSH60'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# Variable check (KEY=VALUE)
# ---------------------------------------------------------------------------

@test "requires: KEY=VALUE check succeeds when variable matches" {
  run shellac_run 'include "core/requires"; MY_VAR=hello requires "MY_VAR=hello"'
  [ "${status}" -eq 0 ]
}

@test "requires: KEY=VALUE check fails when variable does not match" {
  run shellac_run 'include "core/requires"; MY_VAR=world requires "MY_VAR=hello"'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# Version constraint checks
# ---------------------------------------------------------------------------

@test "requires: version constraint passes for installed bash" {
  run shellac_run 'include "core/requires"; requires "bash>=3.0"'
  [ "${status}" -eq 0 ]
}

@test "requires: version constraint fails for impossibly high version" {
  run shellac_run 'include "core/requires"; requires "bash>=999.0"'
  [ "${status}" -eq 1 ]
}
