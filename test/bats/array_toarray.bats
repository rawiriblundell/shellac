#!/usr/bin/env bats
# Tests for toarray in lib/sh/array/toarray.sh

load 'helpers/setup'

@test "toarray: collects stdin lines into named array" {
  run shellac_run 'include "array/toarray"
    printf "%s\n" a b c | toarray myarr
    printf "%s\n" "${myarr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a b c)" ]
}

@test "toarray: single line" {
  run shellac_run 'include "array/toarray"
    printf "%s\n" hello | toarray arr
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}

@test "toarray: correct element count" {
  run shellac_run 'include "array/toarray"
    printf "%s\n" x y z | toarray arr
    printf "%d\n" "${#arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "3" ]
}

@test "toarray: strips trailing newlines from elements" {
  run shellac_run 'include "array/toarray"
    printf "%s\n" "line1" "line2" | toarray arr
    printf "%s\n" "${arr[0]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "line1" ]
}

@test "toarray: missing array name fails" {
  run shellac_run 'include "array/toarray"; printf "a\n" | toarray'
  [ "${status}" -ne 0 ]
}
