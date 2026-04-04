#!/usr/bin/env bats
# Tests for array_length, array_count, array_keys, array_entries, array_print,
# array_has_key in lib/sh/array/length.sh

load 'helpers/setup'
bats_require_minimum_version 1.5.0

# ---------------------------------------------------------------------------
# array_length
# ---------------------------------------------------------------------------

@test "array_length: returns element count" {
  run shellac_run 'include "array/length"; arr=(a b c); array_length arr'
  [ "${status}" -eq 0 ]
  [ "${output}" = "3" ]
}

@test "array_length: empty array returns 0" {
  run shellac_run 'include "array/length"; arr=(); array_length arr'
  [ "${status}" -eq 0 ]
  [ "${output}" = "0" ]
}

@test "array_length: single element returns 1" {
  run shellac_run 'include "array/length"; arr=(x); array_length arr'
  [ "${status}" -eq 0 ]
  [ "${output}" = "1" ]
}

@test "array_length: missing array name fails" {
  run -127 shellac_run 'include "array/length"; array_length'
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# array_count
# ---------------------------------------------------------------------------

@test "array_count: counts occurrences of value" {
  run shellac_run 'include "array/length"; arr=(a b a c a); array_count arr a'
  [ "${status}" -eq 0 ]
  [ "${output}" = "3" ]
}

@test "array_count: value not present returns 0" {
  run shellac_run 'include "array/length"; arr=(a b c); array_count arr z'
  [ "${status}" -eq 0 ]
  [ "${output}" = "0" ]
}

@test "array_count: single occurrence" {
  run shellac_run 'include "array/length"; arr=(a b c); array_count arr b'
  [ "${status}" -eq 0 ]
  [ "${output}" = "1" ]
}

# ---------------------------------------------------------------------------
# array_keys
# ---------------------------------------------------------------------------

@test "array_keys: prints indices for indexed array" {
  run shellac_run 'include "array/length"; arr=(a b c); array_keys arr'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' 0 1 2)" ]
}

# ---------------------------------------------------------------------------
# array_entries
# ---------------------------------------------------------------------------

@test "array_entries: prints index:value pairs" {
  run shellac_run 'include "array/length"; arr=(a b c); array_entries arr'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' 0:a 1:b 2:c)" ]
}

# ---------------------------------------------------------------------------
# array_print
# ---------------------------------------------------------------------------

@test "array_print: prints key: value lines for indexed array" {
  run shellac_run 'include "array/length"; arr=(apple banana); array_print arr'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' '0: apple' '1: banana')" ]
}

@test "array_print: works for associative array" {
  run shellac_run 'include "array/length"
    declare -A colours=([red]="#ff0000")
    array_print colours'
  [ "${status}" -eq 0 ]
  [ "${output}" = "red: #ff0000" ]
}

# ---------------------------------------------------------------------------
# array_has_key
# ---------------------------------------------------------------------------

@test "array_has_key: returns 0 for present key" {
  run shellac_run 'include "array/length"
    declare -A h=([foo]=bar)
    array_has_key h foo'
  [ "${status}" -eq 0 ]
}

@test "array_has_key: returns 1 for absent key" {
  run shellac_run 'include "array/length"
    declare -A h=([foo]=bar)
    array_has_key h baz'
  [ "${status}" -ne 0 ]
}
