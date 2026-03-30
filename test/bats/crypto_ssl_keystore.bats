#!/usr/bin/env bats
# Tests for ssl_create_jks in lib/sh/crypto/ssl_keystore.sh

load 'helpers/setup'

setup() {
  if ! command -v openssl >/dev/null 2>&1; then
    skip "openssl not available"
  fi
  if ! command -v keytool >/dev/null 2>&1; then
    skip "keytool not available"
  fi
  TEST_DIR="$(mktemp -d)"
  # Two minimal self-signed certs + key
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
# argument validation
# ---------------------------------------------------------------------------

@test "ssl_create_jks: missing -k exits 1" {
  run shellac_run "include \"crypto/ssl_keystore\"
    ssl_create_jks -p changeit -o \"${TEST_DIR}/out.jks\" \"${TEST_DIR}/cert.pem\""
  [ "${status}" -eq 1 ]
}

@test "ssl_create_jks: missing -p exits 1" {
  run shellac_run "include \"crypto/ssl_keystore\"
    ssl_create_jks -k \"${TEST_DIR}/server.key\" -o \"${TEST_DIR}/out.jks\" \"${TEST_DIR}/cert.pem\""
  [ "${status}" -eq 1 ]
}

@test "ssl_create_jks: missing -o exits 1" {
  run shellac_run "include \"crypto/ssl_keystore\"
    ssl_create_jks -k \"${TEST_DIR}/server.key\" -p changeit \"${TEST_DIR}/cert.pem\""
  [ "${status}" -eq 1 ]
}

@test "ssl_create_jks: missing cert files exits 1" {
  run shellac_run "include \"crypto/ssl_keystore\"
    ssl_create_jks -k \"${TEST_DIR}/server.key\" -p changeit -o \"${TEST_DIR}/out.jks\""
  [ "${status}" -eq 1 ]
}

@test "ssl_create_jks: non-existent key file exits 1" {
  run shellac_run "include \"crypto/ssl_keystore\"
    ssl_create_jks -k /no/such/key.pem -p changeit -o \"${TEST_DIR}/out.jks\" \"${TEST_DIR}/cert.pem\""
  [ "${status}" -eq 1 ]
}

@test "ssl_create_jks: invalid cert file exits 1" {
  run shellac_run "include \"crypto/ssl_keystore\"
    printf '%s\n' 'not a cert' > \"${TEST_DIR}/bad.pem\"
    ssl_create_jks -k \"${TEST_DIR}/server.key\" -p changeit -o \"${TEST_DIR}/out.jks\" \"${TEST_DIR}/bad.pem\""
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# successful creation
# ---------------------------------------------------------------------------

@test "ssl_create_jks: creates a JKS file" {
  run shellac_run "include \"crypto/ssl_keystore\"
    ssl_create_jks \
      -k \"${TEST_DIR}/server.key\" \
      -p changeit \
      -o \"${TEST_DIR}/keystore.jks\" \
      \"${TEST_DIR}/cert.pem\""
  [ "${status}" -eq 0 ]
  [ -f "${TEST_DIR}/keystore.jks" ]
}

@test "ssl_create_jks: JKS is listable with keytool" {
  run shellac_run "include \"crypto/ssl_keystore\"
    ssl_create_jks \
      -k \"${TEST_DIR}/server.key\" \
      -p changeit \
      -o \"${TEST_DIR}/keystore.jks\" \
      \"${TEST_DIR}/cert.pem\"
    keytool -list -keystore \"${TEST_DIR}/keystore.jks\" -storepass changeit -noprompt 2>/dev/null"
  [ "${status}" -eq 0 ]
}

@test "ssl_create_jks: explicit -a alias is set in JKS" {
  run shellac_run "include \"crypto/ssl_keystore\"
    ssl_create_jks \
      -k \"${TEST_DIR}/server.key\" \
      -p changeit \
      -o \"${TEST_DIR}/keystore.jks\" \
      -a myalias \
      \"${TEST_DIR}/cert.pem\"
    keytool -list -keystore \"${TEST_DIR}/keystore.jks\" -storepass changeit -noprompt 2>/dev/null"
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"myalias"* ]]
}

