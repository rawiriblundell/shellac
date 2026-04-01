#!/usr/bin/env bats
# Tests for line/first (redirects to text/first.sh)

load 'helpers/setup'

@test "first: returns first line from stdin by default" {
  run shellac_run 'include "line/first"; printf "a\nb\nc\n" | first'
  [ "${status}" -eq 0 ]
  [ "${output}" = "a" ]
}

@test "first: row subcommand returns first line from stdin" {
  run shellac_run 'include "line/first"; printf "a\nb\nc\n" | first row'
  [ "${status}" -eq 0 ]
  [ "${output}" = "a" ]
}

@test "first: line subcommand returns first line from stdin" {
  run shellac_run 'include "line/first"; printf "a\nb\nc\n" | first line'
  [ "${status}" -eq 0 ]
  [ "${output}" = "a" ]
}

@test "first: col subcommand returns first column" {
  run shellac_run 'include "line/first"; printf "foo bar\nbaz qux\n" | first col'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'foo\nbaz')" ]
}

@test "first: column subcommand returns first column" {
  run shellac_run 'include "line/first"; printf "one two\nthree four\n" | first column'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'one\nthree')" ]
}

@test "first: char subcommand returns first character" {
  run shellac_run 'include "line/first"; printf "hello" | first char'
  [ "${status}" -eq 0 ]
  [ "${output}" = "h" ]
}

@test "last: returns last line from stdin by default" {
  run shellac_run 'include "line/first"; printf "a\nb\nc\n" | last'
  [ "${status}" -eq 0 ]
  [ "${output}" = "c" ]
}

@test "last: row subcommand returns last line" {
  run shellac_run 'include "line/first"; printf "a\nb\nc\n" | last row'
  [ "${status}" -eq 0 ]
  [ "${output}" = "c" ]
}

@test "last: col subcommand returns last column" {
  run shellac_run 'include "line/first"; printf "foo bar baz\n" | last col'
  [ "${status}" -eq 0 ]
  [ "${output}" = "baz" ]
}

@test "last: char subcommand returns last character" {
  run shellac_run 'include "line/first"; printf "hello" | last char'
  [ "${status}" -eq 0 ]
  [ "${output}" = "o" ]
}

@test "str_first: alias for first" {
  run shellac_run 'include "line/first"; printf "a\nb\nc\n" | str_first'
  [ "${status}" -eq 0 ]
  [ "${output}" = "a" ]
}

@test "str_last: alias for last" {
  run shellac_run 'include "line/first"; printf "a\nb\nc\n" | str_last'
  [ "${status}" -eq 0 ]
  [ "${output}" = "c" ]
}
