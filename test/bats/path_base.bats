#!/usr/bin/env bats
# Tests for path/base in lib/sh/path/base.sh

load 'helpers/setup'

@test "path_exists: returns 0 for a path that exists" {
  run shellac_run 'include "path/base"; path_exists /tmp'
  [ "${status}" -eq 0 ]
}

@test "path_exists: returns 1 for a path that does not exist" {
  run shellac_run 'include "path/base"; path_exists /no/such/path/xyz'
  [ "${status}" -eq 1 ]
}

@test "path_is_file: returns 0 for a regular file" {
  run shellac_run 'include "path/base"; tmp="$(mktemp)"; path_is_file "${tmp}"; rc=$?; rm -f "${tmp}"; exit ${rc}'
  [ "${status}" -eq 0 ]
}

@test "path_is_file: returns 1 for a directory" {
  run shellac_run 'include "path/base"; path_is_file /tmp'
  [ "${status}" -eq 1 ]
}

@test "path_is_directory: returns 0 for a directory" {
  run shellac_run 'include "path/base"; path_is_directory /tmp'
  [ "${status}" -eq 0 ]
}

@test "path_is_directory: returns 1 for a regular file" {
  run shellac_run 'include "path/base"; tmp="$(mktemp)"; path_is_directory "${tmp}"; rc=$?; rm -f "${tmp}"; exit ${rc}'
  [ "${status}" -eq 1 ]
}

@test "path_is_symlink: returns 0 for a symlink" {
  run shellac_run '
    include "path/base"
    tmp="$(mktemp)"
    link="${tmp}.link"
    ln -s "${tmp}" "${link}"
    path_is_symlink "${link}"
    rc=$?
    rm -f "${tmp}" "${link}"
    exit ${rc}
  '
  [ "${status}" -eq 0 ]
}

@test "path_is_symlink: returns 1 for a regular file" {
  run shellac_run 'include "path/base"; tmp="$(mktemp)"; path_is_symlink "${tmp}"; rc=$?; rm -f "${tmp}"; exit ${rc}'
  [ "${status}" -eq 1 ]
}

@test "path_is_readable: returns 0 for a readable file" {
  run shellac_run 'include "path/base"; path_is_readable /etc/os-release'
  [ "${status}" -eq 0 ]
}

@test "path_is_writeable: returns 0 for /tmp" {
  run shellac_run 'include "path/base"; path_is_writeable /tmp'
  [ "${status}" -eq 0 ]
}

@test "path_is_executable: returns 0 for /bin/sh" {
  run shellac_run 'include "path/base"; path_is_executable /bin/sh'
  [ "${status}" -eq 0 ]
}

@test "path_is_absolute: returns 0 for an absolute path" {
  run shellac_run 'include "path/base"; path_is_absolute /foo/bar'
  [ "${status}" -eq 0 ]
}

@test "path_is_absolute: returns 1 for a relative path" {
  run shellac_run 'include "path/base"; path_is_absolute foo/bar'
  [ "${status}" -eq 1 ]
}

@test "path_is_relative: returns 0 for a relative path" {
  run shellac_run 'include "path/base"; path_is_relative foo/bar'
  [ "${status}" -eq 0 ]
}

@test "path_is_relative: returns 1 for an absolute path" {
  run shellac_run 'include "path/base"; path_is_relative /foo/bar'
  [ "${status}" -eq 1 ]
}

@test "path_is_empty_dir: returns 0 for an empty directory" {
  run shellac_run '
    include "path/base"
    tmp="$(mktemp -d)"
    path_is_empty_dir "${tmp}"
    rc=$?
    rmdir "${tmp}"
    exit ${rc}
  '
  [ "${status}" -eq 0 ]
}

@test "path_is_empty_dir: returns 1 for a non-empty directory" {
  run shellac_run '
    include "path/base"
    tmp="$(mktemp -d)"
    touch "${tmp}/file"
    path_is_empty_dir "${tmp}"
    rc=$?
    rm -rf "${tmp}"
    exit ${rc}
  '
  [ "${status}" -eq 1 ]
}

