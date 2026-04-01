#!/usr/bin/env bats
# Tests for line/line in lib/sh/line/line.sh

load 'helpers/setup'

@test "line_count: counts lines from a string argument" {
  run shellac_run 'include "line/line"; line_count "$(printf "a\nb\nc")"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "3" ]
}

@test "line_count: counts lines from stdin" {
  run shellac_run 'include "line/line"; printf "a\nb\nc\n" | line_count'
  [ "${status}" -eq 0 ]
  [ "${output}" = "3" ]
}

@test "line_at: returns the Nth line from stdin" {
  run shellac_run 'include "line/line"; printf "a\nb\nc\n" | line_at 2'
  [ "${status}" -eq 0 ]
  [ "${output}" = "b" ]
}

@test "line_at: returns the first line" {
  run shellac_run 'include "line/line"; printf "a\nb\nc\n" | line_at 1'
  [ "${status}" -eq 0 ]
  [ "${output}" = "a" ]
}

@test "line_at: returns the last line" {
  run shellac_run 'include "line/line"; printf "a\nb\nc\n" | line_at 3'
  [ "${status}" -eq 0 ]
  [ "${output}" = "c" ]
}

@test "line_first: returns the first line from stdin" {
  run shellac_run 'include "line/line"; printf "a\nb\nc\n" | line_first'
  [ "${status}" -eq 0 ]
  [ "${output}" = "a" ]
}

@test "line_last: returns the last line from stdin" {
  run shellac_run 'include "line/line"; printf "a\nb\nc\n" | line_last'
  [ "${status}" -eq 0 ]
  [ "${output}" = "c" ]
}

@test "line_grep: returns matching lines" {
  run shellac_run 'include "line/line"; printf "foo\nbar\nbaz\n" | line_grep "ba"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'bar\nbaz')" ]
}

@test "line_grep: returns exit 1 when no match" {
  run shellac_run 'include "line/line"; printf "foo\nbar\n" | line_grep "zzz"'
  [ "${status}" -eq 1 ]
}

@test "line_unique: removes duplicate lines preserving order" {
  run shellac_run 'include "line/line"; printf "a\nb\na\nc\nb\n" | line_unique'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'a\nb\nc')" ]
}

@test "line_sort: sorts lines alphabetically" {
  run shellac_run 'include "line/line"; printf "b\na\nc\n" | line_sort'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'a\nb\nc')" ]
}

@test "line_reverse: reverses the order of lines" {
  run shellac_run 'include "line/line"; printf "a\nb\nc\n" | line_reverse'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'c\nb\na')" ]
}

@test "line_trim_each: strips leading and trailing whitespace from each line" {
  run shellac_run 'include "line/line"; printf "  foo  \n  bar  \n" | line_trim_each'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'foo\nbar')" ]
}

@test "line_append: appends line to file if not present" {
  run shellac_run '
    include "line/line"
    tmp="$(mktemp)"
    printf "existing\n" > "${tmp}"
    line_append "newline" "${tmp}"
    cat "${tmp}"
    rm -f "${tmp}"
  '
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'existing\nnewline')" ]
}

@test "line_append: does not duplicate a line already present" {
  run shellac_run '
    include "line/line"
    tmp="$(mktemp)"
    printf "existing\n" > "${tmp}"
    line_append "existing" "${tmp}"
    line_append "existing" "${tmp}"
    wc -l < "${tmp}" | tr -d " "
    rm -f "${tmp}"
  '
  [ "${status}" -eq 0 ]
  [ "${output}" = "1" ]
}

@test "line_remove: removes matching lines from file" {
  run shellac_run '
    include "line/line"
    tmp="$(mktemp)"
    printf "keep\nremove\nkeep\n" > "${tmp}"
    line_remove "remove" "${tmp}"
    cat "${tmp}"
    rm -f "${tmp}"
  '
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'keep\nkeep')" ]
}

@test "line_remove: fails on non-writable file" {
  run shellac_run '
    include "line/line"
    tmp="$(mktemp)"
    printf "content\n" > "${tmp}"
    chmod 444 "${tmp}"
    line_remove "content" "${tmp}"
    status_code=$?
    chmod 644 "${tmp}"
    rm -f "${tmp}"
    exit ${status_code}
  '
  [ "${status}" -eq 1 ]
}
