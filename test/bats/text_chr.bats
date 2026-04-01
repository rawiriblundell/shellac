#!/usr/bin/env bats
# Tests for chr and ord in lib/sh/text/chr.sh

load 'helpers/setup'

# ---------------------------------------------------------------------------
# chr
# ---------------------------------------------------------------------------

@test "chr: decimal 65 produces A" {
  run shellac_run 'include "text/chr"; chr 65'
  [ "${status}" -eq 0 ]
  [ "${output}" = "A" ]
}

@test "chr: decimal 97 produces a" {
  run shellac_run 'include "text/chr"; chr 97'
  [ "${status}" -eq 0 ]
  [ "${output}" = "a" ]
}

@test "chr: decimal 48 produces 0" {
  run shellac_run 'include "text/chr"; chr 48'
  [ "${status}" -eq 0 ]
  [ "${output}" = "0" ]
}

@test "chr: value below 32 is shifted up by 32 (e.g. 1 -> 33 -> !)" {
  run shellac_run 'include "text/chr"; chr 1'
  [ "${status}" -eq 0 ]
  [ "${output}" = "!" ]
}

@test "chr: value above 126 is halved until in range" {
  run shellac_run 'include "text/chr"; chr 200'
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]
}

@test "chr: non-integer input returns exit code 1" {
  run shellac_run 'include "text/chr"; chr abc'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# ord
# ---------------------------------------------------------------------------

@test "ord: A returns 65" {
  run shellac_run 'include "text/chr"; ord A'
  [ "${status}" -eq 0 ]
  [ "${output}" = "65" ]
}

@test "ord: a returns 97" {
  run shellac_run 'include "text/chr"; ord a'
  [ "${status}" -eq 0 ]
  [ "${output}" = "97" ]
}

@test "ord: 0 returns 48" {
  run shellac_run 'include "text/chr"; ord 0'
  [ "${status}" -eq 0 ]
  [ "${output}" = "48" ]
}

@test "chr/ord: roundtrip A" {
  run shellac_run 'include "text/chr"; chr "$(ord A)"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "A" ]
}
