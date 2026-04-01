#!/usr/bin/env bats
# Tests for crypto/ssl_view_pkcs12 in lib/sh/crypto/ssl_view_pkcs12.sh
# ssl_view_pkcs12 prompts interactively for the import password, so we only
# test the argument-validation path (no argument).

load 'helpers/setup'

setup() {
  if ! command -v openssl >/dev/null 2>&1; then
    skip "openssl not available"
  fi
}

teardown() {
  :
}

# ---------------------------------------------------------------------------
# ssl_view_pkcs12
# ---------------------------------------------------------------------------

@test "ssl_view_pkcs12: exits 1 with no argument" {
  run shellac_run 'include "crypto/ssl_view_pkcs12"; ssl_view_pkcs12'
  [ "${status}" -eq 1 ]
}

@test "ssl_view_pkcs12: error message mentions the function name" {
  run shellac_run 'include "crypto/ssl_view_pkcs12"; ssl_view_pkcs12'
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"ssl_view_pkcs12"* ]]
}