@test "ssl_create_jks: default alias is CN of first cert" {
  run shellac_run "include \"crypto/ssl_keystore\"
    ssl_create_jks \
      -k \"${TEST_DIR}/server.key\" \
      -p changeit \
      -o \"${TEST_DIR}/keystore.jks\" \
      \"${TEST_DIR}/cert.pem\"
    keytool -list -keystore \"${TEST_DIR}/keystore.jks\" -storepass changeit -noprompt 2>/dev/null"
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"test"* ]]
}

@test "ssl_create_jks: multiple cert files joined into chain" {
  run shellac_run "include \"crypto/ssl_keystore\"
    ssl_create_jks \
      -k \"${TEST_DIR}/server.key\" \
      -p changeit \
      -o \"${TEST_DIR}/keystore.jks\" \
      \"${TEST_DIR}/cert.pem\" \
      \"${TEST_DIR}/ca.pem\""
  [ "${status}" -eq 0 ]
  [ -f "${TEST_DIR}/keystore.jks" ]
}

@test "ssl_create_jks: creates output parent directory if needed" {
  run shellac_run "include \"crypto/ssl_keystore\"
    ssl_create_jks \
      -k \"${TEST_DIR}/server.key\" \
      -p changeit \
      -o \"${TEST_DIR}/subdir/keystore.jks\" \
      \"${TEST_DIR}/cert.pem\""
  [ "${status}" -eq 0 ]
  [ -f "${TEST_DIR}/subdir/keystore.jks" ]
}

# ---------------------------------------------------------------------------
# ssl_create_truststore
# ---------------------------------------------------------------------------

@test "ssl_create_truststore: missing output arg exits 1" {
  run shellac_run 'include "crypto/ssl_keystore"; ssl_create_truststore'
  [ "${status}" -ne 0 ]
}

@test "ssl_create_truststore: missing password arg exits 1" {
  run shellac_run "include \"crypto/ssl_keystore\"; ssl_create_truststore \"${TEST_DIR}/ts.jks\""
  [ "${status}" -ne 0 ]
}

@test "ssl_create_truststore: missing cert files exits 1" {
  run shellac_run "include \"crypto/ssl_keystore\"
    ssl_create_truststore \"${TEST_DIR}/ts.jks\" changeit"
  [ "${status}" -eq 1 ]
}

@test "ssl_create_truststore: invalid cert file exits 1" {
  run shellac_run "include \"crypto/ssl_keystore\"
    printf '%s\n' 'not a cert' > \"${TEST_DIR}/bad.pem\"
    ssl_create_truststore \"${TEST_DIR}/ts.jks\" changeit \"${TEST_DIR}/bad.pem\""
  [ "${status}" -eq 1 ]
}

@test "ssl_create_truststore: creates a truststore from one cert" {
  run shellac_run "include \"crypto/ssl_keystore\"
    ssl_create_truststore \"${TEST_DIR}/ts.jks\" changeit \"${TEST_DIR}/cert.pem\""
  [ "${status}" -eq 0 ]
  [ "${output}" = "1 certificates imported" ]
  [ -f "${TEST_DIR}/ts.jks" ]
}

@test "ssl_create_truststore: truststore is listable with keytool" {
  run shellac_run "include \"crypto/ssl_keystore\"
    ssl_create_truststore \"${TEST_DIR}/ts.jks\" changeit \"${TEST_DIR}/cert.pem\"
    keytool -list -keystore \"${TEST_DIR}/ts.jks\" -storepass changeit -noprompt 2>/dev/null"
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"1 entry"* ]]
}

@test "ssl_create_truststore: imports multiple certs" {
  run shellac_run "include \"crypto/ssl_keystore\"
    ssl_create_truststore \"${TEST_DIR}/ts.jks\" changeit \
      \"${TEST_DIR}/cert.pem\" \"${TEST_DIR}/ca.pem\""
  [ "${status}" -eq 0 ]
  [ "${output}" = "2 certificates imported" ]
}

