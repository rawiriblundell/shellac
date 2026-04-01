#!/usr/bin/env bats
# Tests for line/last (redirects to text/first.sh which contains last())

load 'helpers/setup'

@test "last: returns last line from stdin" {
  run shellac_run 'include "line/last"; printf "a\nb\nc\n" | last'
  [ "${status}" -eq 0 ]
  [ "${output}" = "c" ]
}

@test "last: line subcommand returns last line" {
  run shellac_run 'include "line/last"; printf "x\ny\nz\n" | last line'
  [ "${status}" -eq 0 ]
  [ "${output}" = "z" ]
}

@test "last: row subcommand returns last line" {
  run shellac_run 'include "line/last"; printf "x\ny\nz\n" | last row'
  [ "${status}" -eq 0 ]
  [ "${output}" = "z" ]
}

@test "last: col subcommand returns last column of each line" {
  run shellac_run 'include "line/last"; printf "a b c\nd e f\n" | last col'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'c\nf')" ]
}

@test "last: char subcommand returns last character of stdin" {
  run shellac_run 'include "line/last"; printf "hello" | last char'
  [ "${status}" -eq 0 ]
  [ "${output}" = "o" ]
}
