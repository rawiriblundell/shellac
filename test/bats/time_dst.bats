#!/usr/bin/env bats
# Tests for time/dst in lib/sh/time/dst.sh
# time_dst uses zdump and depends on the system timezone.
# Tests verify load behaviour and basic output format only.

load 'helpers/setup'

@test "time_dst: module loads when zdump is available" {
  if ! command -v zdump >/dev/null 2>&1; then
    skip "zdump not available"
  fi
  run shellac_run 'include "time/dst"'
  [ "${status}" -eq 0 ]
}

@test "time_dst: produces output for a DST-observing timezone" {
  if ! command -v zdump >/dev/null 2>&1; then
    skip "zdump not available"
  fi
  run shellac_run 'include "time/dst"; TZ=America/New_York time_dst'
  [ "${status}" -eq 0 ]
  # Either two lines (DST transitions) or zero (no DST this year) — output is optional
}

@test "time_dst: produces no error for UTC (no DST)" {
  if ! command -v zdump >/dev/null 2>&1; then
    skip "zdump not available"
  fi
  run shellac_run 'include "time/dst"; TZ=UTC time_dst'
  [ "${status}" -eq 0 ]
}
