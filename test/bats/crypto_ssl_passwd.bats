#!/usr/bin/env bats
# Tests for crypto/ssl_passwd in lib/sh/crypto/ssl_passwd.sh

load 'helpers/setup'

setup() {
  if ! command -v openssl >/dev/null 2>&1; then
    skip "openssl not available"
  fi
}

teardown() {
  :
}

# ---------------------------------------------------------------------------
# ssl_passwd_hash
# ---------------------------------------------------------------------------

@test "ssl_passwd_hash: sha512 hash of a known password exits 0" {
  run shellac_run 'include "crypto/ssl_passwd"; ssl_passwd_hash -6 "testpassword"'
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]
}

@test "ssl_passwd_hash: sha512 output starts with dollar-6-dollar" {
  run shellac_run 'include "crypto/ssl_passwd"; ssl_passwd_hash -6 "testpassword"'
  [ "${status}" -eq 0 ]
  [[ "${output}" == '$6$'* ]]
}

@test "ssl_passwd_hash: md5 hash starts with dollar-1-dollar" {
  run shellac_run 'include "crypto/ssl_passwd"; ssl_passwd_hash -1 "testpassword"'
  [ "${status}" -eq 0 ]
  [[ "${output}" == '$1$'* ]]
}

@test "ssl_passwd_hash: apr1 hash starts with dollar-apr1-dollar" {
  run shellac_run 'include "crypto/ssl_passwd"; ssl_passwd_hash -apr1 "testpassword"'
  [ "${status}" -eq 0 ]
  [[ "${output}" == '$apr1$'* ]]
}

@test "ssl_passwd_hash: sha256 hash starts with dollar-5-dollar" {
  run shellac_run 'include "crypto/ssl_passwd"; ssl_passwd_hash -5 "testpassword"'
  [ "${status}" -eq 0 ]
  [[ "${output}" == '$5$'* ]]
}

@test "ssl_passwd_hash: same password and salt always produces the same hash" {
  run shellac_run '
    include "crypto/ssl_passwd"
    h1=$(ssl_passwd_hash -6 "testpass" "saltvalue")
    h2=$(ssl_passwd_hash -6 "testpass" "saltvalue")
    [ "${h1}" = "${h2}" ]
  '
  [ "${status}" -eq 0 ]
}

@test "ssl_passwd_hash: different passwords produce different hashes" {
  run shellac_run '
    include "crypto/ssl_passwd"
    h1=$(ssl_passwd_hash -6 "password1" "samesalt")
    h2=$(ssl_passwd_hash -6 "password2" "samesalt")
    [ "${h1}" != "${h2}" ]
  '
  [ "${status}" -eq 0 ]
}
