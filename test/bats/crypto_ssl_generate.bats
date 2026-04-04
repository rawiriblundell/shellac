#!/usr/bin/env bats
# Tests for crypto/ssl_generate in lib/sh/crypto/ssl_generate.sh

load 'helpers/setup'
bats_require_minimum_version 1.5.0

setup() {
  if ! command -v openssl >/dev/null 2>&1; then
    skip "openssl not available"
  fi
  TEST_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "${TEST_DIR}"
}

# ---------------------------------------------------------------------------
# ssl_genkey_rsa
# ---------------------------------------------------------------------------

@test "ssl_genkey_rsa: generates an RSA key file" {
  run shellac_run "include \"crypto/ssl_generate\"; ssl_genkey_rsa \"${TEST_DIR}/out.key\" 2048"
  [ "${status}" -eq 0 ]
  [ -f "${TEST_DIR}/out.key" ]
  [ -s "${TEST_DIR}/out.key" ]
}

@test "ssl_genkey_rsa: generated key is valid (openssl rsa check)" {
  run shellac_run "
    include \"crypto/ssl_generate\"
    ssl_genkey_rsa \"${TEST_DIR}/out.key\" 2048
    openssl rsa -check -noout -in \"${TEST_DIR}/out.key\"
  "
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# ssl_genkey_ec
# ---------------------------------------------------------------------------

@test "ssl_genkey_ec: generates an EC key with prime256v1" {
  run shellac_run "include \"crypto/ssl_generate\"; ssl_genkey_ec prime256v1 \"${TEST_DIR}/ec.key\""
  [ "${status}" -eq 0 ]
  [ -f "${TEST_DIR}/ec.key" ]
  [ -s "${TEST_DIR}/ec.key" ]
}

@test "ssl_genkey_ec: generated EC key is valid" {
  run shellac_run "
    include \"crypto/ssl_generate\"
    ssl_genkey_ec prime256v1 \"${TEST_DIR}/ec.key\"
    openssl ec -check -noout -in \"${TEST_DIR}/ec.key\"
  "
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# ssl_gencsr
# ---------------------------------------------------------------------------

@test "ssl_gencsr: generates a CSR from an existing key" {
  openssl genrsa -out "${TEST_DIR}/test.key" 2048 2>/dev/null
  run shellac_run "include \"crypto/ssl_generate\"; ssl_gencsr \"${TEST_DIR}/test.key\" \"${TEST_DIR}/test.csr\" \"/CN=test\""
  [ "${status}" -eq 0 ]
  [ -f "${TEST_DIR}/test.csr" ]
  [ -s "${TEST_DIR}/test.csr" ]
}

@test "ssl_gencsr: generated CSR is valid" {
  openssl genrsa -out "${TEST_DIR}/test.key" 2048 2>/dev/null
  run shellac_run "
    include \"crypto/ssl_generate\"
    ssl_gencsr \"${TEST_DIR}/test.key\" \"${TEST_DIR}/test.csr\" \"/CN=test\"
    openssl req -noout -verify -in \"${TEST_DIR}/test.csr\"
  "
  [ "${status}" -eq 0 ]
}

@test "ssl_gencsr: exits non-zero with no key argument" {
  run -127 shellac_run 'include "crypto/ssl_generate"; ssl_gencsr'
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# ssl_selfsigned
# ---------------------------------------------------------------------------

@test "ssl_selfsigned: generates a self-signed cert and key" {
  run shellac_run "include \"crypto/ssl_generate\"; ssl_selfsigned \"${TEST_DIR}/cert.pem\" \"${TEST_DIR}/key.pem\" 1 \"/CN=test\""
  [ "${status}" -eq 0 ]
  [ -f "${TEST_DIR}/cert.pem" ]
  [ -f "${TEST_DIR}/key.pem" ]
}

@test "ssl_selfsigned: generated cert is valid" {
  run shellac_run "
    include \"crypto/ssl_generate\"
    ssl_selfsigned \"${TEST_DIR}/cert.pem\" \"${TEST_DIR}/key.pem\" 1 \"/CN=test\"
    openssl x509 -noout -in \"${TEST_DIR}/cert.pem\"
  "
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# ssl_ec_curves
# ---------------------------------------------------------------------------

@test "ssl_ec_curves: exits 0 and lists curves" {
  run shellac_run 'include "crypto/ssl_generate"; ssl_ec_curves'
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]
}
