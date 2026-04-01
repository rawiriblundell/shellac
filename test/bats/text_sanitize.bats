#!/usr/bin/env bats
# Tests for str_sanitise / str_sanitize in lib/sh/text/sanitize.sh

load 'helpers/setup'

@test "str_sanitise: strips surrounding double quotes" {
  run shellac_run 'include "text/sanitize"; str_sanitise "\"hello\""'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}

@test "str_sanitise: strips surrounding single quotes" {
  run shellac_run "include \"text/sanitize\"; str_sanitise \"'hello'\""
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}

@test "str_sanitise: strips trailing colon and everything after" {
  run shellac_run 'include "text/sanitize"; str_sanitise "Bytes:"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "Bytes" ]
}

@test "str_sanitise: strips trailing equals and everything after" {
  run shellac_run 'include "text/sanitize"; str_sanitise "key="'
  [ "${status}" -eq 0 ]
  [ "${output}" = "key" ]
}

@test "str_sanitise: strips leading whitespace" {
  run shellac_run 'include "text/sanitize"; str_sanitise "  hello"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}

@test "str_sanitise: strips trailing whitespace" {
  run shellac_run 'include "text/sanitize"; str_sanitise "hello  "'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}

@test "str_sanitise: combined quotes and whitespace" {
  run shellac_run 'include "text/sanitize"; str_sanitise "\"  Bytes:  \""'
  [ "${status}" -eq 0 ]
  [ "${output}" = "Bytes" ]
}

@test "str_sanitize: alias works identically" {
  run shellac_run 'include "text/sanitize"; str_sanitize "\"hello\""'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}

@test "str_sanitise: plain string passes through unchanged" {
  run shellac_run 'include "text/sanitize"; str_sanitise "hello"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}
