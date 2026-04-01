#!/usr/bin/env bats
# Tests for str_padding in lib/sh/text/padding.sh
# Note: str_padding falls back to tput cols when COLUMNS is unset.
# We set COLUMNS explicitly to get deterministic output.

load 'helpers/setup'

@test "str_padding: output contains key, dots, and value" {
  run shellac_run 'export COLUMNS=40; include "text/padding"; str_padding "Title" "Page1"'
  [ "${status}" -eq 0 ]
  [[ "${output}" == "Title"*"Page1" ]]
  [[ "${output}" == *"."* ]]
}

@test "str_padding: total output length equals COLUMNS" {
  run shellac_run 'export COLUMNS=40; include "text/padding"; out=$(str_padding "Key" "Val"); printf "%d\n" "${#out}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "40" ]
}

@test "str_padding: -w flag overrides width" {
  run shellac_run 'export COLUMNS=80; include "text/padding"; out=$(str_padding -w 30 "Key" "Val"); printf "%d\n" "${#out}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "30" ]
}

@test "str_padding: key and value are present in output" {
  run shellac_run 'export COLUMNS=40; include "text/padding"; str_padding "Hello" "World"'
  [ "${status}" -eq 0 ]
  [[ "${output}" == "Hello"* ]]
  [[ "${output}" == *"World" ]]
}