@test "ssl_create_truststore: creates output parent directory if needed" {
  run shellac_run "include \"crypto/ssl_keystore\"
    ssl_create_truststore \"${TEST_DIR}/sub/ts.jks\" changeit \"${TEST_DIR}/cert.pem\""
  [ "${status}" -eq 0 ]
  [ -f "${TEST_DIR}/sub/ts.jks" ]
}

@test "ssl_create_truststore: failed import leaves no partial output file" {
  run shellac_run "include \"crypto/ssl_keystore\"
    printf '%s\n' 'not a cert' > \"${TEST_DIR}/bad.pem\"
    ssl_create_truststore \"${TEST_DIR}/ts.jks\" changeit \
      \"${TEST_DIR}/cert.pem\" \"${TEST_DIR}/bad.pem\"
    [ ! -f \"${TEST_DIR}/ts.jks\" ]"
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# ssl_split_jks
# ---------------------------------------------------------------------------

@test "ssl_split_jks: exits 1 for non-existent file" {
  run shellac_run 'include "crypto/ssl_keystore"; ssl_split_jks /no/such/store.jks'
  [ "${status}" -eq 1 ]
}

@test "ssl_split_jks: splits a JKS into one PEM per alias" {
  run shellac_run "include \"crypto/ssl_keystore\"
    ssl_create_jks \
      -k \"${TEST_DIR}/server.key\" \
      -p changeit \
      -o \"${TEST_DIR}/keystore.jks\" \
      -a myalias \
      \"${TEST_DIR}/cert.pem\"
    ssl_split_jks \"${TEST_DIR}/keystore.jks\" changeit \"${TEST_DIR}/split\""
  [ "${status}" -eq 0 ]
  [ "${output}" = "1 certificates extracted" ]
  [ -f "${TEST_DIR}/split/myalias.pem" ]
}

@test "ssl_split_jks: exported PEM is a valid certificate" {
  run shellac_run "include \"crypto/ssl_keystore\"
    ssl_create_jks \
      -k \"${TEST_DIR}/server.key\" \
      -p changeit \
      -o \"${TEST_DIR}/keystore.jks\" \
      -a myalias \
      \"${TEST_DIR}/cert.pem\"
    ssl_split_jks \"${TEST_DIR}/keystore.jks\" changeit \"${TEST_DIR}/split\"
    openssl x509 -noout -in \"${TEST_DIR}/split/myalias.pem\""
  [ "${status}" -eq 0 ]
}

@test "ssl_split_jks: creates output directory if needed" {
  run shellac_run "include \"crypto/ssl_keystore\"
    ssl_create_jks \
      -k \"${TEST_DIR}/server.key\" \
      -p changeit \
      -o \"${TEST_DIR}/keystore.jks\" \
      -a myalias \
      \"${TEST_DIR}/cert.pem\"
    ssl_split_jks \"${TEST_DIR}/keystore.jks\" changeit \"${TEST_DIR}/newdir/certs\""
  [ "${status}" -eq 0 ]
  [ -d "${TEST_DIR}/newdir/certs" ]
}

# ---------------------------------------------------------------------------
# roundtrip: create_jks → split_jks
# ---------------------------------------------------------------------------

@test "roundtrip: create then split recovers a valid PEM" {
  run shellac_run "include \"crypto/ssl_keystore\"
    ssl_create_jks \
      -k \"${TEST_DIR}/server.key\" \
      -p changeit \
      -o \"${TEST_DIR}/keystore.jks\" \
      -a roundtrip \
      \"${TEST_DIR}/cert.pem\"
    ssl_split_jks \"${TEST_DIR}/keystore.jks\" changeit \"${TEST_DIR}/out\"
    openssl x509 -noout -subject -in \"${TEST_DIR}/out/roundtrip.pem\""
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"CN"* ]]
}
