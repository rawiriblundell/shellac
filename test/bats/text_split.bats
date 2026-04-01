#!/usr/bin/env bats
# Tests for str_split in lib/sh/text/split.sh
# str_split stores results in the STR_SPLIT array (no stdout).

load 'helpers/setup'

@test "str_split: splits on delimiter and array has correct element count" {
  run shellac_run 'include "text/split"; str_split -d ":" "a:b:c"; printf "%d\n" "${#STR_SPLIT[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "3" ]
}

@test "str_split: first element is correct" {
  run shellac_run 'include "text/split"; str_split -d ":" "a:b:c"; printf "%s\n" "${STR_SPLIT[0]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "a" ]
}

@test "str_split: last element is correct" {
  run shellac_run 'include "text/split"; str_split -d ":" "a:b:c"; printf "%s\n" "${STR_SPLIT[2]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "c" ]
}

@test "str_split: whitespace split (no delimiter) stores each word as element" {
  run shellac_run 'include "text/split"; str_split "hello" "world" "foo"; printf "%d\n" "${#STR_SPLIT[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "3" ]
}

@test "str_split: single element on delimiter" {
  run shellac_run 'include "text/split"; str_split -d "/" "nodelimiter"; printf "%d\n" "${#STR_SPLIT[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "1" ]
}

@test "str_split: --delimiter long flag works" {
  run shellac_run 'include "text/split"; str_split --delimiter "," "x,y,z"; printf "%s\n" "${STR_SPLIT[1]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "y" ]
}
