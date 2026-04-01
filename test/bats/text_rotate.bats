#!/usr/bin/env bats
# Tests for str_rotate in lib/sh/text/rotate.sh

load 'helpers/setup'

@test "str_rotate: right shift by 2" {
  run shellac_run 'include "text/rotate"; str_rotate "abcdefg" 2'
  [ "${status}" -eq 0 ]
  [ "${output}" = "fgabcde" ]
}

@test "str_rotate: left shift by 2 (negative)" {
  run shellac_run 'include "text/rotate"; str_rotate "abcdefg" -2'
  [ "${status}" -eq 0 ]
  [ "${output}" = "cdefgab" ]
}

@test "str_rotate: shift by full length is a no-op" {
  run shellac_run 'include "text/rotate"; str_rotate "abcdefg" 7'
  [ "${status}" -eq 0 ]
  [ "${output}" = "abcdefg" ]
}

@test "str_rotate: shift by 0 is a no-op" {
  run shellac_run 'include "text/rotate"; str_rotate "abcdefg" 0'
  [ "${status}" -eq 0 ]
  [ "${output}" = "abcdefg" ]
}

@test "str_rotate: empty string produces no output and exits 0" {
  run shellac_run 'include "text/rotate"; str_rotate "" 3'
  [ "${status}" -eq 0 ]
  [ "${output}" = "" ]
}

@test "str_rotate: non-integer shift returns exit 1" {
  run shellac_run 'include "text/rotate"; str_rotate "hello" "abc"'
  [ "${status}" -eq 1 ]
}

@test "str_rotate: default shift of 0 (no second arg)" {
  run shellac_run 'include "text/rotate"; str_rotate "hello"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}
