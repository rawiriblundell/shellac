#!/usr/bin/env bats
# Tests for str_replace in lib/sh/text/replace.sh

load 'helpers/setup'

@test "str_replace: replaces all occurrences by default" {
  run shellac_run 'include "text/replace"; str_replace "aabbaa" "a" "x"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "xxbbxx" ]
}

@test "str_replace: replaces with empty string (deletion)" {
  run shellac_run 'include "text/replace"; str_replace "hello world" " " ""'
  [ "${status}" -eq 0 ]
  [ "${output}" = "helloworld" ]
}

@test "str_replace: count=1 replaces only first occurrence" {
  run shellac_run 'include "text/replace"; str_replace "aabaa" "a" "x" 1'
  [ "${status}" -eq 0 ]
  [ "${output}" = "xabaa" ]
}

@test "str_replace: count=2 replaces first two occurrences" {
  run shellac_run 'include "text/replace"; str_replace "aaabbb" "a" "x" 2'
  [ "${status}" -eq 0 ]
  [ "${output}" = "xxabbb" ]
}

@test "str_replace: no match leaves string unchanged" {
  run shellac_run 'include "text/replace"; str_replace "hello" "z" "x"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}
