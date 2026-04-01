#!/usr/bin/env bats
# Tests for str_truncate in lib/sh/text/truncate.sh
# Note: str_truncate does not append a trailing newline.

load 'helpers/setup'

@test "str_truncate: truncates string to given length" {
  run shellac_run 'include "text/truncate"; str_truncate 10 "Hello, World!"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "Hello, Wor" ]
}

@test "str_truncate: string shorter than limit passes through unchanged" {
  run shellac_run 'include "text/truncate"; str_truncate 5 "Hi"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "Hi" ]
}

@test "str_truncate: string exactly at limit passes through unchanged" {
  run shellac_run 'include "text/truncate"; str_truncate 5 "Hello"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "Hello" ]
}

@test "str_truncate: -e flag appends ellipsis within given length" {
  run shellac_run 'include "text/truncate"; str_truncate -e 10 "Hello, World!"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "Hello, ..." ]
}

@test "str_truncate: -e with short string does not append ellipsis" {
  run shellac_run 'include "text/truncate"; str_truncate -e 10 "Hi"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "Hi" ]
}

@test "str_truncate: output length equals limit when truncating" {
  run shellac_run 'include "text/truncate"; out=$(str_truncate 7 "Hello, World!"); printf "%d\n" "${#out}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "7" ]
}

@test "str_truncate: -e output length equals limit when truncating" {
  run shellac_run 'include "text/truncate"; out=$(str_truncate -e 10 "Hello, World!"); printf "%d\n" "${#out}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "10" ]
}
