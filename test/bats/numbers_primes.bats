#!/usr/bin/env bats
# Tests for is_prime in lib/sh/numbers/primes.sh

load 'helpers/setup'

@test "is_prime: 2 is prime" {
  run shellac_run 'include "numbers/primes"; is_prime 2'
  [ "${status}" -eq 0 ]
}

@test "is_prime: 3 is prime" {
  run shellac_run 'include "numbers/primes"; is_prime 3'
  [ "${status}" -eq 0 ]
}

@test "is_prime: 5 is prime" {
  run shellac_run 'include "numbers/primes"; is_prime 5'
  [ "${status}" -eq 0 ]
}

@test "is_prime: 7 is prime" {
  run shellac_run 'include "numbers/primes"; is_prime 7'
  [ "${status}" -eq 0 ]
}

@test "is_prime: 13 is prime" {
  run shellac_run 'include "numbers/primes"; is_prime 13'
  [ "${status}" -eq 0 ]
}

@test "is_prime: 97 is prime" {
  run shellac_run 'include "numbers/primes"; is_prime 97'
  [ "${status}" -eq 0 ]
}

@test "is_prime: 1 is not prime" {
  run shellac_run 'include "numbers/primes"; is_prime 1'
  [ "${status}" -ne 0 ]
}

@test "is_prime: 0 is not prime" {
  run shellac_run 'include "numbers/primes"; is_prime 0'
  [ "${status}" -ne 0 ]
}

@test "is_prime: negative number is not prime" {
  run shellac_run 'include "numbers/primes"; is_prime -7'
  [ "${status}" -ne 0 ]
}

@test "is_prime: 4 is not prime" {
  run shellac_run 'include "numbers/primes"; is_prime 4'
  [ "${status}" -ne 0 ]
}

@test "is_prime: 25 is not prime (composite passing 6k±1 filter)" {
  run shellac_run 'include "numbers/primes"; is_prime 25'
  [ "${status}" -ne 0 ]
}

@test "is_prime: 49 is not prime" {
  run shellac_run 'include "numbers/primes"; is_prime 49'
  [ "${status}" -ne 0 ]
}

@test "is_prime: --verbose prints verdict for prime" {
  run shellac_run 'include "numbers/primes"; is_prime --verbose 7'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"is a prime"* ]]
}

@test "is_prime: --verbose prints verdict for non-prime" {
  run shellac_run 'include "numbers/primes"; is_prime --verbose 4'
  [ "${status}" -ne 0 ]
  [[ "${output}" = *"is not a prime"* ]]
}

@test "is_prime: -v flag works same as --verbose" {
  run shellac_run 'include "numbers/primes"; is_prime -v 11'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"is a prime"* ]]
}

@test "is_prime: non-numeric input fails" {
  run shellac_run 'include "numbers/primes"; is_prime foo'
  [ "${status}" -ne 0 ]
}
