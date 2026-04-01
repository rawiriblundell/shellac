#!/usr/bin/env bats
# Tests for str_squeeze, str_delete, str_reverse, str_abbreviate,
# str_expand_tabs, str_chunk, str_fields, str_chomp, str_chop
# in lib/sh/text/transform.sh

load 'helpers/setup'

# ---------------------------------------------------------------------------
# str_squeeze
# ---------------------------------------------------------------------------

@test "str_squeeze: collapses runs of spaces" {
  run shellac_run 'include "text/transform"; str_squeeze "hello   world"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello world" ]
}

@test "str_squeeze: custom char set" {
  run shellac_run 'include "text/transform"; str_squeeze "aabbccdd" "a-c"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "abcdd" ]
}

# ---------------------------------------------------------------------------
# str_delete
# ---------------------------------------------------------------------------

@test "str_delete: deletes specified characters" {
  run shellac_run 'include "text/transform"; str_delete "hello world" "lo"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "he wrd" ]
}

@test "str_delete: deletes digit range" {
  run shellac_run 'include "text/transform"; str_delete "abc123" "0-9"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "abc" ]
}

# ---------------------------------------------------------------------------
# str_reverse
# ---------------------------------------------------------------------------

@test "str_reverse: reverses a simple string" {
  run shellac_run 'include "text/transform"; str_reverse "hello"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "olleh" ]
}

@test "str_reverse: reverses a multi-word string" {
  run shellac_run 'include "text/transform"; str_reverse "hello world"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "dlrow olleh" ]
}

# ---------------------------------------------------------------------------
# str_abbreviate
# ---------------------------------------------------------------------------

@test "str_abbreviate: truncates with default ellipsis" {
  run shellac_run 'include "text/transform"; str_abbreviate "hello world" 8'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello..." ]
}

@test "str_abbreviate: short string not truncated" {
  run shellac_run 'include "text/transform"; str_abbreviate "hi" 10'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hi" ]
}

@test "str_abbreviate: exact length not truncated" {
  run shellac_run 'include "text/transform"; str_abbreviate "hello" 5'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}

# ---------------------------------------------------------------------------
# str_expand_tabs
# ---------------------------------------------------------------------------

@test "str_expand_tabs: expands tab to default 8 spaces" {
  run shellac_run $'include "text/transform"; str_expand_tabs "a\tb"'
  [ "${status}" -eq 0 ]
  # 'a' + 7 spaces + 'b' = 9 chars with default tab stop 8
  [ "${#output}" -eq 9 ]
}

@test "str_expand_tabs: custom tab stop 4" {
  run shellac_run $'include "text/transform"; str_expand_tabs "a\tb" 4'
  [ "${status}" -eq 0 ]
  [ "${#output}" -eq 5 ]
}

# ---------------------------------------------------------------------------
# str_chunk
# ---------------------------------------------------------------------------

@test "str_chunk: splits string into equal chunks" {
  run shellac_run 'include "text/transform"; str_chunk "abcdefgh" 3'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'abc\ndef\ngh')" ]
}

@test "str_chunk: chunk size equals string length gives one chunk" {
  run shellac_run 'include "text/transform"; str_chunk "hello" 5'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}

# ---------------------------------------------------------------------------
# str_fields
# ---------------------------------------------------------------------------

@test "str_fields: all fields printed one per line" {
  run shellac_run 'include "text/transform"; str_fields "a:b:c" ":"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'a\nb\nc')" ]
}

@test "str_fields: specific field extracted" {
  run shellac_run 'include "text/transform"; str_fields "a:b:c" ":" 2'
  [ "${status}" -eq 0 ]
  [ "${output}" = "b" ]
}

@test "str_fields: multiple specific fields" {
  run shellac_run 'include "text/transform"; str_fields "a:b:c" ":" 1 3'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'a\nc')" ]
}

# ---------------------------------------------------------------------------
# str_chomp / chomp
# ---------------------------------------------------------------------------

@test "str_chomp: removes trailing newline from string" {
  run shellac_run $'include "text/transform"; str_chomp "hello\n"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}

@test "str_chomp: string without trailing newline unchanged" {
  run shellac_run 'include "text/transform"; str_chomp "hello"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}

@test "chomp: alias for str_chomp" {
  run shellac_run $'include "text/transform"; chomp "hello\n"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}

# ---------------------------------------------------------------------------
# str_chop / chop
# ---------------------------------------------------------------------------

@test "str_chop: removes last character by default" {
  run shellac_run 'include "text/transform"; str_chop "hello,"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}

@test "str_chop: -n removes last N characters" {
  run shellac_run 'include "text/transform"; str_chop -n 3 "hello..."'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}

@test "chop: alias for str_chop" {
  run shellac_run 'include "text/transform"; chop "hello,"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}
