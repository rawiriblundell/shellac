#!/usr/bin/env bats
# Tests for ssl_view_cert in lib/sh/crypto/ssl_view_cert.sh

load 'helpers/setup'

setup() {
  if ! command -v openssl >/dev/null 2>&1; then
    skip "openssl not available"
  fi
  TEST_DIR="$(mktemp -d)"
  # Self-signed cert valid for 365 days, CN=testcert
  openssl req -x509 -newkey rsa:2048 \
    -keyout "${TEST_DIR}/test.key" \
    -out "${TEST_DIR}/test.pem" \
    -days 365 -nodes -subj "/CN=testcert/O=TestOrg/OU=TestUnit" 2>/dev/null
  # Short-lived cert for expiry tests (1 day)
  openssl req -x509 -newkey rsa:2048 \
    -keyout "${TEST_DIR}/short.key" \
    -out "${TEST_DIR}/short.pem" \
    -days 1 -nodes -subj "/CN=shortcert" 2>/dev/null
}

teardown() {
  rm -rf "${TEST_DIR}"
}

# ---------------------------------------------------------------------------
# argument validation
# ---------------------------------------------------------------------------

@test "ssl_view_cert: missing cert file exits 1" {
  run shellac_run 'include "crypto/ssl_view_cert"; ssl_view_cert CN'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# CN
# ---------------------------------------------------------------------------

@test "ssl_view_cert CN: returns common name" {
  run shellac_run "include \"crypto/ssl_view_cert\"; ssl_view_cert CN \"${TEST_DIR}/test.pem\""
  [ "${status}" -eq 0 ]
  [ "${output}" = "testcert" ]
}

# ---------------------------------------------------------------------------
# algorithm
# ---------------------------------------------------------------------------

@test "ssl_view_cert algorithm: returns signature algorithm" {
  run shellac_run "include \"crypto/ssl_view_cert\"; ssl_view_cert algorithm \"${TEST_DIR}/test.pem\""
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"rsa"* || "${output}" = *"RSA"* || "${output}" = *"sha"* ]]
}

# ---------------------------------------------------------------------------
# issuer
# ---------------------------------------------------------------------------

@test "ssl_view_cert issuer: returns issuer string" {
  run shellac_run "include \"crypto/ssl_view_cert\"; ssl_view_cert issuer \"${TEST_DIR}/test.pem\""
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"testcert"* ]]
}

# ---------------------------------------------------------------------------
# serial
# ---------------------------------------------------------------------------

@test "ssl_view_cert serial: returns a hex serial number" {
  run shellac_run "include \"crypto/ssl_view_cert\"; ssl_view_cert serial \"${TEST_DIR}/test.pem\""
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9A-Fa-f]+$ ]]
}

# ---------------------------------------------------------------------------
# start / expiry
# ---------------------------------------------------------------------------

@test "ssl_view_cert start: returns a date string" {
  run shellac_run "include \"crypto/ssl_view_cert\"; ssl_view_cert start \"${TEST_DIR}/test.pem\""
  [ "${status}" -eq 0 ]
  [[ -n "${output}" ]]
}

@test "ssl_view_cert expiry: returns a date string" {
  run shellac_run "include \"crypto/ssl_view_cert\"; ssl_view_cert expiry \"${TEST_DIR}/test.pem\""
  [ "${status}" -eq 0 ]
  [[ -n "${output}" ]]
}

# ---------------------------------------------------------------------------
# state
# ---------------------------------------------------------------------------

@test "ssl_view_cert state: returns OK for valid cert" {
  run shellac_run "include \"crypto/ssl_view_cert\"; ssl_view_cert state \"${TEST_DIR}/test.pem\""
  [ "${status}" -eq 0 ]
  [ "${output}" = "OK" ]
}

# ---------------------------------------------------------------------------
# days — non-interactive output is a plain integer
# ---------------------------------------------------------------------------

@test "ssl_view_cert days: returns a positive integer for a future cert" {
  run shellac_run "include \"crypto/ssl_view_cert\"; ssl_view_cert days \"${TEST_DIR}/test.pem\""
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9]+$ ]]
  (( output > 0 ))
}

@test "ssl_view_cert days: 365-day cert reports roughly 365 days" {
  run shellac_run "include \"crypto/ssl_view_cert\"; ssl_view_cert days \"${TEST_DIR}/test.pem\""
  [ "${status}" -eq 0 ]
  (( output >= 363 && output <= 366 ))
}

@test "ssl_view_cert days: non-interactive output has no 'days' suffix" {
  run shellac_run "include \"crypto/ssl_view_cert\"; ssl_view_cert days \"${TEST_DIR}/test.pem\""
  [ "${status}" -eq 0 ]
  [[ "${output}" != *" days"* ]]
}

@test "ssl_view_cert days: 1-day cert reports 0 or 1 days" {
  run shellac_run "include \"crypto/ssl_view_cert\"; ssl_view_cert days \"${TEST_DIR}/short.pem\""
  [ "${status}" -eq 0 ]
  (( output >= 0 && output <= 1 ))
}

# ---------------------------------------------------------------------------
# OU / OrgName
# ---------------------------------------------------------------------------

@test "ssl_view_cert OU: returns organisational unit" {
  run shellac_run "include \"crypto/ssl_view_cert\"; ssl_view_cert OU \"${TEST_DIR}/test.pem\""
  [ "${status}" -eq 0 ]
  [ "${output}" = "TestUnit" ]
}

# ---------------------------------------------------------------------------
# full text fallback
# ---------------------------------------------------------------------------

@test "ssl_view_cert (default): returns full certificate text" {
  run shellac_run "include \"crypto/ssl_view_cert\"; ssl_view_cert full \"${TEST_DIR}/test.pem\""
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"Certificate:"* ]]
}
