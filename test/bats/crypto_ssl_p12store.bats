#!/usr/bin/env bats
# Tests for ssl_create_p12, ssl_create_p12_truststore, ssl_split_p12
# in lib/sh/crypto/ssl_p12store.sh

load 'helpers/setup'

setup() {
  if ! command -v openssl >/dev/null 2>&1; then
    skip "openssl not available"
  fi
  TEST_DIR="$(mktemp -d)"
  openssl req -x509 -newkey rsa:2048 \
    -keyout "${TEST_DIR}/server.key" \
    -out "${TEST_DIR}/cert.pem" \
    -days 1 -nodes -subj "/CN=test" 2>/dev/null
  openssl req -x509 -newkey rsa:2048 \
    -keyout "${TEST_DIR}/ca.key" \
    -out "${TEST_DIR}/ca.pem" \
    -days 1 -nodes -subj "/CN=ca" 2>/dev/null
}

teardown() {
  rm -rf "${TEST_DIR}"
}

# ---------------------------------------------------------------------------
# ssl_create_p12
# ---------------------------------------------------------------------------

@test "ssl_create_p12: missing -k exits 1" {
  run shellac_run "include \"crypto/ssl_p12store\"
    ssl_create_p12 -p changeit -o \"${TEST_DIR}/out.p12\" \"${TEST_DIR}/cert.pem\""
  [ "${status}" -eq 1 ]
}

@test "ssl_create_p12: missing -p exits 1" {
  run shellac_run "include \"crypto/ssl_p12store\"
    ssl_create_p12 -k \"${TEST_DIR}/server.key\" -o \"${TEST_DIR}/out.p12\" \"${TEST_DIR}/cert.pem\""
  [ "${status}" -eq 1 ]
}

@test "ssl_create_p12: missing -o exits 1" {
  run shellac_run "include \"crypto/ssl_p12store\"
    ssl_create_p12 -k \"${TEST_DIR}/server.key\" -p changeit \"${TEST_DIR}/cert.pem\""
  [ "${status}" -eq 1 ]
}

@test "ssl_create_p12: missing cert files exits 1" {
  run shellac_run "include \"crypto/ssl_p12store\"
    ssl_create_p12 -k \"${TEST_DIR}/server.key\" -p changeit -o \"${TEST_DIR}/out.p12\""
  [ "${status}" -eq 1 ]
}

@test "ssl_create_p12: creates a .p12 file" {
  run shellac_run "include \"crypto/ssl_p12store\"
    ssl_create_p12 \
      -k \"${TEST_DIR}/server.key\" \
      -p changeit \
      -o \"${TEST_DIR}/keystore.p12\" \
      \"${TEST_DIR}/cert.pem\""
  [ "${status}" -eq 0 ]
  [ -f "${TEST_DIR}/keystore.p12" ]
}

@test "ssl_create_p12: output is a readable PKCS12 file" {
  run shellac_run "include \"crypto/ssl_p12store\"
    ssl_create_p12 \
      -k \"${TEST_DIR}/server.key\" \
      -p changeit \
      -o \"${TEST_DIR}/keystore.p12\" \
      \"${TEST_DIR}/cert.pem\"
    openssl pkcs12 -in \"${TEST_DIR}/keystore.p12\" -passin pass:changeit -nokeys 2>/dev/null |
      grep -c -- '-BEGIN CERTIFICATE-'"
  [ "${status}" -eq 0 ]
  [ "${output}" -ge 1 ]
}

@test "ssl_create_p12: default alias is CN of first cert" {
  run shellac_run "include \"crypto/ssl_p12store\"
    ssl_create_p12 \
      -k \"${TEST_DIR}/server.key\" \
      -p changeit \
      -o \"${TEST_DIR}/keystore.p12\" \
      \"${TEST_DIR}/cert.pem\"
    openssl pkcs12 -in \"${TEST_DIR}/keystore.p12\" -passin pass:changeit -nokeys 2>/dev/null |
      grep 'friendlyName'"
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"test"* ]]
}

@test "ssl_create_p12: multiple cert files joined into chain" {
  run shellac_run "include \"crypto/ssl_p12store\"
    ssl_create_p12 \
      -k \"${TEST_DIR}/server.key\" \
      -p changeit \
      -o \"${TEST_DIR}/keystore.p12\" \
      \"${TEST_DIR}/cert.pem\" \
      \"${TEST_DIR}/ca.pem\""
  [ "${status}" -eq 0 ]
  [ -f "${TEST_DIR}/keystore.p12" ]
}

@test "ssl_create_p12: creates output parent directory if needed" {
  run shellac_run "include \"crypto/ssl_p12store\"
    ssl_create_p12 \
      -k \"${TEST_DIR}/server.key\" \
      -p changeit \
      -o \"${TEST_DIR}/sub/keystore.p12\" \
      \"${TEST_DIR}/cert.pem\""
  [ "${status}" -eq 0 ]
  [ -f "${TEST_DIR}/sub/keystore.p12" ]
}

# ---------------------------------------------------------------------------
# ssl_create_p12_truststore
# ---------------------------------------------------------------------------

@test "ssl_create_p12_truststore: missing output exits non-zero" {
  run shellac_run 'include "crypto/ssl_p12store"; ssl_create_p12_truststore'
  [ "${status}" -ne 0 ]
}

