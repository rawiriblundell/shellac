#!/usr/bin/env bats
# Tests for str_before, str_after, str_substr, str_cut
# in lib/sh/text/substr.sh

load 'helpers/setup'

# ---------------------------------------------------------------------------
# str_before
# ---------------------------------------------------------------------------

@test "str_before: returns part before first delimiter" {
  run shellac_run 'include "text/substr"; str_before "foo:bar:baz" ":"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "foo" ]
}

@test "str_before: delimiter absent returns whole string" {
  run shellac_run 'include "text/substr"; str_before "foobar" ":"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "foobar" ]
}

# ---------------------------------------------------------------------------
# str_after
# ---------------------------------------------------------------------------

@test "str_after: returns part after first delimiter" {
  run shellac_run 'include "text/substr"; str_after "foo:bar:baz" ":"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "bar:baz" ]
}

@test "str_after: delimiter absent returns empty string" {
  run shellac_run 'include "text/substr"; str_after "foobar" ":"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "foobar" ]
}

# ---------------------------------------------------------------------------
# str_substr
# ---------------------------------------------------------------------------

@test "str_substr: extract from offset to end" {
  run shellac_run 'include "text/substr"; str_substr "hello world" 6'
  [ "${status}" -eq 0 ]
  [ "${output}" = "world" ]
}

@test "str_substr: extract with length" {
  run shellac_run 'include "text/substr"; str_substr "hello world" 0 5'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}

@test "str_substr: negative start index" {
  run shellac_run 'include "text/substr"; str_substr "hello world" -5'
  [ "${status}" -eq 0 ]
  [ "${output}" = "world" ]
}

# ---------------------------------------------------------------------------
# str_cut
# ---------------------------------------------------------------------------

@test "str_cut: removes chars from start by default" {
  run shellac_run 'include "text/substr"; str_cut "foobar" 3'
  [ "${status}" -eq 0 ]
  [ "${output}" = "bar" ]
}

@test "str_cut: removes chars from end" {
  run shellac_run 'include "text/substr"; str_cut "foobar" 3 end'
  [ "${status}" -eq 0 ]
  [ "${output}" = "foo" ]
}

@test "str_cut: removes chars from start explicitly" {
  run shellac_run 'include "text/substr"; str_cut "foobar" 2 start'
  [ "${status}" -eq 0 ]
  [ "${output}" = "obar" ]
}

@test "str_cut: unknown direction returns exit 1" {
  run shellac_run 'include "text/substr"; str_cut "foobar" 2 middle'
  [ "${status}" -eq 1 ]
}
