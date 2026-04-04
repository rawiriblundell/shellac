#!/usr/bin/env bats
# Tests for calc in lib/sh/numbers/calc.sh

load 'helpers/setup'
bats_require_minimum_version 1.5.0

@test "calc: simple addition" {
  run shellac_run 'include "numbers/calc"; calc "4 + 2"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "6" ]
}

@test "calc: floating point addition" {
  run shellac_run 'include "numbers/calc"; calc "4.2 + 2.6"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "6.8" ]
}

@test "calc: subtraction with parens" {
  run shellac_run 'include "numbers/calc"; calc "(4.2 + 2.6) - 3.5"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "3.3" ]
}

@test "calc: multiplication" {
  run shellac_run 'include "numbers/calc"; calc "3 * 7"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "21" ]
}

@test "calc: division" {
  run shellac_run 'include "numbers/calc"; calc "10 / 4"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "2.50000000000000000000" ]
}

@test "calc: missing argument fails" {
  run -127 shellac_run 'include "numbers/calc"; calc'
  [ "${status}" -ne 0 ]
}
