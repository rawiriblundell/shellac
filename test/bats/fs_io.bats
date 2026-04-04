#!/usr/bin/env bats
# Tests for fs_read_file, fs_write_file, fs_append_line, fs_read_lines
# in lib/sh/fs/io.sh

load 'helpers/setup'
bats_require_minimum_version 1.5.0

# ---------------------------------------------------------------------------
# fs_read_file
# ---------------------------------------------------------------------------

@test "fs_read_file: reads file contents to stdout" {
  run shellac_run 'include "fs/io"
    tmp=$(mktemp)
    trap "rm -f ${tmp}" RETURN
    printf "%s\n" "hello world" > "${tmp}"
    fs_read_file "${tmp}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello world" ]
}

@test "fs_read_file: exits 1 for non-existent file" {
  run shellac_run 'include "fs/io"; fs_read_file /no/such/file/exists'
  [ "${status}" -eq 1 ]
}

@test "fs_read_file: exits 1 for a directory" {
  run shellac_run 'include "fs/io"; fs_read_file /tmp'
  [ "${status}" -eq 1 ]
}

@test "fs_read_file: missing argument exits non-zero" {
  run -127 shellac_run 'include "fs/io"; fs_read_file'
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# fs_write_file
# ---------------------------------------------------------------------------

@test "fs_write_file: writes content argument to file" {
  run shellac_run 'include "fs/io"
    tmp=$(mktemp)
    trap "rm -f ${tmp}" RETURN
    fs_write_file "${tmp}" "written content"
    cat "${tmp}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "written content" ]
}

@test "fs_write_file: reads from stdin when no content argument" {
  run shellac_run 'include "fs/io"
    tmp=$(mktemp)
    trap "rm -f ${tmp}" RETURN
    printf "%s\n" "from stdin" | fs_write_file "${tmp}"
    cat "${tmp}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "from stdin" ]
}

@test "fs_write_file: creates parent directories" {
  run shellac_run 'include "fs/io"
    dir=$(mktemp -d)
    trap "rm -rf ${dir}" RETURN
    fs_write_file "${dir}/a/b/c.txt" "nested"
    cat "${dir}/a/b/c.txt"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "nested" ]
}

@test "fs_write_file: overwrites existing file" {
  run shellac_run 'include "fs/io"
    tmp=$(mktemp)
    trap "rm -f ${tmp}" RETURN
    printf "%s\n" "old" > "${tmp}"
    fs_write_file "${tmp}" "new"
    cat "${tmp}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "new" ]
}

@test "fs_write_file: exits 1 when path is a directory" {
  run shellac_run 'include "fs/io"; fs_write_file /tmp'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# fs_append_line
# ---------------------------------------------------------------------------

@test "fs_append_line: appends a line to an existing file" {
  run shellac_run 'include "fs/io"
    tmp=$(mktemp)
    trap "rm -f ${tmp}" RETURN
    printf "%s\n" "first" > "${tmp}"
    fs_append_line "${tmp}" "second"
    cat "${tmp}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'first\nsecond')" ]
}

@test "fs_append_line: does not duplicate an existing line" {
  run shellac_run 'include "fs/io"
    tmp=$(mktemp)
    trap "rm -f ${tmp}" RETURN
    printf "%s\n" "existing" > "${tmp}"
    fs_append_line "${tmp}" "existing"
    fs_append_line "${tmp}" "existing"
    wc -l < "${tmp}" | tr -d " "'
  [ "${status}" -eq 0 ]
  [ "${output}" = "1" ]
}

@test "fs_append_line: creates file if it does not exist" {
  run shellac_run 'include "fs/io"
    dir=$(mktemp -d)
    trap "rm -rf ${dir}" RETURN
    fs_append_line "${dir}/new.txt" "hello"
    cat "${dir}/new.txt"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}

@test "fs_append_line: creates parent directories" {
  run shellac_run 'include "fs/io"
    dir=$(mktemp -d)
    trap "rm -rf ${dir}" RETURN
    fs_append_line "${dir}/a/b/lines.txt" "deep"
    cat "${dir}/a/b/lines.txt"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "deep" ]
}

# ---------------------------------------------------------------------------
# fs_read_lines
# ---------------------------------------------------------------------------

@test "fs_read_lines: populates FS_LINES array" {
  run shellac_run 'include "fs/io"
    tmp=$(mktemp)
    trap "rm -f ${tmp}" RETURN
    printf "%s\n" "alpha" "beta" "gamma" > "${tmp}"
    fs_read_lines "${tmp}"
    printf "%s\n" "${FS_LINES[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'alpha\nbeta\ngamma')" ]
}

@test "fs_read_lines -n: populates named array" {
  run shellac_run 'include "fs/io"
    tmp=$(mktemp)
    trap "rm -f ${tmp}" RETURN
    printf "%s\n" "one" "two" > "${tmp}"
    fs_read_lines -n my_arr "${tmp}"
    printf "%s\n" "${my_arr[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'one\ntwo')" ]
}

@test "fs_read_lines: exits 1 for non-existent file" {
  run shellac_run 'include "fs/io"; fs_read_lines /no/such/file'
  [ "${status}" -eq 1 ]
}

@test "fs_read_lines: preserves blank lines" {
  run shellac_run 'include "fs/io"
    tmp=$(mktemp)
    trap "rm -f ${tmp}" RETURN
    printf "%s\n" "a" "" "b" > "${tmp}"
    fs_read_lines "${tmp}"
    printf "%d\n" "${#FS_LINES[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "3" ]
}
