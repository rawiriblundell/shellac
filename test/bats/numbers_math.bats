#!/usr/bin/env bats
# Tests for num_abs, num_min, num_max, num_modulo, num_clamp in lib/sh/numbers/math.sh

load 'helpers/setup'

# ---------------------------------------------------------------------------
# num_abs
# ---------------------------------------------------------------------------

@test "num_abs: positive number returns unchanged" {
  run shellac_run 'include "numbers/math"; num_abs 5'
  [ "${status}" -eq 0 ]
  [ "${output}" = "5" ]
}

@test "num_abs: negative number returns positive" {
  run shellac_run 'include "numbers/math"; num_abs -5'
  [ "${status}" -eq 0 ]
  [ "${output}" = "5" ]
}

@test "num_abs: zero returns zero" {
  run shellac_run 'include "numbers/math"; num_abs 0'
  [ "${status}" -eq 0 ]
  [ "${output}" = "0" ]
}

@test "num_abs: missing argument fails" {
  run shellac_run 'include "numbers/math"; num_abs'
  [ "${status}" -ne 0 ]
}

@test "num_abs: non-integer argument fails" {
  run shellac_run 'include "numbers/math"; num_abs foo'
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# num_min
# ---------------------------------------------------------------------------

@test "num_min: returns smaller of two positive numbers" {
  run shellac_run 'include "numbers/math"; num_min 3 7'
  [ "${status}" -eq 0 ]
  [ "${output}" = "3" ]
}

@test "num_min: returns smaller when second is smaller" {
  run shellac_run 'include "numbers/math"; num_min 9 2'
  [ "${status}" -eq 0 ]
  [ "${output}" = "2" ]
}

@test "num_min: equal values returns the value" {
  run shellac_run 'include "numbers/math"; num_min 5 5'
  [ "${status}" -eq 0 ]
  [ "${output}" = "5" ]
}

@test "num_min: negative numbers" {
  run shellac_run 'include "numbers/math"; num_min -2 1'
  [ "${status}" -eq 0 ]
  [ "${output}" = "-2" ]
}

@test "num_min: missing second argument fails" {
  run shellac_run 'include "numbers/math"; num_min 3'
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# num_max
# ---------------------------------------------------------------------------

@test "num_max: returns larger of two positive numbers" {
  run shellac_run 'include "numbers/math"; num_max 3 7'
  [ "${status}" -eq 0 ]
  [ "${output}" = "7" ]
}

@test "num_max: returns larger when first is larger" {
  run shellac_run 'include "numbers/math"; num_max 9 2'
  [ "${status}" -eq 0 ]
  [ "${output}" = "9" ]
}

@test "num_max: equal values returns the value" {
  run shellac_run 'include "numbers/math"; num_max 4 4'
  [ "${status}" -eq 0 ]
  [ "${output}" = "4" ]
}

@test "num_max: negative and positive" {
  run shellac_run 'include "numbers/math"; num_max -2 1'
  [ "${status}" -eq 0 ]
  [ "${output}" = "1" ]
}

@test "num_max: missing second argument fails" {
  run shellac_run 'include "numbers/math"; num_max 3'
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# num_modulo
# ---------------------------------------------------------------------------

@test "num_modulo: basic positive modulo" {
  run shellac_run 'include "numbers/math"; num_modulo 10 3'
  [ "${status}" -eq 0 ]
  [ "${output}" = "1" ]
}

@test "num_modulo: exact division gives zero" {
  run shellac_run 'include "numbers/math"; num_modulo 9 3'
  [ "${status}" -eq 0 ]
  [ "${output}" = "0" ]
}

@test "num_modulo: negative dividend mathematical modulo" {
  run shellac_run 'include "numbers/math"; num_modulo -7 3'
  [ "${status}" -eq 0 ]
  [ "${output}" = "2" ]
}

@test "num_modulo: division by zero fails" {
  run shellac_run 'include "numbers/math"; num_modulo 10 0'
  [ "${status}" -ne 0 ]
}

@test "num_modulo: missing divisor fails" {
  run shellac_run 'include "numbers/math"; num_modulo 10'
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# num_clamp
# ---------------------------------------------------------------------------

@test "num_clamp: value within range is unchanged" {
  run shellac_run 'include "numbers/math"; num_clamp 5 0 10'
  [ "${status}" -eq 0 ]
  [ "${output}" = "5" ]
}

@test "num_clamp: value above max is clamped to max" {
  run shellac_run 'include "numbers/math"; num_clamp 15 0 10'
  [ "${status}" -eq 0 ]
  [ "${output}" = "10" ]
}

@test "num_clamp: value below min is clamped to min" {
  run shellac_run 'include "numbers/math"; num_clamp -3 0 10'
  [ "${status}" -eq 0 ]
  [ "${output}" = "0" ]
}

@test "num_clamp: value equal to min returns min" {
  run shellac_run 'include "numbers/math"; num_clamp 0 0 10'
  [ "${status}" -eq 0 ]
  [ "${output}" = "0" ]
}

@test "num_clamp: value equal to max returns max" {
  run shellac_run 'include "numbers/math"; num_clamp 10 0 10'
  [ "${status}" -eq 0 ]
  [ "${output}" = "10" ]
}

@test "num_clamp: missing max argument fails" {
  run shellac_run 'include "numbers/math"; num_clamp 5 0'
  [ "${status}" -ne 0 ]
}
