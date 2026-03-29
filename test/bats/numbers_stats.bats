#!/usr/bin/env bats
# Tests for numbers_sum, numbers_min, numbers_max, numbers_mean,
# numbers_median, numbers_mode, numbers_stdev, numbers_stdev_sample
# in lib/sh/numbers/stats.sh

load 'helpers/setup'

# ---------------------------------------------------------------------------
# numbers_sum
# ---------------------------------------------------------------------------

@test "numbers_sum: integers" {
  run shellac_run 'include "numbers/stats"; numbers_sum 1 2 3'
  [ "${status}" -eq 0 ]
  [ "${output}" = "6" ]
}

@test "numbers_sum: floats" {
  run shellac_run 'include "numbers/stats"; numbers_sum 1.5 2.5'
  [ "${status}" -eq 0 ]
  [ "${output}" = "4" ]
}

@test "numbers_sum: negative values" {
  run shellac_run 'include "numbers/stats"; numbers_sum -3 5 -2'
  [ "${status}" -eq 0 ]
  [ "${output}" = "0" ]
}

@test "numbers_sum: single value" {
  run shellac_run 'include "numbers/stats"; numbers_sum 42'
  [ "${status}" -eq 0 ]
  [ "${output}" = "42" ]
}

@test "numbers_sum: reads from stdin" {
  run shellac_run 'include "numbers/stats"; seq 1 10 | numbers_sum'
  [ "${status}" -eq 0 ]
  [ "${output}" = "55" ]
}

# ---------------------------------------------------------------------------
# numbers_min
# ---------------------------------------------------------------------------

@test "numbers_min: basic list" {
  run shellac_run 'include "numbers/stats"; numbers_min 3 1 4 1 5 9'
  [ "${status}" -eq 0 ]
  [ "${output}" = "1" ]
}

@test "numbers_min: negative values" {
  run shellac_run 'include "numbers/stats"; numbers_min 0 -5 3'
  [ "${status}" -eq 0 ]
  [ "${output}" = "-5" ]
}

@test "numbers_min: single value" {
  run shellac_run 'include "numbers/stats"; numbers_min 7'
  [ "${status}" -eq 0 ]
  [ "${output}" = "7" ]
}

@test "numbers_min: reads from stdin" {
  run shellac_run 'include "numbers/stats"; seq 10 -1 1 | numbers_min'
  [ "${status}" -eq 0 ]
  [ "${output}" = "1" ]
}

# ---------------------------------------------------------------------------
# numbers_max
# ---------------------------------------------------------------------------

@test "numbers_max: basic list" {
  run shellac_run 'include "numbers/stats"; numbers_max 3 1 4 1 5 9'
  [ "${status}" -eq 0 ]
  [ "${output}" = "9" ]
}

@test "numbers_max: negative values" {
  run shellac_run 'include "numbers/stats"; numbers_max -5 -3 -1'
  [ "${status}" -eq 0 ]
  [ "${output}" = "-1" ]
}

@test "numbers_max: reads from stdin" {
  run shellac_run 'include "numbers/stats"; seq 1 10 | numbers_max'
  [ "${status}" -eq 0 ]
  [ "${output}" = "10" ]
}

# ---------------------------------------------------------------------------
# numbers_mean
# ---------------------------------------------------------------------------

@test "numbers_mean: integer result" {
  run shellac_run 'include "numbers/stats"; numbers_mean 1 2 3'
  [ "${status}" -eq 0 ]
  [ "${output}" = "2" ]
}

@test "numbers_mean: fractional result" {
  run shellac_run 'include "numbers/stats"; numbers_mean 1 2'
  [ "${status}" -eq 0 ]
  [ "${output}" = "1.5" ]
}

@test "numbers_mean: single value is itself" {
  run shellac_run 'include "numbers/stats"; numbers_mean 7'
  [ "${status}" -eq 0 ]
  [ "${output}" = "7" ]
}

@test "numbers_mean: reads from stdin" {
  run shellac_run 'include "numbers/stats"; seq 1 10 | numbers_mean'
  [ "${status}" -eq 0 ]
  [ "${output}" = "5.5" ]
}

