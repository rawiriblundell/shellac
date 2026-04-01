#!/usr/bin/env bats
# Tests for time/date_ordinal in lib/sh/time/date_ordinal.sh
# The module overrides date() to support a %o format specifier for ordinal suffixes.

load 'helpers/setup'

@test "date ordinal: 1st gives 'st' suffix" {
  run shellac_run "include \"time/date_ordinal\"; TZ=UTC date -d '2024-01-01' '+%d%o'"
  [ "${status}" -eq 0 ]
  [ "${output}" = "01st" ]
}

@test "date ordinal: 2nd gives 'nd' suffix" {
  run shellac_run "include \"time/date_ordinal\"; TZ=UTC date -d '2024-01-02' '+%d%o'"
  [ "${status}" -eq 0 ]
  [ "${output}" = "02nd" ]
}

@test "date ordinal: 3rd gives 'rd' suffix" {
  run shellac_run "include \"time/date_ordinal\"; TZ=UTC date -d '2024-01-03' '+%d%o'"
  [ "${status}" -eq 0 ]
  [ "${output}" = "03rd" ]
}

@test "date ordinal: 4th gives 'th' suffix" {
  run shellac_run "include \"time/date_ordinal\"; TZ=UTC date -d '2024-01-04' '+%d%o'"
  [ "${status}" -eq 0 ]
  [ "${output}" = "04th" ]
}

@test "date ordinal: 11th gives 'th' suffix" {
  run shellac_run "include \"time/date_ordinal\"; TZ=UTC date -d '2024-01-11' '+%d%o'"
  [ "${status}" -eq 0 ]
  [ "${output}" = "11th" ]
}

@test "date ordinal: 21st gives 'st' suffix" {
  run shellac_run "include \"time/date_ordinal\"; TZ=UTC date -d '2024-01-21' '+%d%o'"
  [ "${status}" -eq 0 ]
  [ "${output}" = "21st" ]
}

@test "date ordinal: 22nd gives 'nd' suffix" {
  run shellac_run "include \"time/date_ordinal\"; TZ=UTC date -d '2024-01-22' '+%d%o'"
  [ "${status}" -eq 0 ]
  [ "${output}" = "22nd" ]
}

@test "date ordinal: 23rd gives 'rd' suffix" {
  run shellac_run "include \"time/date_ordinal\"; TZ=UTC date -d '2024-01-23' '+%d%o'"
  [ "${status}" -eq 0 ]
  [ "${output}" = "23rd" ]
}

@test "date ordinal: 31st gives 'st' suffix" {
  run shellac_run "include \"time/date_ordinal\"; TZ=UTC date -d '2024-01-31' '+%d%o'"
  [ "${status}" -eq 0 ]
  [ "${output}" = "31st" ]
}

@test "date: passes through to command date when no percent-o" {
  run shellac_run "include \"time/date_ordinal\"; TZ=UTC date -d '2024-01-15' '+%Y-%m-%d'"
  [ "${status}" -eq 0 ]
  [ "${output}" = "2024-01-15" ]
}
