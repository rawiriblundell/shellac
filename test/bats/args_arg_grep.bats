#!/usr/bin/env bats
# Tests for args/arg_grep in lib/sh/args/arg_grep.sh

load 'helpers/setup'

@test "arg_grep: finds a long flag" {
  run shellac_run 'include "args/arg_grep"; arg_grep --verbose --verbose --output file'
  [ "${status}" -eq 0 ]
}

@test "arg_grep: finds a short flag" {
  run shellac_run 'include "args/arg_grep"; arg_grep -v -v --output file'
  [ "${status}" -eq 0 ]
}

@test "arg_grep: finds a plain word" {
  run shellac_run 'include "args/arg_grep"; arg_grep debug --flag debug value'
  [ "${status}" -eq 0 ]
}

@test "arg_grep: returns 1 when flag is not present" {
  run shellac_run 'include "args/arg_grep"; arg_grep --missing --flag value'
  [ "${status}" -eq 1 ]
}

@test "arg_grep: returns 1 when argument list is empty" {
  run shellac_run 'include "args/arg_grep"; arg_grep --flag'
  [ "${status}" -eq 1 ]
}

@test "arg_grep: does not partially match flags" {
  run shellac_run 'include "args/arg_grep"; arg_grep --verb --verbose'
  [ "${status}" -eq 1 ]
}
