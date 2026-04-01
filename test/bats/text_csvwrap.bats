#!/usr/bin/env bats
# Tests for csvwrap in lib/sh/text/csvwrap.sh

load 'helpers/setup'

@test "csvwrap: wraps after default 8 elements" {
  run shellac_run 'include "text/csvwrap"; printf "%s\n" "a,b,c,d,e,f,g,h,i,j" | csvwrap'
  [ "${status}" -eq 0 ]
  # Should contain a backslash-newline continuation after 8th comma
  [[ "${output}" == *$',\\\n'* ]]
}

@test "csvwrap: wraps after custom count of 2" {
  run shellac_run 'include "text/csvwrap"; printf "%s\n" "a,b,c,d,e" | csvwrap 2'
  [ "${status}" -eq 0 ]
  # With split_count=2, we get a wrap after every 2nd comma
  [[ "${output}" == *$',\\\n'* ]]
}

@test "csvwrap: short list with default count has no continuation" {
  run shellac_run 'include "text/csvwrap"; printf "%s\n" "a,b,c" | csvwrap'
  [ "${status}" -eq 0 ]
  # Only 2 commas, fewer than 8, so no wrapping
  [[ "${output}" != *$',\\\n'* ]]
}

@test "csvwrap: input with no commas passes through unchanged" {
  run shellac_run 'include "text/csvwrap"; printf "%s\n" "nodcommas" | csvwrap'
  [ "${status}" -eq 0 ]
  [ "${output}" = "nodcommas" ]
}
