#!/usr/bin/env bats
# Tests for array_diff, array_intersect, array_union, array_unique
# in lib/sh/array/set.sh

load 'helpers/setup'

# ---------------------------------------------------------------------------
# array_diff
# ---------------------------------------------------------------------------

@test "array_diff: elements in first but not second" {
  run shellac_run 'include "array/set"
    arr1=(a b c d)
    arr2=(b d e)
    array_diff arr1 arr2'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a c)" ]
}

@test "array_diff: all elements in common returns nothing" {
  run shellac_run 'include "array/set"
    arr1=(a b)
    arr2=(a b c)
    array_diff arr1 arr2'
  [ "${status}" -eq 0 ]
  [ "${output}" = "" ]
}

@test "array_diff: no elements in common returns all of first" {
  run shellac_run 'include "array/set"
    arr1=(a b)
    arr2=(c d)
    array_diff arr1 arr2'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a b)" ]
}

# ---------------------------------------------------------------------------
# array_intersect
# ---------------------------------------------------------------------------

@test "array_intersect: common elements" {
  run shellac_run 'include "array/set"
    arr1=(a b c d)
    arr2=(b d e)
    array_intersect arr1 arr2'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' b d)" ]
}

@test "array_intersect: no common elements returns nothing" {
  run shellac_run 'include "array/set"
    arr1=(a b)
    arr2=(c d)
    array_intersect arr1 arr2'
  [ "${status}" -eq 0 ]
  [ "${output}" = "" ]
}

# ---------------------------------------------------------------------------
# array_union
# ---------------------------------------------------------------------------

@test "array_union: all unique elements from both arrays" {
  run shellac_run 'include "array/set"
    arr1=(a b c)
    arr2=(b c d e)
    array_union arr1 arr2'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a b c d e)" ]
}

@test "array_union: no duplicates in output" {
  run shellac_run 'include "array/set"
    arr1=(x y)
    arr2=(y z)
    array_union arr1 arr2'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' x y z)" ]
}

# ---------------------------------------------------------------------------
# array_unique
# ---------------------------------------------------------------------------

@test "array_unique: removes duplicate elements in place" {
  run shellac_run 'include "array/set"
    arr=(a b a c b d)
    array_unique arr
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a b c d)" ]
}

@test "array_unique: no change when already unique" {
  run shellac_run 'include "array/set"
    arr=(x y z)
    array_unique arr
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' x y z)" ]
}

@test "array_unique: preserves order" {
  run shellac_run 'include "array/set"
    arr=(c a b a c)
    array_unique arr
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' c a b)" ]
}
