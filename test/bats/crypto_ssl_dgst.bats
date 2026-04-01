#!/usr/bin/env bats
# Tests for crypto/ssl_dgst in lib/sh/crypto/ssl_dgst.sh

load 'helpers/setup'

setup() {
  if ! command -v openssl >/dev/null 2>&1; then
    skip "openssl not available"
  fi
  TEST_DIR="$(mktemp -d)"
  printf '%s\n' "hello shellac" > "${TEST_DIR}/test.txt"
  openssl req -x509 -newkey rsa:2048 -keyout "${TEST_DIR}/test.key" \
    -out "${TEST_DIR}/test.pem" -days 1 -nodes -subj "/CN=test" 2>/dev/null
  openssl rsa -in "${TEST_DIR}/test.key" -pubout -out "${TEST_DIR}/test.pub" 2>/dev/null
}

teardown() {
  rm -rf "${TEST_DIR}"
}

# ---------------------------------------------------------------------------
# ssl_dgst
# ---------------------------------------------------------------------------

@test "ssl_dgst: exits 0 and produces output for a file" {
  run shellac_run "include \"crypto/ssl_dgst\"; ssl_dgst \"${TEST_DIR}/test.txt\""
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]
}

@test "ssl_dgst: output contains the filename" {
  run shellac_run "include \"crypto/ssl_dgst\"; ssl_dgst \"${TEST_DIR}/test.txt\""
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"test.txt"* ]]
}

@test "ssl_dgst: default algorithm is sha256" {
  run shellac_run "include \"crypto/ssl_dgst\"; ssl_dgst \"${TEST_DIR}/test.txt\""
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"SHA"* ]] || [[ "${output}" == *"sha"* ]]
}

@test "ssl_dgst: explicit sha512 algorithm works" {
  run shellac_run "include \"crypto/ssl_dgst\"; ssl_dgst \"${TEST_DIR}/test.txt\" sha512"
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]
}

@test "ssl_dgst: same file produces same digest on second call" {
  run shellac_run "
    include \"crypto/ssl_dgst\"
    d1=\$(ssl_dgst \"${TEST_DIR}/test.txt\")
    d2=\$(ssl_dgst \"${TEST_DIR}/test.txt\")
    [ \"\${d1}\" = \"\${d2}\" ]
  "
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# ssl_dgst_sign / ssl_dgst_verify
# ---------------------------------------------------------------------------

@test "ssl_dgst_sign: signs a file and creates a .sig file" {
  run shellac_run "
    include \"crypto/ssl_dgst\"
    ssl_dgst_sign \"${TEST_DIR}/test.key\" \"${TEST_DIR}/test.txt\" \"${TEST_DIR}/test.sig\"
  "
  [ "${status}" -eq 0 ]
  [ -f "${TEST_DIR}/test.sig" ]
}

@test "ssl_dgst_verify: verifies a valid signature" {
  run shellac_run "
    include \"crypto/ssl_dgst\"
    ssl_dgst_sign \"${TEST_DIR}/test.key\" \"${TEST_DIR}/test.txt\" \"${TEST_DIR}/test.sig\"
    ssl_dgst_verify \"${TEST_DIR}/test.pub\" \"${TEST_DIR}/test.sig\" \"${TEST_DIR}/test.txt\"
  "
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"OK"* ]] || [[ "${output}" == *"Verified"* ]]
}

@test "ssl_dgst_verify: fails for tampered file" {
  run shellac_run "
    include \"crypto/ssl_dgst\"
    ssl_dgst_sign \"${TEST_DIR}/test.key\" \"${TEST_DIR}/test.txt\" \"${TEST_DIR}/test.sig\"
    printf '%s\n' 'tampered' >> \"${TEST_DIR}/test.txt\"
    ssl_dgst_verify \"${TEST_DIR}/test.pub\" \"${TEST_DIR}/test.sig\" \"${TEST_DIR}/test.txt\"
  "
  [ "${status}" -ne 0 ]
}
