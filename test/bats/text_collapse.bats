#!/usr/bin/env bats
# Tests for str_collapse in lib/sh/text/collapse.sh

load 'helpers/setup'

@test "str_collapse: collapses multiple spaces to one" {
  run shellac_run 'include "text/collapse"; str_collapse "foo   bar     baz"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "foo bar baz " ]
}

@test "str_collapse: single spaces unchanged (apart from trailing space from tr)" {
  run shellac_run 'include "text/collapse"; str_collapse "a b c"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "a b c " ]
}

@test "str_collapse: collapses tabs to spaces via stdin" {
  run shellac_run 'include "text/collapse"; printf "a\tb\tc\n" | str_collapse'
  [ "${status}" -eq 0 ]
  [ "${output}" = "a b c " ]
}

@test "str_collapse: handles single word" {
  run shellac_run 'include "text/collapse"; str_collapse "hello"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello " ]
}