@test "numbers_mean: negative values" {
  run shellac_run 'include "numbers/stats"; numbers_mean -1 0 1'
  [ "${status}" -eq 0 ]
  [ "${output}" = "0" ]
}

# ---------------------------------------------------------------------------
# numbers_median
# ---------------------------------------------------------------------------

@test "numbers_median: odd count returns middle value" {
  run shellac_run 'include "numbers/stats"; numbers_median 3 1 4 1 5'
  [ "${status}" -eq 0 ]
  [ "${output}" = "3" ]
}

@test "numbers_median: even count returns mean of two middle values" {
  run shellac_run 'include "numbers/stats"; numbers_median 1 2 3 4'
  [ "${status}" -eq 0 ]
  [ "${output}" = "2.5" ]
}

@test "numbers_median: single value" {
  run shellac_run 'include "numbers/stats"; numbers_median 42'
  [ "${status}" -eq 0 ]
  [ "${output}" = "42" ]
}

@test "numbers_median: unsorted input is sorted before calculation" {
  run shellac_run 'include "numbers/stats"; numbers_median 9 1 5'
  [ "${status}" -eq 0 ]
  [ "${output}" = "5" ]
}

@test "numbers_median: reads from stdin" {
  run shellac_run 'include "numbers/stats"; seq 1 9 | numbers_median'
  [ "${status}" -eq 0 ]
  [ "${output}" = "5" ]
}

# ---------------------------------------------------------------------------
# numbers_mode
# ---------------------------------------------------------------------------

@test "numbers_mode: single most frequent value" {
  run shellac_run 'include "numbers/stats"; numbers_mode 1 2 2 3 3 3'
  [ "${status}" -eq 0 ]
  [ "${output}" = "3" ]
}

@test "numbers_mode: tie returns smallest" {
  run shellac_run 'include "numbers/stats"; numbers_mode 1 1 2 2'
  [ "${status}" -eq 0 ]
  [ "${output}" = "1" ]
}

@test "numbers_mode: single value" {
  run shellac_run 'include "numbers/stats"; numbers_mode 7'
  [ "${status}" -eq 0 ]
  [ "${output}" = "7" ]
}

@test "numbers_mode: reads from stdin" {
  run shellac_run 'include "numbers/stats"; printf "%s\n" 1 2 2 3 | numbers_mode'
  [ "${status}" -eq 0 ]
  [ "${output}" = "2" ]
}

# ---------------------------------------------------------------------------
# numbers_stdev (population)
# ---------------------------------------------------------------------------

@test "numbers_stdev: known result 2 4 4 4 5 5 7 9 = 2" {
  run shellac_run 'include "numbers/stats"; numbers_stdev 2 4 4 4 5 5 7 9'
  [ "${status}" -eq 0 ]
  [ "${output}" = "2" ]
}

@test "numbers_stdev: single value returns 0" {
  run shellac_run 'include "numbers/stats"; numbers_stdev 5'
  [ "${status}" -eq 0 ]
  [ "${output}" = "0" ]
}

@test "numbers_stdev: identical values return 0" {
  run shellac_run 'include "numbers/stats"; numbers_stdev 3 3 3 3'
  [ "${status}" -eq 0 ]
  [ "${output}" = "0" ]
}

@test "numbers_stdev: reads from stdin" {
  run shellac_run 'include "numbers/stats"; printf "%s\n" 2 4 4 4 5 5 7 9 | numbers_stdev'
  [ "${status}" -eq 0 ]
  [ "${output}" = "2" ]
}

# ---------------------------------------------------------------------------
# numbers_stdev_sample
# ---------------------------------------------------------------------------

@test "numbers_stdev_sample: two values" {
  run shellac_run 'include "numbers/stats"; numbers_stdev_sample 2 4'
  [ "${status}" -eq 0 ]
  [ "${output}" = "1.41421" ]
}

@test "numbers_stdev_sample: single value returns exit 1" {
  run shellac_run 'include "numbers/stats"; numbers_stdev_sample 5'
  [ "${status}" -eq 1 ]
}

@test "numbers_stdev_sample: reads from stdin" {
  run shellac_run 'include "numbers/stats"; printf "%s\n" 2 4 | numbers_stdev_sample'
  [ "${status}" -eq 0 ]
  [ "${output}" = "1.41421" ]
}
