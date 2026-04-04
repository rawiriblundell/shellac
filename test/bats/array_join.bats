#!/usr/bin/env bats
# Tests for array_split and array_join in lib/sh/array/join.sh

load 'helpers/setup'
bats_require_minimum_version 1.5.0

# ---------------------------------------------------------------------------
# array_split
# ---------------------------------------------------------------------------

@test "array_split: splits on comma" {
  run shellac_run 'include "array/join"
    array_split arr , "a,b,c,d"
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a b c d)" ]
}

@test "array_split: splits on colon" {
  run shellac_run 'include "array/join"
    array_split arr : "foo:bar:baz"
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' foo bar baz)" ]
}

@test "array_split: single element string" {
  run shellac_run 'include "array/join"
    array_split arr , "only"
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "only" ]
}

@test "array_split: missing args fails" {
  run -127 shellac_run 'include "array/join"; array_split arr'
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# array_join
# ---------------------------------------------------------------------------

@test "array_join: joins with comma" {
  run shellac_run 'include "array/join"; array_join , a b c d'
  [ "${status}" -eq 0 ]
  [ "${output}" = "a,b,c,d" ]
}

@test "array_join: joins with pipe" {
  run shellac_run 'include "array/join"; array_join "|" a b c'
  [ "${status}" -eq 0 ]
  [ "${output}" = "a|b|c" ]
}

@test "array_join: multi-char delimiter" {
  run shellac_run 'include "array/join"; array_join "|||" a b c'
  [ "${status}" -eq 0 ]
  [ "${output}" = "a|||b|||c" ]
}

@test "array_join: single element" {
  run shellac_run 'include "array/join"; array_join , only'
  [ "${status}" -eq 0 ]
  [ "${output}" = "only" ]
}

@test "array_join: element with spaces" {
  run shellac_run 'include "array/join"
    arr=(a "b c" d)
    array_join , "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "a,b c,d" ]
}

@test "array_join: no arguments fails" {
  run shellac_run 'include "array/join"; array_join'
  [ "${status}" -ne 0 ]
}
