#!/usr/bin/env bats
# Tests for str_repeat in lib/sh/text/repeat.sh

load 'helpers/setup'

@test "str_repeat: repeats string N times with newlines" {
  run shellac_run 'include "text/repeat"; str_repeat "ha" 3'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'ha\nha\nha')" ]
}

@test "str_repeat: default count is 1" {
  run shellac_run 'include "text/repeat"; str_repeat "hello"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}

@test "str_repeat: -n flag suppresses intermediate newlines" {
  run shellac_run 'include "text/repeat"; str_repeat -n "ab" 3'
  [ "${status}" -eq 0 ]
  [ "${output}" = "ababab" ]
}

@test "str_repeat: count 0 produces no output" {
  run shellac_run 'include "text/repeat"; str_repeat "x" 0'
  [ "${status}" -eq 0 ]
  [ "${output}" = "" ]
}
