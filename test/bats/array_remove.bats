#!/usr/bin/env bats
# Tests for array_clear, array_remove, array_remove_first, array_pop,
# array_insert, array_splice in lib/sh/array/remove.sh

load 'helpers/setup'

# ---------------------------------------------------------------------------
# array_clear
# ---------------------------------------------------------------------------

@test "array_clear: empties the array" {
  run shellac_run 'include "array/remove"
    arr=(a b c)
    array_clear arr
    printf "%d\n" "${#arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "0" ]
}

# ---------------------------------------------------------------------------
# array_remove
# ---------------------------------------------------------------------------

@test "array_remove: removes all matching elements" {
  run shellac_run 'include "array/remove"
    arr=(a b c b d)
    array_remove arr b
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a c d)" ]
}

@test "array_remove: no change when element not present" {
  run shellac_run 'include "array/remove"
    arr=(a b c)
    array_remove arr z
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a b c)" ]
}

# ---------------------------------------------------------------------------
# array_remove_first
# ---------------------------------------------------------------------------

@test "array_remove_first: removes only the first occurrence" {
  run shellac_run 'include "array/remove"
    arr=(a b c b d)
    array_remove_first arr b
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a c b d)" ]
}

@test "array_remove_first: no change when element not present" {
  run shellac_run 'include "array/remove"
    arr=(a b c)
    array_remove_first arr z
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a b c)" ]
}

# ---------------------------------------------------------------------------
# array_pop
# ---------------------------------------------------------------------------

@test "array_pop: prints and removes last element" {
  run shellac_run 'include "array/remove"
    arr=(a b c)
    array_pop arr
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' c a b)" ]
}

# ---------------------------------------------------------------------------
# array_insert
# ---------------------------------------------------------------------------

@test "array_insert: inserts element at given index" {
  run shellac_run 'include "array/remove"
    arr=(a b d e)
    array_insert arr 2 c
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a b c d e)" ]
}

@test "array_insert: inserts at index 0 prepends" {
  run shellac_run 'include "array/remove"
    arr=(b c)
    array_insert arr 0 a
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a b c)" ]
}

@test "array_insert: multiple elements inserted" {
  run shellac_run 'include "array/remove"
    arr=(a d)
    array_insert arr 1 b c
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a b c d)" ]
}

# ---------------------------------------------------------------------------
# array_splice
# ---------------------------------------------------------------------------

@test "array_splice: removes elements and prints them" {
  run shellac_run 'include "array/remove"
    arr=(a b c d e)
    array_splice arr 1 2'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' b c)" ]
}

@test "array_splice: array is modified after splice" {
  run shellac_run 'include "array/remove"
    arr=(a b c d e)
    array_splice arr 1 2 >/dev/null
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a d e)" ]
}

@test "array_splice: with replacement elements" {
  run shellac_run 'include "array/remove"
    arr=(a b c d e)
    array_splice arr 1 2 X Y >/dev/null
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a X Y d e)" ]
}

@test "array_splice: negative start index" {
  run shellac_run 'include "array/remove"
    arr=(a b c d e)
    array_splice arr -2 1'
  [ "${status}" -eq 0 ]
  [ "${output}" = "d" ]
}
