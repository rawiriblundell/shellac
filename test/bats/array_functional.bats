#!/usr/bin/env bats
# Tests for array_compact, array_filter, array_map, array_reduce
# in lib/sh/array/functional.sh

load 'helpers/setup'

# ---------------------------------------------------------------------------
# array_compact
# ---------------------------------------------------------------------------

@test "array_compact: removes empty elements" {
  run shellac_run 'include "array/functional"
    arr=(a "" b "" c)
    array_compact arr
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a b c)" ]
}

@test "array_compact: no change when no empty elements" {
  run shellac_run 'include "array/functional"
    arr=(x y z)
    array_compact arr
    printf "%s\n" "${arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' x y z)" ]
}

# ---------------------------------------------------------------------------
# array_filter
# ---------------------------------------------------------------------------

@test "array_filter: prints elements matching glob" {
  run shellac_run 'include "array/functional"
    arr=(apple banana cherry apricot)
    array_filter arr "a*"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' apple apricot)" ]
}

@test "array_filter: no match produces no output" {
  run shellac_run 'include "array/functional"
    arr=(apple banana cherry)
    array_filter arr "z*"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "" ]
}

@test "array_filter: exact match glob" {
  run shellac_run 'include "array/functional"
    arr=(a b c)
    array_filter arr "b"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "b" ]
}

# ---------------------------------------------------------------------------
# array_map
# ---------------------------------------------------------------------------

@test "array_map: applies function to each element" {
  run shellac_run 'include "array/functional"
    double() { printf "%s\n" "$(( $1 * 2 ))"; }
    arr=(1 2 3)
    array_map arr double'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' 2 4 6)" ]
}

@test "array_map: string transformation" {
  run shellac_run 'include "array/functional"
    upper() { printf "%s\n" "${1^^}"; }
    arr=(hello world)
    array_map arr upper'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' HELLO WORLD)" ]
}

# ---------------------------------------------------------------------------
# array_reduce
# ---------------------------------------------------------------------------

@test "array_reduce: sums elements with explicit initial value" {
  run shellac_run 'include "array/functional"
    add() { printf "%s\n" "$(( $1 + $2 ))"; }
    arr=(1 2 3 4 5)
    array_reduce arr add 0'
  [ "${status}" -eq 0 ]
  [ "${output}" = "15" ]
}

@test "array_reduce: uses first element as initial when no initial given" {
  run shellac_run 'include "array/functional"
    add() { printf "%s\n" "$(( $1 + $2 ))"; }
    arr=(10 5 3)
    array_reduce arr add'
  [ "${status}" -eq 0 ]
  [ "${output}" = "18" ]
}

@test "array_reduce: single element with no initial returns that element" {
  run shellac_run 'include "array/functional"
    add() { printf "%s\n" "$(( $1 + $2 ))"; }
    arr=(42)
    array_reduce arr add'
  [ "${status}" -eq 0 ]
  [ "${output}" = "42" ]
}
