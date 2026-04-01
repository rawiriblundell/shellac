#!/usr/bin/env bats
# Tests for array_copy, array_concat, array_append, array_prepend, array_zip
# in lib/sh/array/concat.sh

load 'helpers/setup'

# ---------------------------------------------------------------------------
# array_copy
# ---------------------------------------------------------------------------

@test "array_copy: copies elements to destination" {
  run shellac_run 'include "array/concat"
    src=(a b c)
    array_copy src dst
    printf "%s\n" "${dst[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a b c)" ]
}

@test "array_copy: source is unchanged" {
  run shellac_run 'include "array/concat"
    src=(x y)
    array_copy src dst
    printf "%s\n" "${src[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' x y)" ]
}

# ---------------------------------------------------------------------------
# array_concat
# ---------------------------------------------------------------------------

@test "array_concat: appends second array to first" {
  run shellac_run 'include "array/concat"
    arr1=(a b c)
    arr2=(d e f)
    array_concat arr1 arr2
    printf "%s\n" "${arr1[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a b c d e f)" ]
}

@test "array_concat: multiple source arrays" {
  run shellac_run 'include "array/concat"
    dst=(a)
    s1=(b c)
    s2=(d e)
    array_concat dst s1 s2
    printf "%s\n" "${dst[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a b c d e)" ]
}

# ---------------------------------------------------------------------------
# array_append
# ---------------------------------------------------------------------------

@test "array_append: appends single element" {
  run shellac_run 'include "array/concat"
    arr=(a b c)
    array_append arr d
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a b c d)" ]
}

@test "array_append: appends multiple elements" {
  run shellac_run 'include "array/concat"
    arr=(a b)
    array_append arr c d e
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a b c d e)" ]
}

# ---------------------------------------------------------------------------
# array_prepend
# ---------------------------------------------------------------------------

@test "array_prepend: prepends single element" {
  run shellac_run 'include "array/concat"
    arr=(c d e)
    array_prepend arr b
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' b c d e)" ]
}

@test "array_prepend: prepends multiple elements" {
  run shellac_run 'include "array/concat"
    arr=(c d e)
    array_prepend arr a b
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a b c d e)" ]
}

# ---------------------------------------------------------------------------
# array_zip
# ---------------------------------------------------------------------------

@test "array_zip: pairs elements by index" {
  run shellac_run 'include "array/concat"
    keys=(a b c)
    vals=(1 2 3)
    array_zip keys vals'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' 'a 1' 'b 2' 'c 3')" ]
}

@test "array_zip: stops at shorter array length" {
  run shellac_run 'include "array/concat"
    a=(x y z)
    b=(1 2)
    array_zip a b'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' 'x 1' 'y 2')" ]
}
