#!/usr/bin/env bats
# Tests for str_quote in lib/sh/text/quote.sh

load 'helpers/setup'

@test "str_quote: default wraps in double quotes" {
  run shellac_run 'include "text/quote"; str_quote "hello"'
  [ "${status}" -eq 0 ]
  [ "${output}" = '"hello"' ]
}

@test "str_quote: -d flag wraps in double quotes explicitly" {
  run shellac_run 'include "text/quote"; str_quote -d "hello"'
  [ "${status}" -eq 0 ]
  [ "${output}" = '"hello"' ]
}

@test "str_quote: -s flag wraps in single quotes" {
  run shellac_run "include \"text/quote\"; str_quote -s \"hello\""
  [ "${status}" -eq 0 ]
  [ "${output}" = "'hello'" ]
}

@test "str_quote: -P flag wraps in parentheses" {
  run shellac_run 'include "text/quote"; str_quote -P "hello"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "(hello)" ]
}

@test "str_quote: -C flag wraps in braces" {
  run shellac_run 'include "text/quote"; str_quote -C "hello"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "{hello}" ]
}

@test "str_quote: -S flag wraps in brackets" {
  run shellac_run 'include "text/quote"; str_quote -S "hello"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "[hello]" ]
}

@test "str_quote: -A flag wraps in chevrons" {
  run shellac_run 'include "text/quote"; str_quote -A "hello"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "<hello>" ]
}

@test "str_quote: -b flag wraps in backticks" {
  run shellac_run 'include "text/quote"; str_quote -b "hello"'
  [ "${status}" -eq 0 ]
  [ "${output}" = '`hello`' ]
}

@test "str_quote: multi-word input" {
  run shellac_run 'include "text/quote"; str_quote "hello world"'
  [ "${status}" -eq 0 ]
  [ "${output}" = '"hello world"' ]
}
