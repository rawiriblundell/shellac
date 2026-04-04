#!/usr/bin/env bats
# Tests for array_fill, array_pad, array_range in lib/sh/array/fill.sh

load 'helpers/setup'
bats_require_minimum_version 1.5.0

# ---------------------------------------------------------------------------
# array_fill
# ---------------------------------------------------------------------------

@test "array_fill: fills array with value n times" {
  run shellac_run 'include "array/fill"
    array_fill arr x 3
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' x x x)" ]
}

@test "array_fill: count of 1" {
  run shellac_run 'include "array/fill"
    array_fill arr hello 1
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}

@test "array_fill: replaces existing contents" {
  run shellac_run 'include "array/fill"
    arr=(a b c)
    array_fill arr z 2
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' z z)" ]
}

@test "array_fill: missing args fails" {
  run -127 shellac_run 'include "array/fill"; array_fill arr'
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# array_pad
# ---------------------------------------------------------------------------

@test "array_pad: pads short array to minimum length" {
  run shellac_run 'include "array/fill"
    arr=(a b c)
    array_pad arr 5 x
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a b c x x)" ]
}

@test "array_pad: no effect when array already at minimum length" {
  run shellac_run 'include "array/fill"
    arr=(a b c)
    array_pad arr 3 x
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a b c)" ]
}

@test "array_pad: no effect when array exceeds minimum length" {
  run shellac_run 'include "array/fill"
    arr=(a b c d e)
    array_pad arr 3 x
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a b c d e)" ]
}

# ---------------------------------------------------------------------------
# array_range
# ---------------------------------------------------------------------------

@test "array_range: generates inclusive range" {
  run shellac_run 'include "array/fill"
    array_range arr 1 5
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' 1 2 3 4 5)" ]
}

@test "array_range: step of 2" {
  run shellac_run 'include "array/fill"
    array_range arr 0 8 2
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' 0 2 4 6 8)" ]
}

@test "array_range: single element when start equals end" {
  run shellac_run 'include "array/fill"
    array_range arr 5 5
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "5" ]
}
