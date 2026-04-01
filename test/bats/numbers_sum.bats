#!/usr/bin/env bats
# Tests for sum and average in lib/sh/numbers/sum.sh

load 'helpers/setup'

# ---------------------------------------------------------------------------
# sum
# ---------------------------------------------------------------------------

@test "sum: positional args" {
  run shellac_run 'include "numbers/sum"; sum 1 2 3'
  [ "${status}" -eq 0 ]
  [ "${output}" = "6" ]
}

@test "sum: single value" {
  run shellac_run 'include "numbers/sum"; sum 42'
  [ "${status}" -eq 0 ]
  [ "${output}" = "42" ]
}

@test "sum: zero values sum to zero" {
  run shellac_run 'include "numbers/sum"; sum 0 0 0'
  [ "${status}" -eq 0 ]
  [ "${output}" = "0" ]
}

@test "sum: skips non-integer args" {
  run shellac_run 'include "numbers/sum"; sum 1 foo 3'
  [ "${status}" -eq 0 ]
  [ "${output}" = "4" ]
}

@test "sum: no args prints 0" {
  run shellac_run 'include "numbers/sum"; sum 0'
  [ "${status}" -eq 0 ]
  [ "${output}" = "0" ]
}

@test "sum: --help flag exits 0" {
  run shellac_run 'include "numbers/sum"; sum --help'
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# average
# ---------------------------------------------------------------------------

@test "average: multiple positional args" {
  run shellac_run 'include "numbers/sum"; average 1 2 3 4 5'
  [ "${status}" -eq 0 ]
  [ "${output}" = "3" ]
}

@test "average: two values" {
  run shellac_run 'include "numbers/sum"; average 10 20'
  [ "${status}" -eq 0 ]
  [ "${output}" = "15" ]
}

@test "average: single value returns that value" {
  run shellac_run 'include "numbers/sum"; average 7'
  [ "${status}" -eq 0 ]
  [ "${output}" = "7" ]
}
