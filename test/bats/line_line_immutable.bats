#!/usr/bin/env bats
# Tests for line/line_immutable in lib/sh/line/line_immutable.sh

load 'helpers/setup'

@test "line_immutable: appends line when not present" {
  run shellac_run '
    include "line/line_immutable"
    tmp="$(mktemp)"
    printf "existing\n" > "${tmp}"
    line_immutable "newline" "${tmp}"
    cat "${tmp}"
    rm -f "${tmp}"
  '
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'existing\nnewline')" ]
}

@test "line_immutable: does not append when line already present" {
  run shellac_run '
    include "line/line_immutable"
    tmp="$(mktemp)"
    printf "existing\n" > "${tmp}"
    line_immutable "existing" "${tmp}"
    wc -l < "${tmp}" | tr -d " "
    rm -f "${tmp}"
  '
  [ "${status}" -eq 0 ]
  [ "${output}" = "1" ]
}

@test "line_immutable: --after inserts line after matching pattern" {
  run shellac_run '
    include "line/line_immutable"
    tmp="$(mktemp)"
    printf "aaa\nbbb\nccc\n" > "${tmp}"
    line_immutable --after "bbb" "inserted" "${tmp}"
    cat "${tmp}"
    rm -f "${tmp}"
  '
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'aaa\nbbb\ninserted\nccc')" ]
}

@test "line_immutable: --after fails when pattern not found" {
  run shellac_run '
    include "line/line_immutable"
    tmp="$(mktemp)"
    printf "aaa\nbbb\n" > "${tmp}"
    line_immutable --after "zzz" "inserted" "${tmp}"
    status_code=$?
    rm -f "${tmp}"
    exit ${status_code}
  '
  [ "${status}" -eq 1 ]
}

@test "line_immutable: --line-number inserts line before given line number" {
  run shellac_run '
    include "line/line_immutable"
    tmp="$(mktemp)"
    printf "aaa\nbbb\nccc\n" > "${tmp}"
    line_immutable --line-number 2 "inserted" "${tmp}"
    cat "${tmp}"
    rm -f "${tmp}"
  '
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'aaa\ninserted\nbbb\nccc')" ]
}

@test "line_immutable: fails when file does not exist" {
  run shellac_run 'include "line/line_immutable"; line_immutable "something" "/no/such/file"'
  [ "${status}" -eq 1 ]
}

@test "line_immutable: fails with unknown option" {
  run shellac_run '
    include "line/line_immutable"
    tmp="$(mktemp)"
    printf "aaa\n" > "${tmp}"
    line_immutable --bogus "val" "line" "${tmp}"
    status_code=$?
    rm -f "${tmp}"
    exit ${status_code}
  '
  [ "${status}" -eq 1 ]
}
