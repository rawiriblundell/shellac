#!/usr/bin/env bats
# Tests for crypto/ssl_inspect in lib/sh/crypto/ssl_inspect.sh

load 'helpers/setup'
bats_require_minimum_version 1.5.0

setup() {
  if ! command -v openssl >/dev/null 2>&1; then
    skip "openssl not available"
  fi
  TEST_DIR="$(mktemp -d)"
  openssl req -x509 -newkey rsa:2048 -keyout "${TEST_DIR}/test.key" \
    -out "${TEST_DIR}/test.pem" -days 1 -nodes -subj "/CN=test" 2>/dev/null
  # Generate a CSR
  openssl req -new -key "${TEST_DIR}/test.key" \
    -out "${TEST_DIR}/test.csr" -subj "/CN=test" 2>/dev/null
}

teardown() {
  rm -rf "${TEST_DIR}"
}

# ---------------------------------------------------------------------------
# ssl_cert_dates
# ---------------------------------------------------------------------------

@test "ssl_cert_dates: exits 0 for valid cert" {
  run shellac_run "include \"crypto/ssl_inspect\"; ssl_cert_dates \"${TEST_DIR}/test.pem\""
  [ "${status}" -eq 0 ]
}

@test "ssl_cert_dates: output contains notBefore and notAfter" {
  run shellac_run "include \"crypto/ssl_inspect\"; ssl_cert_dates \"${TEST_DIR}/test.pem\""
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"notBefore"* ]]
  [[ "${output}" == *"notAfter"* ]]
}

@test "ssl_cert_dates: fails with no argument" {
  run -127 shellac_run 'include "crypto/ssl_inspect"; ssl_cert_dates'
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# ssl_cert_subject
# ---------------------------------------------------------------------------

@test "ssl_cert_subject: exits 0 for valid cert" {
  run shellac_run "include \"crypto/ssl_inspect\"; ssl_cert_subject \"${TEST_DIR}/test.pem\""
  [ "${status}" -eq 0 ]
}

@test "ssl_cert_subject: output contains the CN" {
  run shellac_run "include \"crypto/ssl_inspect\"; ssl_cert_subject \"${TEST_DIR}/test.pem\""
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"test"* ]]
}

@test "ssl_cert_subject: fails with no argument" {
  run -127 shellac_run 'include "crypto/ssl_inspect"; ssl_cert_subject'
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# ssl_cert_fingerprint
# ---------------------------------------------------------------------------

@test "ssl_cert_fingerprint: exits 0 for valid cert" {
  run shellac_run "include \"crypto/ssl_inspect\"; ssl_cert_fingerprint \"${TEST_DIR}/test.pem\""
  [ "${status}" -eq 0 ]
}

@test "ssl_cert_fingerprint: output contains Fingerprint" {
  run shellac_run "include \"crypto/ssl_inspect\"; ssl_cert_fingerprint \"${TEST_DIR}/test.pem\""
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"Fingerprint"* ]]
}

@test "ssl_cert_fingerprint: sha1 algorithm works" {
  run shellac_run "include \"crypto/ssl_inspect\"; ssl_cert_fingerprint \"${TEST_DIR}/test.pem\" sha1"
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]
}

@test "ssl_cert_fingerprint: fails with no argument" {
  run -127 shellac_run 'include "crypto/ssl_inspect"; ssl_cert_fingerprint'
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# ssl_modulus_match
# ---------------------------------------------------------------------------

@test "ssl_modulus_match: cert and key with matching modulus exits 0" {
  run shellac_run "include \"crypto/ssl_inspect\"; ssl_modulus_match \"${TEST_DIR}/test.pem\" \"${TEST_DIR}/test.key\""
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"OK"* ]]
}

@test "ssl_modulus_match: cert, key, and csr with matching modulus exits 0" {
  run shellac_run "include \"crypto/ssl_inspect\"; ssl_modulus_match \"${TEST_DIR}/test.pem\" \"${TEST_DIR}/test.key\" \"${TEST_DIR}/test.csr\""
  [ "${status}" -eq 0 ]
}

@test "ssl_modulus_match: mismatched key exits 1" {
  # Generate a second key that won't match the cert
  openssl req -x509 -newkey rsa:2048 -keyout "${TEST_DIR}/other.key" \
    -out "${TEST_DIR}/other.pem" -days 1 -nodes -subj "/CN=other" 2>/dev/null
  run shellac_run "include \"crypto/ssl_inspect\"; ssl_modulus_match \"${TEST_DIR}/test.pem\" \"${TEST_DIR}/other.key\""
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# ssl_verify_csr
# ---------------------------------------------------------------------------

@test "ssl_verify_csr: exits 0 for valid CSR" {
  run shellac_run "include \"crypto/ssl_inspect\"; ssl_verify_csr \"${TEST_DIR}/test.csr\""
  [ "${status}" -eq 0 ]
}

@test "ssl_verify_csr: fails with no argument" {
  run -127 shellac_run 'include "crypto/ssl_inspect"; ssl_verify_csr'
  [ "${status}" -ne 0 ]
}
