#!/usr/bin/env bats
# Tests for ssl_cert_split and ssl_cert_join in lib/sh/crypto/

load 'helpers/setup'

# Generate self-signed test certs on first use; skip if openssl unavailable.
setup() {
  if ! command -v openssl >/dev/null 2>&1; then
    skip "openssl not available"
  fi
  TEST_DIR="$(mktemp -d)"
  # Two minimal self-signed certs
  openssl req -x509 -newkey rsa:2048 -keyout "${TEST_DIR}/key1.pem" \
    -out "${TEST_DIR}/cert1.pem" -days 1 -nodes -subj "/CN=test1" 2>/dev/null
  openssl req -x509 -newkey rsa:2048 -keyout "${TEST_DIR}/key2.pem" \
    -out "${TEST_DIR}/cert2.pem" -days 1 -nodes -subj "/CN=test2" 2>/dev/null
  # A two-cert bundle
  cat "${TEST_DIR}/cert1.pem" "${TEST_DIR}/cert2.pem" > "${TEST_DIR}/bundle.pem"
}

teardown() {
  rm -rf "${TEST_DIR}"
}

# ---------------------------------------------------------------------------
# ssl_cert_split
# ---------------------------------------------------------------------------

@test "ssl_cert_split: splits a two-cert bundle into two files" {
  run shellac_run "include \"crypto/ssl_cert_split\"
    ssl_cert_split \"${TEST_DIR}/bundle.pem\" cert \"${TEST_DIR}/out\""
  [ "${status}" -eq 0 ]
  [ "${output}" = "2 certificates extracted" ]
  [ -f "${TEST_DIR}/out/cert01.pem" ]
  [ -f "${TEST_DIR}/out/cert02.pem" ]
}

@test "ssl_cert_split: each output file is a valid PEM certificate" {
  run shellac_run "include \"crypto/ssl_cert_split\"
    ssl_cert_split \"${TEST_DIR}/bundle.pem\" cert \"${TEST_DIR}/out\"
    openssl x509 -noout -in \"${TEST_DIR}/out/cert01.pem\" &&
    openssl x509 -noout -in \"${TEST_DIR}/out/cert02.pem\""
  [ "${status}" -eq 0 ]
}

@test "ssl_cert_split: default prefix is 'cert'" {
  run shellac_run "include \"crypto/ssl_cert_split\"
    cd \"${TEST_DIR}\" || exit 1
    ssl_cert_split bundle.pem"
  [ "${status}" -eq 0 ]
  [ -f "${TEST_DIR}/cert01.pem" ]
}

@test "ssl_cert_split: single-cert bundle extracts one file" {
  run shellac_run "include \"crypto/ssl_cert_split\"
    ssl_cert_split \"${TEST_DIR}/cert1.pem\" single \"${TEST_DIR}/out\""
  [ "${status}" -eq 0 ]
  [ "${output}" = "1 certificates extracted" ]
  [ -f "${TEST_DIR}/out/single01.pem" ]
}

@test "ssl_cert_split: exits 1 for non-existent file" {
  run shellac_run 'include "crypto/ssl_cert_split"; ssl_cert_split /no/such/file.pem'
  [ "${status}" -eq 1 ]
}

@test "ssl_cert_split: exits 1 for file with no certificates" {
  run shellac_run "include \"crypto/ssl_cert_split\"
    printf '%s\n' 'not a cert' > \"${TEST_DIR}/bad.txt\"
    ssl_cert_split \"${TEST_DIR}/bad.txt\""
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# ssl_cert_join
# ---------------------------------------------------------------------------

@test "ssl_cert_join: joins two certs to stdout" {
  run shellac_run "include \"crypto/ssl_cert_join\"
    ssl_cert_join \"${TEST_DIR}/cert1.pem\" \"${TEST_DIR}/cert2.pem\""
  [ "${status}" -eq 0 ]
  count=$(printf '%s\n' "${output}" | grep -c -- '-BEGIN CERTIFICATE-')
  [ "${count}" -eq 2 ]
}

@test "ssl_cert_join -o: writes bundle to output file" {
  run shellac_run "include \"crypto/ssl_cert_join\"
    ssl_cert_join -o \"${TEST_DIR}/joined.pem\" \
      \"${TEST_DIR}/cert1.pem\" \"${TEST_DIR}/cert2.pem\"
    grep -c -- '-BEGIN CERTIFICATE-' \"${TEST_DIR}/joined.pem\""
  [ "${status}" -eq 0 ]
  [ "${output}" = "2" ]
}

@test "ssl_cert_join: exits 1 for non-existent input file" {
  run shellac_run "include \"crypto/ssl_cert_join\"
    ssl_cert_join \"${TEST_DIR}/cert1.pem\" /no/such/cert.pem"
  [ "${status}" -eq 1 ]
}

@test "ssl_cert_join: exits 1 for invalid PEM input" {
  run shellac_run "include \"crypto/ssl_cert_join\"
    printf '%s\n' 'not a cert' > \"${TEST_DIR}/bad.txt\"
    ssl_cert_join \"${TEST_DIR}/cert1.pem\" \"${TEST_DIR}/bad.txt\""
  [ "${status}" -eq 1 ]
}

@test "ssl_cert_join: exits 1 with no arguments" {
  run shellac_run 'include "crypto/ssl_cert_join"; ssl_cert_join'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# roundtrip: join then split
# ---------------------------------------------------------------------------

@test "roundtrip: join two certs then split recovers two valid certs" {
  run shellac_run "include \"crypto/ssl_cert_join\"; include \"crypto/ssl_cert_split\"
    ssl_cert_join \"${TEST_DIR}/cert1.pem\" \"${TEST_DIR}/cert2.pem\" \
      > \"${TEST_DIR}/joined.pem\"
    ssl_cert_split \"${TEST_DIR}/joined.pem\" rt \"${TEST_DIR}/out\"
    openssl x509 -noout -in \"${TEST_DIR}/out/rt01.pem\" &&
    openssl x509 -noout -in \"${TEST_DIR}/out/rt02.pem\""
  [ "${status}" -eq 0 ]
}
