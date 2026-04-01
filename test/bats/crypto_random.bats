#!/usr/bin/env bats
# Tests for crypto/random in lib/sh/crypto/random.sh

load 'helpers/setup'

setup() {
  :
}

teardown() {
  :
}

# ---------------------------------------------------------------------------
# random_seed
# ---------------------------------------------------------------------------

@test "random_seed: exits 0 and produces a numeric output" {
  run shellac_run 'include "crypto/random"; random_seed'
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]
  [[ "${output}" =~ ^[0-9]+$ ]]
}

# ---------------------------------------------------------------------------
# random_lcg
# ---------------------------------------------------------------------------

@test "random_lcg: produces one number by default" {
  run shellac_run 'include "crypto/random"; random_lcg'
  [ "${status}" -eq 0 ]
  count=$(printf '%s\n' "${output}" | wc -l | tr -d ' ')
  [ "${count}" -eq 1 ]
}

@test "random_lcg: output is a non-negative integer" {
  run shellac_run 'include "crypto/random"; random_lcg'
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9]+$ ]]
}

@test "random_lcg: output is in range 0-32767" {
  run shellac_run 'include "crypto/random"; random_lcg'
  [ "${status}" -eq 0 ]
  val="${output}"
  (( val >= 0 && val <= 32767 ))
}

@test "random_lcg: -n 5 produces five numbers" {
  run shellac_run 'include "crypto/random"; random_lcg 5'
  [ "${status}" -eq 0 ]
  count=$(printf '%s\n' "${output}" | wc -l | tr -d ' ')
  [ "${count}" -eq 5 ]
}

@test "random_lcg: same seed produces same sequence" {
  run shellac_run 'include "crypto/random"; random_lcg 3 42; random_lcg 3 42'
  [ "${status}" -eq 0 ]
  first_half=$(printf '%s\n' "${output}" | head -3 | paste -sd',')
  second_half=$(printf '%s\n' "${output}" | tail -3 | paste -sd',')
  [ "${first_half}" = "${second_half}" ]
}

# ---------------------------------------------------------------------------
# random_int
# ---------------------------------------------------------------------------

@test "random_int: produces one number by default" {
  run shellac_run 'include "crypto/random"; random_int'
  [ "${status}" -eq 0 ]
  count=$(printf '%s\n' "${output}" | wc -l | tr -d ' ')
  [ "${count}" -eq 1 ]
}

@test "random_int: output is in range 1-32767 (defaults)" {
  run shellac_run 'include "crypto/random"; random_int'
  [ "${status}" -eq 0 ]
  val="${output}"
  (( val >= 1 && val <= 32767 ))
}

@test "random_int: respects min and max bounds" {
  run shellac_run 'include "crypto/random"; random_int 1 5 10'
  [ "${status}" -eq 0 ]
  val="${output}"
  (( val >= 5 && val <= 10 ))
}

@test "random_int: count=5 produces five numbers" {
  run shellac_run 'include "crypto/random"; random_int 5 1 100'
  [ "${status}" -eq 0 ]
  count=$(printf '%s\n' "${output}" | wc -l | tr -d ' ')
  [ "${count}" -eq 5 ]
}

@test "random_int: returns exit 3 when min equals max" {
  run shellac_run 'include "crypto/random"; random_int 1 7 7'
  [ "${status}" -eq 3 ]
}

# ---------------------------------------------------------------------------
# random_xorshift128plus
# ---------------------------------------------------------------------------

@test "random_xorshift128plus: produces one number by default" {
  run shellac_run 'include "crypto/random"; random_xorshift128plus'
  [ "${status}" -eq 0 ]
  count=$(printf '%s\n' "${output}" | wc -l | tr -d ' ')
  [ "${count}" -eq 1 ]
}

@test "random_xorshift128plus: output is a non-negative integer" {
  run shellac_run 'include "crypto/random"; random_xorshift128plus'
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9]+$ ]]
}

@test "random_xorshift128plus: count=4 produces four numbers" {
  run shellac_run 'include "crypto/random"; random_xorshift128plus 4'
  [ "${status}" -eq 0 ]
  count=$(printf '%s\n' "${output}" | wc -l | tr -d ' ')
  [ "${count}" -eq 4 ]
}

@test "random_xorshift128plus: respects min/max range" {
  run shellac_run 'include "crypto/random"; random_xorshift128plus 1 10 20'
  [ "${status}" -eq 0 ]
  val="${output}"
  (( val >= 10 && val <= 20 ))
}
