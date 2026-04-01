#!/usr/bin/env bats
# Tests for carve in lib/sh/text/carve.sh

load 'helpers/setup'

@test "carve: extracts substring between ordinal delimiters" {
  run shellac_run 'include "text/carve"; printf "%s\n" "a/b:c/d:e" | carve first : to 2nd :'
  [ "${status}" -eq 0 ]
  [ "${output}" = "c/d" ]
}

@test "carve: uses 'first' ordinal for start" {
  run shellac_run 'include "text/carve"; printf "%s\n" "a/b/c:end" | carve first / to first :'
  [ "${status}" -eq 0 ]
  [ "${output}" = "b/c" ]
}

@test "carve: uses 'last' ordinal for end delimiter" {
  run shellac_run 'include "text/carve"; printf "%s\n" "a:b:c:done" | carve first : to last :'
  [ "${status}" -eq 0 ]
  [ "${output}" = "b:c" ]
}

@test "carve: numeric ordinal (1st) for start" {
  run shellac_run 'include "text/carve"; printf "%s\n" "x/y/z:end" | carve 1st / to first :'
  [ "${status}" -eq 0 ]
  [ "${output}" = "y/z" ]
}

@test "carve: missing usage args prints to stderr and exits 0" {
  run shellac_run 'include "text/carve"; printf "%s\n" "a/b" | carve'
  [ "${status}" -eq 0 ]
}
