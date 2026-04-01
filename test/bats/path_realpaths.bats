#!/usr/bin/env bats
# Tests for path/realpaths in lib/sh/path/realpaths.sh
# Note: realpath_* functions write to REPLY, not stdout.

load 'helpers/setup'

@test "realpath_basename: sets REPLY to filename component" {
  run shellac_run '
    include "path/realpaths"
    realpath_basename "/foo/bar/baz.txt"
    printf "%s\n" "${REPLY}"
  '
  [ "${status}" -eq 0 ]
  [ "${output}" = "baz.txt" ]
}

@test "realpath_basename: sets REPLY to / for bare slash" {
  run shellac_run '
    include "path/realpaths"
    realpath_basename "/"
    printf "%s\n" "${REPLY}"
  '
  [ "${status}" -eq 0 ]
  [ "${output}" = "/" ]
}

@test "realpath_dirname: sets REPLY to directory component" {
  run shellac_run '
    include "path/realpaths"
    realpath_dirname "/foo/bar/baz.txt"
    printf "%s\n" "${REPLY}"
  '
  [ "${status}" -eq 0 ]
  [ "${output}" = "/foo/bar" ]
}

@test "realpath_dirname: sets REPLY to . for bare filename" {
  run shellac_run '
    include "path/realpaths"
    realpath_dirname "filename"
    printf "%s\n" "${REPLY}"
  '
  [ "${status}" -eq 0 ]
  [ "${output}" = "." ]
}

@test "realpath_absolute: resolves relative path against PWD" {
  run shellac_run '
    include "path/realpaths"
    realpath_absolute "subdir/file"
    printf "%s\n" "${REPLY}"
  '
  [ "${status}" -eq 0 ]
  [[ "${output}" == /* ]]
}

@test "realpath_absolute: resolves .. component" {
  run shellac_run '
    include "path/realpaths"
    realpath_absolute "/foo/bar/.."
    printf "%s\n" "${REPLY}"
  '
  [ "${status}" -eq 0 ]
  [ "${output}" = "/foo" ]
}

@test "realpath_follow: sets REPLY to the path itself when not a symlink" {
  run shellac_run '
    include "path/realpaths"
    tmp="$(mktemp)"
    realpath_follow "${tmp}"
    printf "%s\n" "${REPLY}"
    rm -f "${tmp}"
  '
  [ "${status}" -eq 0 ]
  [[ "${output}" == /tmp/* ]]
}

@test "realpath_follow: resolves a symlink" {
  run shellac_run '
    include "path/realpaths"
    tmp="$(mktemp)"
    link="${tmp}.link"
    ln -s "${tmp}" "${link}"
    realpath_follow "${link}"
    printf "%s\n" "${REPLY}"
    rm -f "${tmp}" "${link}"
  '
  [ "${status}" -eq 0 ]
  [[ "${output}" == /tmp/* ]]
}

@test "realpath_portable_follow: resolves a regular file path" {
  run shellac_run '
    include "path/realpaths"
    tmp="$(mktemp)"
    realpath_portable_follow "${tmp}"
    rm -f "${tmp}"
  '
  [ "${status}" -eq 0 ]
  [[ "${output}" == /* ]]
}

@test "realpath_portable_follow: returns 1 for non-existent path" {
  run shellac_run 'include "path/realpaths"; realpath_portable_follow /no/such/path/xyz'
  [ "${status}" -eq 1 ]
}

@test "realpath_relative: sets REPLY to relative path from base" {
  run shellac_run '
    include "path/realpaths"
    realpath_relative /foo/bar/baz /foo/bar
    printf "%s\n" "${REPLY}"
  '
  [ "${status}" -eq 0 ]
  [ "${output}" = "baz" ]
}
