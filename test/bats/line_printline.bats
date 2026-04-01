#!/usr/bin/env bats
# Tests for line/printline in lib/sh/line/printline.sh

load 'helpers/setup'

@test "printline: prints the Nth line from stdin" {
  run shellac_run 'include "line/printline"; printf "a\nb\nc\n" | printline 2'
  [ "${status}" -eq 0 ]
  [ "${output}" = "b" ]
}

@test "printline: prints first line" {
  run shellac_run 'include "line/printline"; printf "a\nb\nc\n" | printline 1'
  [ "${status}" -eq 0 ]
  [ "${output}" = "a" ]
}

@test "printline: prints a range of lines" {
  run shellac_run 'include "line/printline"; printf "a\nb\nc\nd\n" | printline 2 3'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'b\nc')" ]
}

@test "printline: no argument prints usage and exits 0" {
  run shellac_run 'include "line/printline"; printline'
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"Usage"* ]]
}

@test "printline: non-numeric argument returns exit 1" {
  run shellac_run 'include "line/printline"; printf "a\nb\n" | printline abc'
  [ "${status}" -eq 1 ]
}

@test "printline: unreadable file returns exit 1" {
  run shellac_run 'include "line/printline"; printline 1 /no/such/file'
  [ "${status}" -eq 1 ]
}
