#!/usr/bin/env bats
# Tests for line/behead in lib/sh/line/behead.sh

load 'helpers/setup'

@test "behead: removes first line by default" {
  run shellac_run 'include "line/behead"; printf "a\nb\nc\n" | behead'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'b\nc')" ]
}

@test "behead: removes first N lines when given an argument" {
  run shellac_run 'include "line/behead"; printf "a\nb\nc\nd\n" | behead 2'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'c\nd')" ]
}

@test "behead: returns nothing when count equals total lines" {
  run shellac_run 'include "line/behead"; printf "a\nb\nc\n" | behead 3'
  [ "${status}" -eq 0 ]
  [ "${output}" = "" ]
}

@test "behead: returns nothing when count exceeds total lines" {
  run shellac_run 'include "line/behead"; printf "a\nb\n" | behead 5'
  [ "${status}" -eq 0 ]
  [ "${output}" = "" ]
}

@test "behead: behead 0 returns all lines" {
  run shellac_run 'include "line/behead"; printf "a\nb\nc\n" | behead 0'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'a\nb\nc')" ]
}

@test "behead: single line input removes all output by default" {
  run shellac_run 'include "line/behead"; printf "only\n" | behead'
  [ "${status}" -eq 0 ]
  [ "${output}" = "" ]
}
