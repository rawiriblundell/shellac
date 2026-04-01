#!/usr/bin/env bats
# Tests for time/date_arithmetic in lib/sh/time/date_arithmetic.sh

load 'helpers/setup'

# Use a fixed timestamp: 2024-01-15 12:00:00 UTC = 1705320000
FIXED_TS=1705320000

@test "time_add_days: adds 1 day by default" {
  run shellac_run "include \"time/date_arithmetic\"; time_add_days ${FIXED_TS}"
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9]+$ ]]
  (( output == FIXED_TS + 86400 ))
}

@test "time_add_days: adds N days" {
  run shellac_run "include \"time/date_arithmetic\"; time_add_days ${FIXED_TS} 7"
  [ "${status}" -eq 0 ]
  (( output == FIXED_TS + 7 * 86400 ))
}

@test "time_add_days: missing argument returns exit 2" {
  run shellac_run 'include "time/date_arithmetic"; time_add_days'
  [ "${status}" -eq 2 ]
}

@test "time_add_weeks: adds 1 week by default" {
  run shellac_run "include \"time/date_arithmetic\"; time_add_weeks ${FIXED_TS}"
  [ "${status}" -eq 0 ]
  (( output == FIXED_TS + 7 * 86400 ))
}

@test "time_add_weeks: missing argument returns exit 2" {
  run shellac_run 'include "time/date_arithmetic"; time_add_weeks'
  [ "${status}" -eq 2 ]
}

@test "time_add_months: adds 1 month by default" {
  run shellac_run "include \"time/date_arithmetic\"; time_add_months ${FIXED_TS}"
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9]+$ ]]
  (( output > FIXED_TS ))
}

@test "time_add_months: missing argument returns exit 2" {
  run shellac_run 'include "time/date_arithmetic"; time_add_months'
  [ "${status}" -eq 2 ]
}

@test "time_add_years: adds 1 year by default" {
  run shellac_run "include \"time/date_arithmetic\"; time_add_years ${FIXED_TS}"
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9]+$ ]]
  (( output > FIXED_TS ))
}

@test "time_add_years: missing argument returns exit 2" {
  run shellac_run 'include "time/date_arithmetic"; time_add_years'
  [ "${status}" -eq 2 ]
}

@test "time_add_hours: adds 1 hour by default" {
  run shellac_run "include \"time/date_arithmetic\"; time_add_hours ${FIXED_TS}"
  [ "${status}" -eq 0 ]
  (( output == FIXED_TS + 3600 ))
}

@test "time_add_hours: adds N hours" {
  run shellac_run "include \"time/date_arithmetic\"; time_add_hours ${FIXED_TS} 3"
  [ "${status}" -eq 0 ]
  (( output == FIXED_TS + 10800 ))
}

@test "time_add_hours: missing argument returns exit 2" {
  run shellac_run 'include "time/date_arithmetic"; time_add_hours'
  [ "${status}" -eq 2 ]
}

@test "time_add_minutes: adds 1 minute by default" {
  run shellac_run "include \"time/date_arithmetic\"; time_add_minutes ${FIXED_TS}"
  [ "${status}" -eq 0 ]
  (( output == FIXED_TS + 60 ))
}

@test "time_add_minutes: missing argument returns exit 2" {
  run shellac_run 'include "time/date_arithmetic"; time_add_minutes'
  [ "${status}" -eq 2 ]
}

@test "time_add_seconds: adds 1 second by default" {
  run shellac_run "include \"time/date_arithmetic\"; time_add_seconds ${FIXED_TS}"
  [ "${status}" -eq 0 ]
  (( output == FIXED_TS + 1 ))
}

@test "time_add_seconds: adds N seconds" {
  run shellac_run "include \"time/date_arithmetic\"; time_add_seconds ${FIXED_TS} 30"
  [ "${status}" -eq 0 ]
  (( output == FIXED_TS + 30 ))
}

