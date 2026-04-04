#!/usr/bin/env bats
# Tests for text_helmet / helmet in lib/sh/text/helmet.sh
# helmet emits the first N lines to stderr and the rest to stdout.

load 'helpers/setup'

bats_require_minimum_version 1.5.0

@test "helmet: first line goes to stderr, remainder to stdout" {
  run --separate-stderr shellac_run 'include "text/helmet"; printf "header\nrow1\nrow2\n" | helmet'
  [ "${status}" -eq 0 ]
  # stdout should contain only the body rows
  [ "${output}" = "$(printf 'row1\nrow2')" ]
}

@test "helmet: with count 2, first two lines go to stderr" {
  run --separate-stderr shellac_run 'include "text/helmet"; printf "h1\nh2\nbody\n" | helmet 2'
  [ "${status}" -eq 0 ]
  [ "${output}" = "body" ]
}

@test "helmet: single-line input (just a header) produces empty stdout" {
  run --separate-stderr shellac_run 'include "text/helmet"; printf "header\n" | helmet'
  [ "${status}" -eq 0 ]
  [ "${output}" = "" ]
}

@test "text_helmet: alias helmet works identically" {
  run --separate-stderr shellac_run 'include "text/helmet"; printf "header\nrow\n" | text_helmet'
  [ "${status}" -eq 0 ]
  [ "${output}" = "row" ]
}
