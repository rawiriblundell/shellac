#!/usr/bin/env bats
# Tests for crypto/ssl_view_key in lib/sh/crypto/ssl_view_key.sh

load 'helpers/setup'

setup() {
  if ! command -v openssl >/dev/null 2>&1; then
    skip "openssl not available"
  fi
  TEST_DIR="$(mktemp -d)"
  openssl req -x509 -newkey rsa:2048 -keyout "${TEST_DIR}/test.key" \
    -out "${TEST_DIR}/test.pem" -days 1 -nodes -subj "/CN=test" 2>/dev/null
}

teardown() {
  rm -rf "${TEST_DIR}"
}

# ---------------------------------------------------------------------------
# ssl_view_key
# ---------------------------------------------------------------------------

@test "ssl_view_key: exits 0 for a valid private key" {
  run shellac_run "include \"crypto/ssl_view_key\"; ssl_view_key \"${TEST_DIR}/test.key\""
  [ "${status}" -eq 0 ]
}

@test "ssl_view_key: output contains RSA key info" {
  run shellac_run "include \"crypto/ssl_view_key\"; ssl_view_key \"${TEST_DIR}/test.key\""
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"RSA"* ]] || [[ "${output}" == *"modulus"* ]] || [[ "${output}" == *"OK"* ]]
}

@test "ssl_view_key: exits 1 with no argument" {
  run shellac_run 'include "crypto/ssl_view_key"; ssl_view_key'
  [ "${status}" -eq 1 ]
}

@test "ssl_view_key: exits non-zero for non-existent file" {
  run shellac_run 'include "crypto/ssl_view_key"; ssl_view_key /no/such/key.pem'
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# ssl_view_key_modulus
# ---------------------------------------------------------------------------

@test "ssl_view_key_modulus: exits 1 with no argument" {
  run shellac_run 'include "crypto/ssl_view_key"; ssl_view_key_modulus'
  [ "${status}" -eq 1 ]
}
