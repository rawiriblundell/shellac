#!/usr/bin/env bats
# Tests for dir_compare in lib/sh/fs/dir.sh

load 'helpers/setup'
bats_require_minimum_version 1.5.0

setup() {
  TEST_TMPDIR="$(mktemp -d)"
  # Two identical shallow dirs
  mkdir -p "${TEST_TMPDIR}/a" "${TEST_TMPDIR}/b"
  printf -- '%s\n' "hello" > "${TEST_TMPDIR}/a/file1.txt"
  printf -- '%s\n' "world" > "${TEST_TMPDIR}/a/file2.txt"
  printf -- '%s\n' "hello" > "${TEST_TMPDIR}/b/file1.txt"
  printf -- '%s\n' "world" > "${TEST_TMPDIR}/b/file2.txt"
}

teardown() {
  rm -rf "${TEST_TMPDIR}"
}

# ---------------------------------------------------------------------------
# Argument validation
# ---------------------------------------------------------------------------

@test "dir_compare: no arguments exits 1" {
  run shellac_run 'include "fs/dir"; dir_compare'
  [ "${status}" -eq 1 ]
}

@test "dir_compare: one argument exits 1" {
  run shellac_run "include \"fs/dir\"; dir_compare \"${TEST_TMPDIR}/a\""
  [ "${status}" -eq 1 ]
}

@test "dir_compare: non-existent first dir exits 1" {
  run shellac_run "include \"fs/dir\"; dir_compare \"${TEST_TMPDIR}/no_such\" \"${TEST_TMPDIR}/b\""
  [ "${status}" -eq 1 ]
}

@test "dir_compare: non-existent second dir exits 1" {
  run shellac_run "include \"fs/dir\"; dir_compare \"${TEST_TMPDIR}/a\" \"${TEST_TMPDIR}/no_such\""
  [ "${status}" -eq 1 ]
}

@test "dir_compare: unknown option exits 1" {
  run shellac_run "include \"fs/dir\"; dir_compare --no-such-opt \"${TEST_TMPDIR}/a\" \"${TEST_TMPDIR}/b\""
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# Quiet shallow (default)
# ---------------------------------------------------------------------------

@test "dir_compare: identical dirs return 0" {
  run shellac_run "include \"fs/dir\"; dir_compare \"${TEST_TMPDIR}/a\" \"${TEST_TMPDIR}/b\""
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
}

@test "dir_compare: dirs with different file sets return 1" {
  printf -- '%s\n' "extra" > "${TEST_TMPDIR}/b/file3.txt"
  run shellac_run "include \"fs/dir\"; dir_compare \"${TEST_TMPDIR}/a\" \"${TEST_TMPDIR}/b\""
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
}

@test "dir_compare: different content same names returns 0 (shallow is name-only)" {
  printf -- '%s\n' "different content" > "${TEST_TMPDIR}/b/file1.txt"
  run shellac_run "include \"fs/dir\"; dir_compare \"${TEST_TMPDIR}/a\" \"${TEST_TMPDIR}/b\""
  [ "${status}" -eq 0 ]
}

@test "dir_compare: dotfiles are considered" {
  printf -- '%s\n' "hidden" > "${TEST_TMPDIR}/a/.hidden"
  run shellac_run "include \"fs/dir\"; dir_compare \"${TEST_TMPDIR}/a\" \"${TEST_TMPDIR}/b\""
  [ "${status}" -eq 1 ]
}

@test "dir_compare: dotfiles match on both sides return 0" {
  printf -- '%s\n' "hidden" > "${TEST_TMPDIR}/a/.hidden"
  printf -- '%s\n' "hidden" > "${TEST_TMPDIR}/b/.hidden"
  run shellac_run "include \"fs/dir\"; dir_compare \"${TEST_TMPDIR}/a\" \"${TEST_TMPDIR}/b\""
  [ "${status}" -eq 0 ]
}

@test "dir_compare: two empty dirs return 0" {
  mkdir -p "${TEST_TMPDIR}/empty1" "${TEST_TMPDIR}/empty2"
  run shellac_run "include \"fs/dir\"; dir_compare \"${TEST_TMPDIR}/empty1\" \"${TEST_TMPDIR}/empty2\""
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Verbose shallow (-v)
# ---------------------------------------------------------------------------

@test "dir_compare -v: identical dirs return 0 with no output" {
  run shellac_run "include \"fs/dir\"; dir_compare -v \"${TEST_TMPDIR}/a\" \"${TEST_TMPDIR}/b\""
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
}

@test "dir_compare -v: extra file in dir2 is reported" {
  printf -- '%s\n' "extra" > "${TEST_TMPDIR}/b/file3.txt"
  run shellac_run "include \"fs/dir\"; dir_compare -v \"${TEST_TMPDIR}/a\" \"${TEST_TMPDIR}/b\""
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"file3.txt"* ]]
  [[ "${output}" == *"${TEST_TMPDIR}/b"* ]]
}

