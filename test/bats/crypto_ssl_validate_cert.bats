#!/usr/bin/env bats
# Tests for crypto/ssl_validate_cert in lib/sh/crypto/ssl_validate_cert.sh

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
# ssl_validate_cert
# ---------------------------------------------------------------------------

@test "ssl_validate_cert: exits 0 when cert, key, and csr all match" {
  run shellac_run "include \"crypto/ssl_validate_cert\"; ssl_validate_cert \"${TEST_DIR}/test.pem\" \"${TEST_DIR}/test.key\" \"${TEST_DIR}/test.csr\""
  [ "${status}" -eq 0 ]
}

@test "ssl_validate_cert: exits 1 with no arguments" {
  run shellac_run 'include "crypto/ssl_validate_cert"; ssl_validate_cert'
  [ "${status}" -eq 1 ]
}

@test "ssl_validate_cert: exits 1 when key file does not exist" {
  run shellac_run "include \"crypto/ssl_validate_cert\"; ssl_validate_cert \"${TEST_DIR}/test.pem\" /no/such/key.key \"${TEST_DIR}/test.csr\""
  [ "${status}" -eq 1 ]
}

@test "ssl_validate_cert: exits 1 when csr file does not exist" {
  run shellac_run "include \"crypto/ssl_validate_cert\"; ssl_validate_cert \"${TEST_DIR}/test.pem\" \"${TEST_DIR}/test.key\" /no/such/file.csr"
  [ "${status}" -eq 1 ]
}

@test "ssl_validate_cert: exits 1 when cert and key do not match" {
  openssl req -x509 -newkey rsa:2048 -keyout "${TEST_DIR}/other.key" \
    -out "${TEST_DIR}/other.pem" -days 1 -nodes -subj "/CN=other" 2>/dev/null
  openssl req -new -key "${TEST_DIR}/other.key" \
    -out "${TEST_DIR}/other.csr" -subj "/CN=other" 2>/dev/null
  run shellac_run "include \"crypto/ssl_validate_cert\"; ssl_validate_cert \"${TEST_DIR}/test.pem\" \"${TEST_DIR}/other.key\" \"${TEST_DIR}/other.csr\""
  [ "${status}" -eq 1 ]
}
