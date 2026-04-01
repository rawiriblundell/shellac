#!/usr/bin/env bats
# Tests for puts in lib/sh/text/puts.sh

load 'helpers/setup'

@test "puts: plain string with trailing newline" {
  run shellac_run 'include "text/puts"; puts "hello"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}

@test "puts: -e flag expands escape sequences" {
  run shellac_run 'include "text/puts"; puts -e "line1\nline2"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'line1\nline2')" ]
}

@test "puts: -E flag suppresses escape expansion" {
  run shellac_run 'include "text/puts"; puts -E "line1\nline2"'
  [ "${status}" -eq 0 ]
  [ "${output}" = 'line1\nline2' ]
}

@test "puts: -n suppresses trailing newline (output matches raw printf)" {
  run shellac_run 'include "text/puts"; out=$(puts -n "hello"); printf "%d" "${#out}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "5" ]
}

@test "puts: -j outputs JSON key-value" {
  run shellac_run 'include "text/puts"; puts -j "key" "value"'
  [ "${status}" -eq 0 ]
  [ "${output}" = '{"key": "value"}' ]
}

@test "puts: -en flag expands escapes and suppresses newline" {
  run shellac_run 'include "text/puts"; out=$(puts -en "a\tb"); printf "%s" "${out}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'a\tb')" ]
}

@test "puts: multiple words joined" {
  run shellac_run 'include "text/puts"; puts "hello" "world"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello world" ]
}
