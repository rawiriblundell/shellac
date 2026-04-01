#!/usr/bin/env bats
# Tests for crypto/genphrase in lib/sh/crypto/genphrase.sh
# Note: secrets_genphrase requires ~/.pwords.dict (or downloads it) and 'capitalise'.
# Most tests are skipped unless the prerequisites are met.

load 'helpers/setup'

setup() {
  # Check for capitalise function availability via shellac
  if ! shellac_run 'include "text/capitalise"; capitalise test' >/dev/null 2>&1; then
    skip "capitalise function not available"
  fi
  if [[ ! -f "${HOME}/.pwords.dict" ]]; then
    skip "~/.pwords.dict not available"
  fi
}

teardown() {
  :
}

# ---------------------------------------------------------------------------
# secrets_genphrase / genphrase
# ---------------------------------------------------------------------------

@test "secrets_genphrase: produces one passphrase by default" {
  run shellac_run 'include "crypto/genphrase"; secrets_genphrase'
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]
  count=$(printf '%s\n' "${output}" | wc -l | tr -d ' ')
  [ "${count}" -eq 1 ]
}

@test "secrets_genphrase: -n 2 produces two passphrases" {
  run shellac_run 'include "crypto/genphrase"; secrets_genphrase -n 2'
  [ "${status}" -eq 0 ]
  count=$(printf '%s\n' "${output}" | wc -l | tr -d ' ')
  [ "${count}" -eq 2 ]
}

@test "secrets_genphrase: -h exits 0" {
  run shellac_run 'include "crypto/genphrase"; secrets_genphrase -h'
  [ "${status}" -eq 0 ]
}

@test "secrets_genphrase: invalid option exits 1" {
  run shellac_run 'include "crypto/genphrase"; secrets_genphrase -Z'
  [ "${status}" -eq 1 ]
}

@test "genphrase: alias works identically to secrets_genphrase" {
  run shellac_run 'include "crypto/genphrase"; genphrase'
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]
}
