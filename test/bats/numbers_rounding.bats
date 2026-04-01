#!/usr/bin/env bats
# Tests for math_ceiling, ceiling, math_floor, floor, math_trunc, trunc, math_round, round
# in lib/sh/numbers/rounding.sh

load 'helpers/setup'

# ---------------------------------------------------------------------------
# math_ceiling / ceiling
# ---------------------------------------------------------------------------

@test "math_ceiling: rounds up fractional float" {
  run shellac_run 'include "numbers/rounding"; math_ceiling 3.4'
  [ "${status}" -eq 0 ]
  [ "${output}" = "4" ]
}

@test "math_ceiling: exact integer unchanged" {
  run shellac_run 'include "numbers/rounding"; math_ceiling 5'
  [ "${status}" -eq 0 ]
  [ "${output}" = "5" ]
}

@test "math_ceiling: rounds up 3.0001" {
  run shellac_run 'include "numbers/rounding"; math_ceiling 3.0001'
  [ "${status}" -eq 0 ]
  [ "${output}" = "4" ]
}

@test "ceiling: alias works identically" {
  run shellac_run 'include "numbers/rounding"; ceiling 2.1'
  [ "${status}" -eq 0 ]
  [ "${output}" = "3" ]
}

# ---------------------------------------------------------------------------
# math_floor / floor
# ---------------------------------------------------------------------------

@test "math_floor: rounds down fractional float" {
  run shellac_run 'include "numbers/rounding"; math_floor 3.7'
  [ "${status}" -eq 0 ]
  [ "${output}" = "3" ]
}

@test "math_floor: exact integer unchanged" {
  run shellac_run 'include "numbers/rounding"; math_floor 5'
  [ "${status}" -eq 0 ]
  [ "${output}" = "5" ]
}

@test "math_floor: negative float rounds toward negative infinity" {
  run shellac_run 'include "numbers/rounding"; math_floor -2.3'
  [ "${status}" -eq 0 ]
  [ "${output}" = "-2" ]
}

@test "floor: alias works identically" {
  run shellac_run 'include "numbers/rounding"; floor 7.9'
  [ "${status}" -eq 0 ]
  [ "${output}" = "7" ]
}

# ---------------------------------------------------------------------------
# math_trunc / trunc
# ---------------------------------------------------------------------------

@test "math_trunc: strips fractional part" {
  run shellac_run 'include "numbers/rounding"; math_trunc 3.7445'
  [ "${status}" -eq 0 ]
  [ "${output}" = "3" ]
}

@test "math_trunc: integer input returns integer" {
  run shellac_run 'include "numbers/rounding"; math_trunc 9'
  [ "${status}" -eq 0 ]
  [ "${output}" = "9" ]
}

@test "trunc: alias works identically" {
  run shellac_run 'include "numbers/rounding"; trunc 4.99'
  [ "${status}" -eq 0 ]
  [ "${output}" = "4" ]
}

# ---------------------------------------------------------------------------
# math_round / round  (bankers rounding by default)
# ---------------------------------------------------------------------------

@test "math_round: rounds down when fractional < 0.5" {
  run shellac_run 'include "numbers/rounding"; math_round 3.4'
  [ "${status}" -eq 0 ]
  [ "${output}" = "3" ]
}

@test "math_round: bankers rounding - 4.5 rounds to even 4" {
  run shellac_run 'include "numbers/rounding"; math_round 4.5'
  [ "${status}" -eq 0 ]
  [ "${output}" = "4" ]
}

@test "math_round: bankers rounding - 5.5 rounds to even 6" {
  run shellac_run 'include "numbers/rounding"; math_round 5.5'
  [ "${status}" -eq 0 ]
  [ "${output}" = "6" ]
}

@test "math_round: precision 2 returns two decimal places" {
  run shellac_run 'include "numbers/rounding"; math_round 3.4445 2'
  [ "${status}" -eq 0 ]
  [ "${output}" = "3.44" ]
}

@test "math_round: --common rounds 4.5 up to 5" {
  run shellac_run 'include "numbers/rounding"; math_round --common 4.5'
  [ "${status}" -eq 0 ]
  [ "${output}" = "5" ]
}

@test "round: alias works identically" {
  run shellac_run 'include "numbers/rounding"; round 2.6'
  [ "${status}" -eq 0 ]
  [ "${output}" = "3" ]
}
