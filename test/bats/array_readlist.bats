#!/usr/bin/env bats
# Tests for readlist in lib/sh/array/readlist.sh

load 'helpers/setup'

@test "readlist: bare words stored in READLIST" {
  run shellac_run 'include "array/readlist"
    readlist dev, prod, test
    printf "%s\n" "${READLIST[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' dev prod test)" ]
}

@test "readlist: -n names the target array" {
  run shellac_run 'include "array/readlist"
    readlist -n envs "dev, prod, test"
    printf "%s\n" "${envs[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' dev prod test)" ]
}

@test "readlist: Python-style bracket notation stripped" {
  run shellac_run 'include "array/readlist"
    readlist "[dev, prod, test]"
    printf "%s\n" "${READLIST[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' dev prod test)" ]
}

@test "readlist: strips leading and trailing whitespace from elements" {
  run shellac_run 'include "array/readlist"
    readlist "  foo  ,  bar  ,  baz  "
    printf "%s\n" "${READLIST[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' foo bar baz)" ]
}

@test "readlist: single element" {
  run shellac_run 'include "array/readlist"
    readlist only
    printf "%s\n" "${READLIST[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "only" ]
}