@test "path_absolute: resolves a relative path to absolute" {
  run shellac_run '
    include "path/base"
    tmp="$(mktemp)"
    result="$(path_absolute "${tmp}")"
    rc=$?
    rm -f "${tmp}"
    printf "%s\n" "${result}"
    exit ${rc}
  '
  [ "${status}" -eq 0 ]
  [[ "${output}" == /* ]]
}

@test "path_absolute: returns 1 for a non-existent path" {
  run shellac_run 'include "path/base"; path_absolute /no/such/path/xyz'
  [ "${status}" -eq 1 ]
}

@test "path_basename: strips directory prefix" {
  run shellac_run 'include "path/base"; path_basename /foo/bar/baz.txt'
  [ "${status}" -eq 0 ]
  [ "${output}" = "baz.txt" ]
}

@test "path_basename: root file" {
  run shellac_run 'include "path/base"; path_basename /file'
  [ "${status}" -eq 0 ]
  [ "${output}" = "file" ]
}

@test "path_dirname: strips filename component" {
  run shellac_run 'include "path/base"; path_dirname /foo/bar/baz.txt'
  [ "${status}" -eq 0 ]
  [ "${output}" = "/foo/bar" ]
}

@test "path_extension: returns extension without dot" {
  run shellac_run 'include "path/base"; path_extension /foo/bar.txt'
  [ "${status}" -eq 0 ]
  [ "${output}" = "txt" ]
}

@test "path_extension: returns last extension for multi-extension files" {
  run shellac_run 'include "path/base"; path_extension /foo/archive.tar.gz'
  [ "${status}" -eq 0 ]
  [ "${output}" = "gz" ]
}

@test "path_extension: returns 1 for file with no extension" {
  run shellac_run 'include "path/base"; path_extension /foo/noext'
  [ "${status}" -eq 1 ]
}

@test "path_extension: returns 2 when called with no argument" {
  run shellac_run 'include "path/base"; path_extension'
  [ "${status}" -eq 2 ]
}

@test "path_stem: returns filename without extension" {
  run shellac_run 'include "path/base"; path_stem /foo/bar.txt'
  [ "${status}" -eq 0 ]
  [ "${output}" = "bar" ]
}

@test "path_stem: returns filename unchanged when no extension" {
  run shellac_run 'include "path/base"; path_stem /foo/bar'
  [ "${status}" -eq 0 ]
  [ "${output}" = "bar" ]
}

@test "path_strip_extension: returns path without final extension" {
  run shellac_run 'include "path/base"; path_strip_extension /foo/bar.txt'
  [ "${status}" -eq 0 ]
  [ "${output}" = "/foo/bar" ]
}

@test "path_strip_extension: leaves path unchanged when no extension" {
  run shellac_run 'include "path/base"; path_strip_extension /foo/noext'
  [ "${status}" -eq 0 ]
  [ "${output}" = "/foo/noext" ]
}

@test "path_replace_extension: replaces extension" {
  run shellac_run 'include "path/base"; path_replace_extension /foo/bar.txt .md'
  [ "${status}" -eq 0 ]
  [ "${output}" = "/foo/bar.md" ]
}

@test "path_normalize: resolves .. components" {
  run shellac_run 'include "path/base"; path_normalize /foo/bar/../baz'
  [ "${status}" -eq 0 ]
  [ "${output}" = "/foo/baz" ]
}

@test "path_normalize: resolves . components" {
  run shellac_run 'include "path/base"; path_normalize /foo/./bar'
  [ "${status}" -eq 0 ]
  [ "${output}" = "/foo/bar" ]
}

@test "path_normalize: collapses double slashes" {
  run shellac_run 'include "path/base"; path_normalize "foo//bar"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "foo/bar" ]
}

@test "path_relative: computes relative path between two absolute paths" {
  run shellac_run 'include "path/base"; path_relative /foo/bar /foo/bar/baz'
  [ "${status}" -eq 0 ]
  [ "${output}" = "baz" ]
}

@test "path_relative: computes ../sibling relationship" {
  run shellac_run 'include "path/base"; path_relative /foo/bar /foo/qux'
  [ "${status}" -eq 0 ]
  [ "${output}" = "../qux" ]
}

@test "path_relative: returns . when from and to are the same" {
  run shellac_run 'include "path/base"; path_relative /foo/bar /foo/bar'
  [ "${status}" -eq 0 ]
  [ "${output}" = "." ]
}
