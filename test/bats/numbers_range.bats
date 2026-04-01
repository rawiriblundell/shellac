#!/usr/bin/env bats
# Tests for range in lib/sh/numbers/range.sh

load 'helpers/setup'

@test "range: one arg generates 0 to n-1" {
  run shellac_run 'include "numbers/range"; range 5'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%d\n' 0 1 2 3 4)" ]
}

@test "range: one arg of 1 generates just 0" {
  run shellac_run 'include "numbers/range"; range 1'
  [ "${status}" -eq 0 ]
  [ "${output}" = "0" ]
}

@test "range: two args generates first to last inclusive" {
  run shellac_run 'include "numbers/range"; range 3 7'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%d\n' 3 4 5 6 7)" ]
}

@test "range: two args same value generates single number" {
  run shellac_run 'include "numbers/range"; range 5 5'
  [ "${status}" -eq 0 ]
  [ "${output}" = "5" ]
}

@test "range: three args with step" {
  run shellac_run 'include "numbers/range"; range 0 10 2'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%d\n' 0 2 4 6 8 10)" ]
}

@test "range: three args step of 3" {
  run shellac_run 'include "numbers/range"; range 1 10 3'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%d\n' 1 4 7 10)" ]
}

@test "range: no args fails with exit code 1" {
  run shellac_run 'include "numbers/range"; range'
  [ "${status}" -eq 1 ]
}
