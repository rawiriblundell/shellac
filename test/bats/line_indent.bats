#!/usr/bin/env bats
# Tests for line/indent in lib/sh/line/indent.sh

load 'helpers/setup'

@test "line_indent: indents with 2 spaces by default" {
  run shellac_run 'include "line/indent"; printf "hello\n" | line_indent'
  [ "${status}" -eq 0 ]
  [ "${output}" = "  hello" ]
}

@test "line_indent: indents with specified number of spaces" {
  run shellac_run 'include "line/indent"; printf "hello\n" | line_indent 4'
  [ "${status}" -eq 0 ]
  [ "${output}" = "    hello" ]
}

@test "line_indent: indents multiple lines" {
  run shellac_run 'include "line/indent"; printf "a\nb\nc\n" | line_indent'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '  a\n  b\n  c')" ]
}

@test "line_indent: indent of 0 spaces produces no indentation" {
  run shellac_run 'include "line/indent"; printf "hello\n" | line_indent 0'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}

@test "indent: alias for line_indent works" {
  run shellac_run 'include "line/indent"; printf "hello\n" | indent'
  [ "${status}" -eq 0 ]
  [ "${output}" = "  hello" ]
}

@test "str_indent: alias for line_indent works" {
  run shellac_run 'include "line/indent"; printf "hello\n" | str_indent 3'
  [ "${status}" -eq 0 ]
  [ "${output}" = "   hello" ]
}
