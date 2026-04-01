#!/usr/bin/env bats
# Tests for mapfile (step-in) in lib/sh/array/mapfile.sh
# The module only defines mapfile when the builtin is absent.
# Since we're on bash 4+, mapfile is a builtin and the step-in is not loaded.
# We test the builtin behaviour via include (which returns early if mapfile exists).

load 'helpers/setup'

@test "mapfile: reads lines from stdin into MAPFILE" {
  run shellac_run 'include "array/mapfile"
    mapfile -t < <(printf "%s\n" a b c)
    printf "%s\n" "${MAPFILE[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' a b c)" ]
}

@test "mapfile: reads lines into named array" {
  run shellac_run 'include "array/mapfile"
    mapfile -t myarr < <(printf "%s\n" x y z)
    printf "%s\n" "${myarr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' x y z)" ]
}

@test "mapfile: strips trailing newlines with -t" {
  run shellac_run 'include "array/mapfile"
    mapfile -t lines < <(printf "%s\n" "line1" "line2")
    printf "%d\n" "${#lines[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "2" ]
}
