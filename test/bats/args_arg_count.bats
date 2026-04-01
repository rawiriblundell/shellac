#!/usr/bin/env bats
# Tests for args/arg_count in lib/sh/args/arg_count.sh

load 'helpers/setup'

@test "arg_count: returns 0 when counts match" {
  run shellac_run 'include "args/arg_count"; arg_count 2 2'
  [ "${status}" -eq 0 ]
}

@test "arg_count: returns 0 for zero args" {
  run shellac_run 'include "args/arg_count"; arg_count 0 0'
  [ "${status}" -eq 0 ]
}

@test "arg_count: returns 1 when actual is less than desired" {
  run shellac_run 'include "args/arg_count"; arg_count 3 1'
  [ "${status}" -eq 1 ]
}

@test "arg_count: returns 1 when actual is more than desired" {
  run shellac_run 'include "args/arg_count"; arg_count 1 3'
  [ "${status}" -eq 1 ]
}

@test "arg_count: returns 1 when called with wrong number of args itself" {
  run shellac_run 'include "args/arg_count"; arg_count 1'
  [ "${status}" -eq 1 ]
}

@test "arg_count: returns 1 when desired count is non-integer" {
  run shellac_run 'include "args/arg_count"; arg_count abc 2'
  [ "${status}" -eq 1 ]
}

@test "arg_count: returns 1 when actual count is non-integer" {
  run shellac_run 'include "args/arg_count"; arg_count 2 abc'
  [ "${status}" -eq 1 ]
}

@test "arg_count: error message mentions not enough parameters" {
  run shellac_run 'include "args/arg_count"; arg_count 3 1 2>&1'
  [[ "${output}" == *"not enough parameters"* ]]
}

@test "arg_count: error message mentions too many parameters" {
  run shellac_run 'include "args/arg_count"; arg_count 1 3 2>&1'
  [[ "${output}" == *"too many parameters"* ]]
}
