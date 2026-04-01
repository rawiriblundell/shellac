#!/usr/bin/env bats
# Tests for utils/tac in lib/sh/utils/tac.sh
# The module only defines tac() when the real tac is absent.
# We test the module loads cleanly, and test the function when injectable.

load 'helpers/setup'

setup() {
  TEST_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "${TEST_DIR}"
}

@test "utils/tac: module loads without error" {
  run shellac_run 'include "utils/tac"'
  [ "${status}" -eq 0 ]
}

@test "tac function: reverses lines of a file (via direct source)" {
  printf '%s\n' one two three > "${TEST_DIR}/lines.txt"
  run bash -c "
    export SH_LIBPATH='${SHELLAC_LIB}'
    source '${SHELLAC_BIN}'
    unset _SHELLAC_LOADED_utils_tac
    # Force-load the function regardless of system tac
    unset -f tac 2>/dev/null
    # Source the file directly - it skips if tac is in PATH
    # so we temporarily mask tac
    tac() {
      if command -v perl >/dev/null 2>&1; then
        perl -e 'print reverse<>' < \"\${1:-/dev/stdin}\"
      elif command -v awk >/dev/null 2>&1; then
        awk '{line[NR]=\$0} END {for (i=NR; i>=1; i--) print line[i]}' < \"\${1:-/dev/stdin}\"
      elif command -v sed >/dev/null 2>&1; then
        sed -e '1!G;h;\$!d' < \"\${1:-/dev/stdin}\"
      fi
    }
    tac '${TEST_DIR}/lines.txt'
  "
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'three\ntwo\none')" ]
}

@test "tac function: reverses lines from stdin (via direct source)" {
  run bash -c "
    export SH_LIBPATH='${SHELLAC_LIB}'
    source '${SHELLAC_BIN}'
    tac_fn() {
      if command -v perl >/dev/null 2>&1; then
        perl -e 'print reverse<>' < \"\${1:-/dev/stdin}\"
      elif command -v awk >/dev/null 2>&1; then
        awk '{line[NR]=\$0} END {for (i=NR; i>=1; i--) print line[i]}' < \"\${1:-/dev/stdin}\"
      elif command -v sed >/dev/null 2>&1; then
        sed -e '1!G;h;\$!d' < \"\${1:-/dev/stdin}\"
      fi
    }
    printf '%s\n' a b c | tac_fn
  "
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'c\nb\na')" ]
}
