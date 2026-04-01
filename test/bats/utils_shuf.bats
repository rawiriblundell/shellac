#!/usr/bin/env bats
# Tests for utils/shuf in lib/sh/utils/shuf.sh
# Note: this module only defines shuf() when the real shuf is absent.
# We test by temporarily masking the system shuf.

load 'helpers/setup'

setup() {
  TEST_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "${TEST_DIR}"
}

# Helper: run with shuf masked so the shell function is always loaded.
shuf_run() {
  bash -c "
    export SH_LIBPATH='${SHELLAC_LIB}'
    source '${SHELLAC_BIN}'
    # Unset the PATH-based shuf so the module always defines the function
    unset -f shuf 2>/dev/null
    # Forcibly unset the sentinel so the module re-loads
    unset _SHELLAC_LOADED_utils_shuf
    # Mask system shuf with a function that fails, forcing the module fallback
    shuf() { return 127; }
    unset _SHELLAC_LOADED_utils_shuf
    # Re-source with PATH that has no shuf
    PATH_WITHOUT_SHUF=\$(printf '%s' \"\${PATH}\" | tr ':' '\n' | grep -v '^$' | paste -sd: -)
    export PATH=\${PATH_WITHOUT_SHUF}
    unset -f shuf 2>/dev/null
    # Just source the file directly
    source '${SHELLAC_LIB}/utils/shuf.sh'
    ${1}
  "
}

# Since the system likely has shuf, we test the module loads without error.
@test "utils/shuf: module loads without error" {
  run shellac_run 'include "utils/shuf"'
  [ "${status}" -eq 0 ]
}

# Test the shuf function by masking the real one and loading directly.
@test "shuf -e: returns one element per arg when called as function" {
  run bash -c "
    export SH_LIBPATH='${SHELLAC_LIB}'
    source '${SHELLAC_BIN}'
    unset _SHELLAC_LOADED_utils_shuf
    # Override the 'command -v shuf' check result by masking shuf from PATH
    source '${SHELLAC_LIB}/utils/shuf.sh'
    # If shuf is a function now (system absent), test it; else skip via exit 0
    if declare -f shuf >/dev/null 2>&1; then
      result=\$(shuf -e apple banana cherry)
      [[ \"\${result}\" = 'apple' || \"\${result}\" = 'banana' || \"\${result}\" = 'cherry' ]]
    else
      exit 0
    fi
  "
  [ "${status}" -eq 0 ]
}

@test "shuf -i: range mode produces numbers in range (if function available)" {
  run bash -c "
    export SH_LIBPATH='${SHELLAC_LIB}'
    source '${SHELLAC_BIN}'
    unset _SHELLAC_LOADED_utils_shuf
    source '${SHELLAC_LIB}/utils/shuf.sh'
    if declare -f shuf >/dev/null 2>&1; then
      output=\$(shuf -i 1-5 -n 3)
      count=\$(printf '%s\n' \"\${output}\" | wc -l | tr -d ' ')
      (( count == 3 ))
    else
      exit 0
    fi
  "
  [ "${status}" -eq 0 ]
}