@test "dir_compare -v: extra file in dir1 is reported" {
  printf -- '%s\n' "extra" > "${TEST_TMPDIR}/a/file3.txt"
  run shellac_run "include \"fs/dir\"; dir_compare -v \"${TEST_TMPDIR}/a\" \"${TEST_TMPDIR}/b\""
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"file3.txt"* ]]
  [[ "${output}" == *"${TEST_TMPDIR}/a"* ]]
}

@test "dir_compare --verbose: long form is accepted" {
  printf -- '%s\n' "extra" > "${TEST_TMPDIR}/b/only_b.txt"
  run shellac_run "include \"fs/dir\"; dir_compare --verbose \"${TEST_TMPDIR}/a\" \"${TEST_TMPDIR}/b\""
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"only_b.txt"* ]]
}

# ---------------------------------------------------------------------------
# Quiet recursive (-r)
# ---------------------------------------------------------------------------

@test "dir_compare -r: identical recursive trees return 0" {
  mkdir -p "${TEST_TMPDIR}/a/sub" "${TEST_TMPDIR}/b/sub"
  printf -- '%s\n' "deep" > "${TEST_TMPDIR}/a/sub/deep.txt"
  printf -- '%s\n' "deep" > "${TEST_TMPDIR}/b/sub/deep.txt"
  run shellac_run "include \"fs/dir\"; dir_compare -r \"${TEST_TMPDIR}/a\" \"${TEST_TMPDIR}/b\""
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
}

@test "dir_compare -r: different file content returns 1" {
  printf -- '%s\n' "version A" > "${TEST_TMPDIR}/a/file1.txt"
  printf -- '%s\n' "version B" > "${TEST_TMPDIR}/b/file1.txt"
  run shellac_run "include \"fs/dir\"; dir_compare -r \"${TEST_TMPDIR}/a\" \"${TEST_TMPDIR}/b\""
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
}

@test "dir_compare -r: missing nested file returns 1" {
  mkdir -p "${TEST_TMPDIR}/a/sub"
  printf -- '%s\n' "deep" > "${TEST_TMPDIR}/a/sub/deep.txt"
  run shellac_run "include \"fs/dir\"; dir_compare -r \"${TEST_TMPDIR}/a\" \"${TEST_TMPDIR}/b\""
  [ "${status}" -eq 1 ]
}

@test "dir_compare --recursive: long form is accepted" {
  run shellac_run "include \"fs/dir\"; dir_compare --recursive \"${TEST_TMPDIR}/a\" \"${TEST_TMPDIR}/b\""
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Verbose recursive (-r -v)
# ---------------------------------------------------------------------------

@test "dir_compare -r -v: identical trees return 0 with no output" {
  run shellac_run "include \"fs/dir\"; dir_compare -r -v \"${TEST_TMPDIR}/a\" \"${TEST_TMPDIR}/b\""
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
}

@test "dir_compare -r -v: content difference is reported" {
  printf -- '%s\n' "version A" > "${TEST_TMPDIR}/a/file1.txt"
  printf -- '%s\n' "version B" > "${TEST_TMPDIR}/b/file1.txt"
  run shellac_run "include \"fs/dir\"; dir_compare -r -v \"${TEST_TMPDIR}/a\" \"${TEST_TMPDIR}/b\""
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"file1.txt"* ]]
}

@test "dir_compare -rv: combined short form is accepted" {
  printf -- '%s\n' "version A" > "${TEST_TMPDIR}/a/file1.txt"
  printf -- '%s\n' "version B" > "${TEST_TMPDIR}/b/file1.txt"
  run shellac_run "include \"fs/dir\"; dir_compare -rv \"${TEST_TMPDIR}/a\" \"${TEST_TMPDIR}/b\""
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"file1.txt"* ]]
}

@test "dir_compare -vr: reversed combined short form is accepted" {
  run shellac_run "include \"fs/dir\"; dir_compare -vr \"${TEST_TMPDIR}/a\" \"${TEST_TMPDIR}/b\""
  [ "${status}" -eq 0 ]
}
