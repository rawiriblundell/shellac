#!/usr/bin/env bats
# Tests for array_shift and array_rotate in lib/sh/array/shift.sh

load 'helpers/setup'

# ---------------------------------------------------------------------------
# array_shift
# ---------------------------------------------------------------------------

@test "array_shift: removes first element by default" {
  run shellac_run 'include "array/shift"
    arr=(a b c d)
    array_shift arr
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' b c d)" ]
}

@test "array_shift: removes first n elements" {
  run shellac_run 'include "array/shift"
    arr=(a b c d e)
    array_shift arr 2
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' c d e)" ]
}

@test "array_shift: shifting all elements leaves empty array" {
  run shellac_run 'include "array/shift"
    arr=(a b c)
    array_shift arr 3
    printf "%d\n" "${#arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "0" ]
}

# ---------------------------------------------------------------------------
# array_rotate
# ---------------------------------------------------------------------------

@test "array_rotate: rotates left by 1 by default" {
  run shellac_run 'include "array/shift"
    arr=(a b c d e)
    array_rotate arr
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' b c d e a)" ]
}

@test "array_rotate: rotates left by n" {
  run shellac_run 'include "array/shift"
    arr=(a b c d e)
    array_rotate arr 2
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' c d e a b)" ]
}

@test "array_rotate: negative n rotates right" {
  run shellac_run 'include "array/shift"
    arr=(a b c d e)
    array_rotate arr -1
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' e a b c d)" ]
}

@test "array_rotate: rotate by array length is a no-op" {
  run shellac_run 'include "array/shift"
    arr=(a b c)
    array_rotate arr 3
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a b c)" ]
}

@test "array_rotate: empty array is a no-op" {
  run shellac_run 'include "array/shift"
    arr=()
    array_rotate arr 2
    printf "%d\n" "${#arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "0" ]
}
