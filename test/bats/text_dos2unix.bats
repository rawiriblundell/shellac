#!/usr/bin/env bats
# Tests for dos2unix (stub) in lib/sh/text/dos2unix.sh

load 'helpers/setup'

setup() {
  _test_tmpdir="$(mktemp -d)"
}

teardown() {
  rm -rf "${_test_tmpdir}"
}

@test "dos2unix: strips carriage returns from stdin" {
  run shellac_run 'include "text/dos2unix"; printf "line1\r\nline2\r\n" | dos2unix'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'line1\nline2\n')" ]
}

@test "dos2unix: input with no CR passes through unchanged via stdin" {
  run shellac_run 'include "text/dos2unix"; printf "line1\nline2\n" | dos2unix'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'line1\nline2\n')" ]
}

@test "dos2unix: rejects option flags with exit 1" {
  run shellac_run 'include "text/dos2unix"; printf "x\r\n" | dos2unix -u'
  [ "${status}" -eq 1 ]
}

@test "dos2unix: converts file in place" {
  local tmpfile
  tmpfile="${_test_tmpdir}/test.txt"
  printf 'hello\r\nworld\r\n' > "${tmpfile}"
  run shellac_run "include \"text/dos2unix\"; dos2unix \"${tmpfile}\""
  [ "${status}" -eq 0 ]
  # Verify the file no longer contains CR
  run bash -c "grep -cP '\r' '${tmpfile}'"
  [ "${output}" = "0" ]
}