@test "ssl_create_p12_truststore: missing cert files exits 1" {
  run shellac_run "include \"crypto/ssl_p12store\"
    ssl_create_p12_truststore \"${TEST_DIR}/ts.p12\" changeit"
  [ "${status}" -eq 1 ]
}

@test "ssl_create_p12_truststore: invalid cert exits 1" {
  run shellac_run "include \"crypto/ssl_p12store\"
    printf '%s\n' 'not a cert' > \"${TEST_DIR}/bad.pem\"
    ssl_create_p12_truststore \"${TEST_DIR}/ts.p12\" changeit \"${TEST_DIR}/bad.pem\""
  [ "${status}" -eq 1 ]
}

@test "ssl_create_p12_truststore: creates a .p12 truststore" {
  run shellac_run "include \"crypto/ssl_p12store\"
    ssl_create_p12_truststore \"${TEST_DIR}/ts.p12\" changeit \
      \"${TEST_DIR}/cert.pem\" \"${TEST_DIR}/ca.pem\""
  [ "${status}" -eq 0 ]
  [ "${output}" = "2 certificates imported" ]
  [ -f "${TEST_DIR}/ts.p12" ]
}

@test "ssl_create_p12_truststore: output is a readable PKCS12 file" {
  run shellac_run "include \"crypto/ssl_p12store\"
    ssl_create_p12_truststore \"${TEST_DIR}/ts.p12\" changeit \"${TEST_DIR}/cert.pem\" >/dev/null
    openssl pkcs12 -in \"${TEST_DIR}/ts.p12\" -passin pass:changeit -nokeys 2>/dev/null |
      grep -c -- '-BEGIN CERTIFICATE-'"
  [ "${status}" -eq 0 ]
  [ "${output}" -ge 1 ]
}

@test "ssl_create_p12_truststore: creates output parent directory if needed" {
  run shellac_run "include \"crypto/ssl_p12store\"
    ssl_create_p12_truststore \"${TEST_DIR}/sub/ts.p12\" changeit \"${TEST_DIR}/cert.pem\""
  [ "${status}" -eq 0 ]
  [ -f "${TEST_DIR}/sub/ts.p12" ]
}

# ---------------------------------------------------------------------------
# ssl_split_p12
# ---------------------------------------------------------------------------

@test "ssl_split_p12: exits 1 for non-existent file" {
  run shellac_run 'include "crypto/ssl_p12store"; ssl_split_p12 /no/such/file.p12 ""'
  [ "${status}" -eq 1 ]
}

@test "ssl_split_p12: splits a .p12 into PEM files named by CN" {
  run shellac_run "include \"crypto/ssl_p12store\"
    ssl_create_p12 \
      -k \"${TEST_DIR}/server.key\" \
      -p changeit \
      -o \"${TEST_DIR}/keystore.p12\" \
      \"${TEST_DIR}/cert.pem\" \
      \"${TEST_DIR}/ca.pem\"
    ssl_split_p12 \"${TEST_DIR}/keystore.p12\" changeit \"${TEST_DIR}/split\""
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"certificates extracted"* ]]
  [ -d "${TEST_DIR}/split" ]
}

@test "ssl_split_p12: extracted files are valid PEM certificates" {
  run shellac_run "include \"crypto/ssl_p12store\"
    ssl_create_p12 \
      -k \"${TEST_DIR}/server.key\" \
      -p changeit \
      -o \"${TEST_DIR}/keystore.p12\" \
      \"${TEST_DIR}/cert.pem\"
    ssl_split_p12 \"${TEST_DIR}/keystore.p12\" changeit \"${TEST_DIR}/split\"
    for f in \"${TEST_DIR}/split\"/*.pem; do
      openssl x509 -noout -in \"\${f}\" || exit 1
    done"
  [ "${status}" -eq 0 ]
}

@test "ssl_split_p12: creates output directory if needed" {
  run shellac_run "include \"crypto/ssl_p12store\"
    ssl_create_p12 \
      -k \"${TEST_DIR}/server.key\" \
      -p changeit \
      -o \"${TEST_DIR}/keystore.p12\" \
      \"${TEST_DIR}/cert.pem\"
    ssl_split_p12 \"${TEST_DIR}/keystore.p12\" changeit \"${TEST_DIR}/newdir\""
  [ "${status}" -eq 0 ]
  [ -d "${TEST_DIR}/newdir" ]
}

# ---------------------------------------------------------------------------
# roundtrip: create_p12 → split_p12
# ---------------------------------------------------------------------------

@test "roundtrip: create_p12 then split_p12 recovers a valid cert named by CN" {
  run shellac_run "include \"crypto/ssl_p12store\"
    ssl_create_p12 \
      -k \"${TEST_DIR}/server.key\" \
      -p changeit \
      -o \"${TEST_DIR}/keystore.p12\" \
      \"${TEST_DIR}/cert.pem\"
    ssl_split_p12 \"${TEST_DIR}/keystore.p12\" changeit \"${TEST_DIR}/split\"
    openssl x509 -noout -subject -in \"${TEST_DIR}/split/test.pem\""
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"CN"*"test"* ]]
}
