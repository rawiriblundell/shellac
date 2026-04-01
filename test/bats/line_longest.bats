#!/usr/bin/env bats
# Tests for line/longest in lib/sh/line/longest.sh

load 'helpers/setup'

@test "longest: returns the longest line from stdin" {
  run shellac_run 'include "line/longest"; printf "hi\nhello\nyo\n" | longest'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}

@test "longest: returns the only line when given one line" {
  run shellac_run 'include "line/longest"; printf "onlyone\n" | longest'
  [ "${status}" -eq 0 ]
  [ "${output}" = "onlyone" ]
}

@test "longest: returns first encountered line when two are equal length" {
  run shellac_run 'include "line/longest"; printf "abc\ndef\n" | longest'
  [ "${status}" -eq 0 ]
  [ "${output}" = "abc" ]
}

@test "longest: returns empty string for empty input" {
  run shellac_run 'include "line/longest"; printf "" | longest'
  [ "${status}" -eq 0 ]
  [ "${output}" = "" ]
}
