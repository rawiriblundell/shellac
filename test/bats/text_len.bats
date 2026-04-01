#!/usr/bin/env bats
# Tests for str_len, strlen, len, str_count, str_word_count
# in lib/sh/text/len.sh

load 'helpers/setup'

# ---------------------------------------------------------------------------
# str_len
# ---------------------------------------------------------------------------

@test "str_len: length of a simple string" {
  run shellac_run 'include "text/len"; str_len "hello"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "5" ]
}

@test "str_len: length of a multi-word string" {
  run shellac_run 'include "text/len"; str_len "hello world"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "11" ]
}

@test "str_len: -b flag returns byte length" {
  run shellac_run 'include "text/len"; str_len -b "hello"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "5" ]
}

@test "str_len: stdin mode prints length and content for each line" {
  run shellac_run 'include "text/len"; printf "hi\nhello\n" | str_len'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '2 hi\n5 hello')" ]
}

@test "str_len: empty string length is 0" {
  run shellac_run 'include "text/len"; str_len ""'
  [ "${status}" -eq 0 ]
  [ "${output}" = "0" ]
}

# ---------------------------------------------------------------------------
# strlen and len aliases
# ---------------------------------------------------------------------------

@test "strlen: alias for str_len" {
  run shellac_run 'include "text/len"; strlen "hello"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "5" ]
}

@test "len: alias for str_len" {
  run shellac_run 'include "text/len"; len "hello"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "5" ]
}

# ---------------------------------------------------------------------------
# str_count
# ---------------------------------------------------------------------------

@test "str_count: counts substring occurrences" {
  run shellac_run 'include "text/len"; str_count "banana" "an"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "2" ]
}

@test "str_count: single character occurrence" {
  run shellac_run 'include "text/len"; str_count "hello" "l"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "2" ]
}

@test "str_count: zero occurrences" {
  run shellac_run 'include "text/len"; str_count "hello" "z"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "0" ]
}

# ---------------------------------------------------------------------------
# str_word_count
# ---------------------------------------------------------------------------

@test "str_word_count: three words" {
  run shellac_run 'include "text/len"; str_word_count "hello world foo"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "3" ]
}

@test "str_word_count: extra spaces collapsed" {
  run shellac_run 'include "text/len"; str_word_count "  spaced  out  "'
  [ "${status}" -eq 0 ]
  [ "${output}" = "2" ]
}

@test "str_word_count: single word" {
  run shellac_run 'include "text/len"; str_word_count "hello"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "1" ]
}
