#!/usr/bin/env bats
# Tests for array_sum, array_min, array_max, array_product in lib/sh/array/aggregate.sh

load 'helpers/setup'
bats_require_minimum_version 1.5.0

# ---------------------------------------------------------------------------
# array_sum
# ---------------------------------------------------------------------------

@test "array_sum: sums all elements" {
  run shellac_run 'include "array/aggregate"; nums=(1 2 3 4 5); array_sum nums'
  [ "${status}" -eq 0 ]
  [ "${output}" = "15" ]
}

@test "array_sum: single element" {
  run shellac_run 'include "array/aggregate"; nums=(42); array_sum nums'
  [ "${status}" -eq 0 ]
  [ "${output}" = "42" ]
}

@test "array_sum: all zeros" {
  run shellac_run 'include "array/aggregate"; nums=(0 0 0); array_sum nums'
  [ "${status}" -eq 0 ]
  [ "${output}" = "0" ]
}

@test "array_sum: missing array name fails" {
  run -127 shellac_run 'include "array/aggregate"; array_sum'
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# array_min
# ---------------------------------------------------------------------------

@test "array_min: returns minimum element" {
  run shellac_run 'include "array/aggregate"; nums=(3 1 4 1 5 9); array_min nums'
  [ "${status}" -eq 0 ]
  [ "${output}" = "1" ]
}

@test "array_min: single element" {
  run shellac_run 'include "array/aggregate"; nums=(7); array_min nums'
  [ "${status}" -eq 0 ]
  [ "${output}" = "7" ]
}

@test "array_min: negative numbers" {
  run shellac_run 'include "array/aggregate"; nums=(5 -3 2); array_min nums'
  [ "${status}" -eq 0 ]
  [ "${output}" = "-3" ]
}

# ---------------------------------------------------------------------------
# array_max
# ---------------------------------------------------------------------------

@test "array_max: returns maximum element" {
  run shellac_run 'include "array/aggregate"; nums=(3 1 4 1 5 9); array_max nums'
  [ "${status}" -eq 0 ]
  [ "${output}" = "9" ]
}

@test "array_max: single element" {
  run shellac_run 'include "array/aggregate"; nums=(7); array_max nums'
  [ "${status}" -eq 0 ]
  [ "${output}" = "7" ]
}

@test "array_max: all same value" {
  run shellac_run 'include "array/aggregate"; nums=(4 4 4); array_max nums'
  [ "${status}" -eq 0 ]
  [ "${output}" = "4" ]
}

# ---------------------------------------------------------------------------
# array_product
# ---------------------------------------------------------------------------

@test "array_product: multiplies all elements" {
  run shellac_run 'include "array/aggregate"; nums=(2 3 4); array_product nums'
  [ "${status}" -eq 0 ]
  [ "${output}" = "24" ]
}

@test "array_product: single element" {
  run shellac_run 'include "array/aggregate"; nums=(5); array_product nums'
  [ "${status}" -eq 0 ]
  [ "${output}" = "5" ]
}

@test "array_product: containing zero gives zero" {
  run shellac_run 'include "array/aggregate"; nums=(2 3 0 4); array_product nums'
  [ "${status}" -eq 0 ]
  [ "${output}" = "0" ]
}
