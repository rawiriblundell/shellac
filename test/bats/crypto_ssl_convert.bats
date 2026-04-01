#!/usr/bin/env bats
# Tests for crypto/ssl_convert in lib/sh/crypto/ssl_convert.sh

load 'helpers/setup'

setup() {
  if ! command -v openssl >/dev/null 2>&1; then
    skip "openssl not available"
  fi
  TEST_DIR="$(mktemp -d)"
  openssl req -x509 -newkey rsa:2048 -keyout "${TEST_DIR}/test.key" \
    -out "${TEST_DIR}/test.pem" -days 1 -nodes -subj "/CN=test" 2>/dev/null
  # Make a .crt copy (PEM format)
  cp "${TEST_DIR}/test.pem" "${TEST_DIR}/test.crt"
  # Create a DER format file
  openssl x509 -outform der -in "${TEST_DIR}/test.pem" -out "${TEST_DIR}/test.der" 2>/dev/null
}

teardown() {
  rm -rf "${TEST_DIR}"
}

# ---------------------------------------------------------------------------
# ssl_pem_to_der / ssl_der_to_pem
# ---------------------------------------------------------------------------

@test "ssl_pem_to_der: converts PEM to DER successfully" {
  run shellac_run "include \"crypto/ssl_convert\"; ssl_pem_to_der \"${TEST_DIR}/test.pem\" \"${TEST_DIR}/out.der\""
  [ "${status}" -eq 0 ]
  [ -f "${TEST_DIR}/out.der" ]
  [ -s "${TEST_DIR}/out.der" ]
}

@test "ssl_pem_to_der: exits non-zero with no argument" {
  run shellac_run 'include "crypto/ssl_convert"; ssl_pem_to_der'
  [ "${status}" -ne 0 ]
}

@test "ssl_der_to_pem: converts DER to PEM successfully" {
  run shellac_run "include \"crypto/ssl_convert\"; ssl_der_to_pem \"${TEST_DIR}/test.der\" \"${TEST_DIR}/out.pem\""
  [ "${status}" -eq 0 ]
  [ -f "${TEST_DIR}/out.pem" ]
  [ -s "${TEST_DIR}/out.pem" ]
}

@test "ssl_der_to_pem: output is a valid PEM certificate" {
  run shellac_run "
    include \"crypto/ssl_convert\"
    ssl_der_to_pem \"${TEST_DIR}/test.der\" \"${TEST_DIR}/out.pem\"
    openssl x509 -noout -in \"${TEST_DIR}/out.pem\"
  "
  [ "${status}" -eq 0 ]
}

@test "ssl_der_to_pem: exits non-zero with no argument" {
  run shellac_run 'include "crypto/ssl_convert"; ssl_der_to_pem'
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# ssl_crt_to_pem / ssl_pem_to_crt
# ---------------------------------------------------------------------------

@test "ssl_crt_to_pem: converts .crt to .pem successfully" {
  run shellac_run "include \"crypto/ssl_convert\"; ssl_crt_to_pem \"${TEST_DIR}/test.crt\" \"${TEST_DIR}/out.pem\""
  [ "${status}" -eq 0 ]
  [ -f "${TEST_DIR}/out.pem" ]
}

@test "ssl_crt_to_pem: exits 1 for an empty file" {
  run shellac_run "
    include \"crypto/ssl_convert\"
    touch \"${TEST_DIR}/empty.crt\"
    ssl_crt_to_pem \"${TEST_DIR}/empty.crt\"
  "
  [ "${status}" -eq 1 ]
}

@test "ssl_pem_to_crt: converts .pem to .crt successfully" {
  run shellac_run "include \"crypto/ssl_convert\"; ssl_pem_to_crt \"${TEST_DIR}/test.pem\" \"${TEST_DIR}/out.crt\""
  [ "${status}" -eq 0 ]
  [ -f "${TEST_DIR}/out.crt" ]
}

@test "ssl_pem_to_crt: exits 1 for an empty file" {
  run shellac_run "
    include \"crypto/ssl_convert\"
    touch \"${TEST_DIR}/empty.pem\"
    ssl_pem_to_crt \"${TEST_DIR}/empty.pem\"
  "
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# ssl_cer_to_crt
# ---------------------------------------------------------------------------

@test "ssl_cer_to_crt: converts a PEM .cer to .crt" {
  cp "${TEST_DIR}/test.pem" "${TEST_DIR}/test.cer"
  run shellac_run "include \"crypto/ssl_convert\"; ssl_cer_to_crt \"${TEST_DIR}/test.cer\" \"${TEST_DIR}/out.crt\""
  [ "${status}" -eq 0 ]
  [ -f "${TEST_DIR}/out.crt" ]
}

@test "ssl_cer_to_crt: exits 1 for an empty file" {
  run shellac_run "
    include \"crypto/ssl_convert\"
    touch \"${TEST_DIR}/empty.cer\"
    ssl_cer_to_crt \"${TEST_DIR}/empty.cer\"
  "
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# Roundtrip: PEM -> DER -> PEM
# ---------------------------------------------------------------------------

@test "roundtrip: PEM to DER to PEM produces a valid certificate" {
  run shellac_run "
    include \"crypto/ssl_convert\"
    ssl_pem_to_der \"${TEST_DIR}/test.pem\" \"${TEST_DIR}/rt.der\"
    ssl_der_to_pem \"${TEST_DIR}/rt.der\" \"${TEST_DIR}/rt.pem\"
    openssl x509 -noout -in \"${TEST_DIR}/rt.pem\"
  "
  [ "${status}" -eq 0 ]
}
