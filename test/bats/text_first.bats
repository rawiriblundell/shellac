#!/usr/bin/env bats
# Tests for first, last, str_first, str_last in lib/sh/text/first.sh

load 'helpers/setup'

# ---------------------------------------------------------------------------
# first
# ---------------------------------------------------------------------------

@test "first: returns first line of stdin (no subcommand)" {
  run shellac_run 'include "text/first"; printf "line1\nline2\nline3\n" | first'
  [ "${status}" -eq 0 ]
  [ "${output}" = "line1" ]
}

@test "first row: returns first line" {
  run shellac_run 'include "text/first"; printf "line1\nline2\n" | first row'
  [ "${status}" -eq 0 ]
  [ "${output}" = "line1" ]
}

@test "first line: alias for row" {
  run shellac_run 'include "text/first"; printf "line1\nline2\n" | first line'
  [ "${status}" -eq 0 ]
  [ "${output}" = "line1" ]
}

@test "first col: returns first column of each line" {
  run shellac_run 'include "text/first"; printf "a b c\nd e f\n" | first col'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'a\nd')" ]
}

@test "first column: alias for col" {
  run shellac_run 'include "text/first"; printf "a b c\n" | first column'
  [ "${status}" -eq 0 ]
  [ "${output}" = "a" ]
}

@test "first char: returns first character of stdin line" {
  run shellac_run 'include "text/first"; printf "hello\n" | first char'
  [ "${status}" -eq 0 ]
  [ "${output}" = "h" ]
}

# ---------------------------------------------------------------------------
# last
# ---------------------------------------------------------------------------

@test "last: returns last line of stdin (no subcommand)" {
  run shellac_run 'include "text/first"; printf "line1\nline2\nline3\n" | last'
  [ "${status}" -eq 0 ]
  [ "${output}" = "line3" ]
}

@test "last row: returns last line" {
  run shellac_run 'include "text/first"; printf "line1\nline2\n" | last row'
  [ "${status}" -eq 0 ]
  [ "${output}" = "line2" ]
}

@test "last col: returns last column of each line" {
  run shellac_run 'include "text/first"; printf "a b c\nd e f\n" | last col'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'c\nf')" ]
}

@test "last char: returns last character of stdin line" {
  run shellac_run 'include "text/first"; printf "hello\n" | last char'
  [ "${status}" -eq 0 ]
  [ "${output}" = "o" ]
}

# ---------------------------------------------------------------------------
# str_first / str_last aliases
# ---------------------------------------------------------------------------

@test "str_first: delegates to first" {
  run shellac_run 'include "text/first"; printf "line1\nline2\n" | str_first'
  [ "${status}" -eq 0 ]
  [ "${output}" = "line1" ]
}

@test "str_last: delegates to last" {
  run shellac_run 'include "text/first"; printf "line1\nline2\n" | str_last'
  [ "${status}" -eq 0 ]
  [ "${output}" = "line2" ]
}
