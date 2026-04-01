#!/usr/bin/env bats
# Tests for crypto/ssl_view_csr in lib/sh/crypto/ssl_view_csr.sh

load 'helpers/setup'

setup() {
  if ! command -v openssl >/dev/null 2>&1; then
    skip "openssl not available"
  fi
  TEST_DIR="$(mktemp -d)"
  openssl req -x509 -newkey rsa:2048 -keyout "${TEST_DIR}/test.key" \
    -out "${TEST_DIR}/test.pem" -days 1 -nodes -subj "/CN=test" 2>/dev/null
  openssl req -new -key "${TEST_DIR}/test.key" \
    -out "${TEST_DIR}/test.csr" -subj "/CN=test" 2>/dev/null
}

teardown() {
  rm -rf "${TEST_DIR}"
}

# ---------------------------------------------------------------------------
# ssl_view_csr
# ---------------------------------------------------------------------------

@test "ssl_view_csr: exits 0 for a valid CSR" {
  run shellac_run "include \"crypto/ssl_view_csr\"; ssl_view_csr \"${TEST_DIR}/test.csr\""
  [ "${status}" -eq 0 ]
}

@test "ssl_view_csr: output contains subject CN" {
  run shellac_run "include \"crypto/ssl_view_csr\"; ssl_view_csr \"${TEST_DIR}/test.csr\""
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"test"* ]]
}

@test "ssl_view_csr: exits 1 with no argument" {
  run shellac_run 'include "crypto/ssl_view_csr"; ssl_view_csr'
  [ "${status}" -eq 1 ]
}

@test "ssl_view_csr: exits non-zero for invalid file" {
  run shellac_run "include \"crypto/ssl_view_csr\"; ssl_view_csr /no/such/file.csr"
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# ssl_view_csr_modulus
# ---------------------------------------------------------------------------

@test "ssl_view_csr_modulus: exits 1 with no argument" {
  run shellac_run 'include "crypto/ssl_view_csr"; ssl_view_csr_modulus'
  [ "${status}" -eq 1 ]
}
