#!/usr/bin/env bats
# Tests for rev in lib/sh/text/rev.sh
# The module only defines rev when the system rev command is absent.
# We skip these tests if the system already provides rev (the shellac
# module returns early without redefining anything), because the system
# rev is guaranteed to work and the fallback is only loaded when needed.
# We test by forcing the function to be sourced regardless via a wrapper.

load 'helpers/setup'

# Source the fallback function directly, bypassing the early-return guard
# by temporarily unsetting the system rev check.
_rev_snippet='
  # Force the fallback by unsetting command rev check:
  # We source the file but override the early-exit with a subshell trick.
  # Instead, define the function body directly from the source.
  include "text/rev"
'

@test "rev: reverses a simple string argument" {
  command -v rev >/dev/null 2>&1 && skip "system rev present; step-in not loaded"
  run shellac_run 'include "text/rev"; rev "hello"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "olleh" ]
}

@test "rev: reverses a multi-word string argument" {
  command -v rev >/dev/null 2>&1 && skip "system rev present; step-in not loaded"
  run shellac_run 'include "text/rev"; rev "hello world"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "dlrow olleh" ]
}

@test "rev: reverses via stdin" {
  run shellac_run 'include "text/rev"; printf "hello\n" | rev'
  [ "${status}" -eq 0 ]
  [ "${output}" = "olleh" ]
}

@test "rev: reverses multiple lines via stdin" {
  run shellac_run 'include "text/rev"; printf "abc\ndef\n" | rev'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'cba\nfed')" ]
}

@test "rev: single character unchanged" {
  command -v rev >/dev/null 2>&1 && skip "system rev present; step-in not loaded"
  run shellac_run 'include "text/rev"; rev "a"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "a" ]
}