@test "time_add_seconds: missing argument returns exit 2" {
  run shellac_run 'include "time/date_arithmetic"; time_add_seconds'
  [ "${status}" -eq 2 ]
}

@test "time_sub_days: subtracts 1 day by default" {
  run shellac_run "include \"time/date_arithmetic\"; time_sub_days ${FIXED_TS}"
  [ "${status}" -eq 0 ]
  (( output == FIXED_TS - 86400 ))
}

@test "time_sub_days: missing argument returns exit 2" {
  run shellac_run 'include "time/date_arithmetic"; time_sub_days'
  [ "${status}" -eq 2 ]
}

@test "time_sub_weeks: subtracts 1 week by default" {
  run shellac_run "include \"time/date_arithmetic\"; time_sub_weeks ${FIXED_TS}"
  [ "${status}" -eq 0 ]
  (( output == FIXED_TS - 7 * 86400 ))
}

@test "time_sub_weeks: missing argument returns exit 2" {
  run shellac_run 'include "time/date_arithmetic"; time_sub_weeks'
  [ "${status}" -eq 2 ]
}

@test "time_sub_months: subtracts 1 month by default" {
  run shellac_run "include \"time/date_arithmetic\"; time_sub_months ${FIXED_TS}"
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9]+$ ]]
  (( output < FIXED_TS ))
}

@test "time_sub_months: missing argument returns exit 2" {
  run shellac_run 'include "time/date_arithmetic"; time_sub_months'
  [ "${status}" -eq 2 ]
}

@test "time_sub_years: subtracts 1 year by default" {
  run shellac_run "include \"time/date_arithmetic\"; time_sub_years ${FIXED_TS}"
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9]+$ ]]
  (( output < FIXED_TS ))
}

@test "time_sub_years: missing argument returns exit 2" {
  run shellac_run 'include "time/date_arithmetic"; time_sub_years'
  [ "${status}" -eq 2 ]
}

@test "time_sub_hours: subtracts 1 hour by default" {
  run shellac_run "include \"time/date_arithmetic\"; time_sub_hours ${FIXED_TS}"
  [ "${status}" -eq 0 ]
  (( output == FIXED_TS - 3600 ))
}

@test "time_sub_hours: missing argument returns exit 2" {
  run shellac_run 'include "time/date_arithmetic"; time_sub_hours'
  [ "${status}" -eq 2 ]
}

@test "time_sub_minutes: subtracts 1 minute by default" {
  run shellac_run "include \"time/date_arithmetic\"; time_sub_minutes ${FIXED_TS}"
  [ "${status}" -eq 0 ]
  (( output == FIXED_TS - 60 ))
}

@test "time_sub_minutes: missing argument returns exit 2" {
  run shellac_run 'include "time/date_arithmetic"; time_sub_minutes'
  [ "${status}" -eq 2 ]
}

@test "time_sub_seconds: subtracts 1 second by default" {
  run shellac_run "include \"time/date_arithmetic\"; time_sub_seconds ${FIXED_TS}"
  [ "${status}" -eq 0 ]
  (( output == FIXED_TS - 1 ))
}

@test "time_sub_seconds: missing argument returns exit 2" {
  run shellac_run 'include "time/date_arithmetic"; time_sub_seconds'
  [ "${status}" -eq 2 ]
}

@test "time_format: formats a timestamp with default format" {
  run shellac_run "include \"time/date_arithmetic\"; TZ=UTC time_format ${FIXED_TS}"
  [ "${status}" -eq 0 ]
  [ "${output}" = "2024-01-15 12:00:00" ]
}

@test "time_format: formats with a custom format string" {
  run shellac_run "include \"time/date_arithmetic\"; TZ=UTC time_format ${FIXED_TS} '%Y-%m-%d'"
  [ "${status}" -eq 0 ]
  [ "${output}" = "2024-01-15" ]
}

@test "time_format: missing argument returns exit 2" {
  run shellac_run 'include "time/date_arithmetic"; time_format'
  [ "${status}" -eq 2 ]
}
