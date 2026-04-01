#!/usr/bin/env bats
# Tests for line/filter in lib/sh/line/filter.sh

load 'helpers/setup'

@test "filter_first: returns first line of input" {
  run shellac_run 'include "line/filter"; printf "a\nb\nc\n" | filter_first'
  [ "${status}" -eq 0 ]
  [ "${output}" = "a" ]
}

@test "filter_not_first: returns all but the first line" {
  run shellac_run 'include "line/filter"; printf "a\nb\nc\n" | filter_not_first'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'b\nc')" ]
}

@test "filter_last: returns last line of input" {
  run shellac_run 'include "line/filter"; printf "a\nb\nc\n" | filter_last'
  [ "${status}" -eq 0 ]
  [ "${output}" = "c" ]
}

@test "filter_not_last: returns all but the last line" {
  run shellac_run 'include "line/filter"; printf "a\nb\nc\n" | filter_not_last'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'a\nb')" ]
}

@test "match_at_most_one: passes through a single line" {
  run shellac_run 'include "line/filter"; printf "only\n" | match_at_most_one'
  [ "${status}" -eq 0 ]
  [ "${output}" = "only" ]
}

@test "match_at_most_one: fails and emits nothing when given two lines" {
  run shellac_run 'include "line/filter"; printf "a\nb\n" | match_at_most_one'
  [ "${status}" -eq 1 ]
  [ "${output}" = "" ]
}

@test "match_at_most_one: passes through empty input with exit 0" {
  run shellac_run 'include "line/filter"; printf "" | match_at_most_one'
  [ "${status}" -eq 0 ]
}

@test "match_at_least_one: passes through when input has lines" {
  run shellac_run 'include "line/filter"; printf "hello\n" | match_at_least_one'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}

@test "match_at_least_one: fails when input is empty" {
  run shellac_run 'include "line/filter"; printf "" | match_at_least_one'
  [ "${status}" -eq 1 ]
}

@test "match_exactly_one: passes through exactly one line" {
  run shellac_run 'include "line/filter"; printf "only\n" | match_exactly_one'
  [ "${status}" -eq 0 ]
  [ "${output}" = "only" ]
}

@test "match_exactly_one: fails when given two lines" {
  run shellac_run 'include "line/filter"; printf "a\nb\n" | match_exactly_one'
  [ "${status}" -eq 1 ]
}

@test "match_exactly_one: fails when input is empty" {
  run shellac_run 'include "line/filter"; printf "" | match_exactly_one'
  [ "${status}" -eq 1 ]
}

@test "strip_trailing_newline: removes trailing newline" {
  run shellac_run 'include "line/filter"; printf "hello\n" | strip_trailing_newline'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}

@test "strip_trailing_newline: multi-line input has no trailing newline" {
  run shellac_run 'include "line/filter"; printf "a\nb\nc\n" | strip_trailing_newline'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'a\nb\nc')" ]
}
