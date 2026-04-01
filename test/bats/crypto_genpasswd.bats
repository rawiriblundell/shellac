#!/usr/bin/env bats
# Tests for crypto/genpasswd in lib/sh/crypto/genpasswd.sh

load 'helpers/setup'

setup() {
  :
}

teardown() {
  :
}

# ---------------------------------------------------------------------------
# secrets_genpasswd / genpasswd
# ---------------------------------------------------------------------------

@test "secrets_genpasswd: produces one password by default" {
  run shellac_run 'include "crypto/genpasswd"; secrets_genpasswd'
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]
  count=$(printf '%s\n' "${output}" | wc -l | tr -d ' ')
  [ "${count}" -eq 1 ]
}

@test "secrets_genpasswd: default password is 10 chars long" {
  run shellac_run 'include "crypto/genpasswd"; secrets_genpasswd'
  [ "${status}" -eq 0 ]
  [ "${#output}" -eq 10 ]
}

@test "secrets_genpasswd: -c 16 produces a 16-char password" {
  run shellac_run 'include "crypto/genpasswd"; secrets_genpasswd -c 16'
  [ "${status}" -eq 0 ]
  [ "${#output}" -eq 16 ]
}

@test "secrets_genpasswd: -n 3 produces three passwords" {
  run shellac_run 'include "crypto/genpasswd"; secrets_genpasswd -n 3'
  [ "${status}" -eq 0 ]
  count=$(printf '%s\n' "${output}" | wc -l | tr -d ' ')
  [ "${count}" -eq 3 ]
}

@test "secrets_genpasswd: rejects password length less than 4" {
  run shellac_run 'include "crypto/genpasswd"; secrets_genpasswd -c 3'
  [ "${status}" -eq 1 ]
}

@test "secrets_genpasswd: -h exits 0 and prints usage" {
  run shellac_run 'include "crypto/genpasswd"; secrets_genpasswd -h'
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"genpasswd"* ]]
}

@test "secrets_genpasswd: invalid option exits 1" {
  run shellac_run 'include "crypto/genpasswd"; secrets_genpasswd -Z'
  [ "${status}" -eq 1 ]
}

@test "genpasswd: alias works identically to secrets_genpasswd" {
  run shellac_run 'include "crypto/genpasswd"; genpasswd'
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]
}
