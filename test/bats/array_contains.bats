#!/usr/bin/env bats
# Tests for array_grep, array_index, array_some, array_every, array_last_index,
# array_find, array_find_last in lib/sh/array/contains.sh

load 'helpers/setup'

# ---------------------------------------------------------------------------
# array_grep
# ---------------------------------------------------------------------------

@test "array_grep: matches element with regex" {
  run shellac_run 'include "array/contains"
    arr=(apple banana cherry)
    array_grep "^ban" "${arr[@]}"'
  [ "${status}" -eq 0 ]
}

@test "array_grep: no match fails" {
  run shellac_run 'include "array/contains"
    arr=(apple banana cherry)
    array_grep "^xyz" "${arr[@]}"'
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# array_index
# ---------------------------------------------------------------------------

@test "array_index: returns zero-based index of first match" {
  run shellac_run 'include "array/contains"
    arr=(a b c)
    array_index arr b'
  [ "${status}" -eq 0 ]
  [ "${output}" = "1" ]
}

@test "array_index: returns 0 for first element" {
  run shellac_run 'include "array/contains"
    arr=(a b c)
    array_index arr a'
  [ "${status}" -eq 0 ]
  [ "${output}" = "0" ]
}

@test "array_index: element not found fails" {
  run shellac_run 'include "array/contains"
    arr=(a b c)
    array_index arr z'
  [ "${status}" -ne 0 ]
}

@test "array_index: returns index of first occurrence when duplicates exist" {
  run shellac_run 'include "array/contains"
    arr=(a b c b d)
    array_index arr b'
  [ "${status}" -eq 0 ]
  [ "${output}" = "1" ]
}

# ---------------------------------------------------------------------------
# array_some
# ---------------------------------------------------------------------------

@test "array_some: returns 0 when at least one element matches glob" {
  run shellac_run 'include "array/contains"
    arr=(apple banana cherry)
    array_some arr "ban*"'
  [ "${status}" -eq 0 ]
}

@test "array_some: returns 1 when no element matches glob" {
  run shellac_run 'include "array/contains"
    arr=(apple banana cherry)
    array_some arr "xyz*"'
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# array_every
# ---------------------------------------------------------------------------

@test "array_every: returns 0 when all elements match glob" {
  run shellac_run 'include "array/contains"
    arr=(apple apricot avocado)
    array_every arr "a*"'
  [ "${status}" -eq 0 ]
}

@test "array_every: returns 1 when one element does not match" {
  run shellac_run 'include "array/contains"
    arr=(apple banana cherry)
    array_every arr "a*"'
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# array_last_index
# ---------------------------------------------------------------------------

@test "array_last_index: returns index of last occurrence" {
  run shellac_run 'include "array/contains"
    arr=(a b c b d)
    array_last_index arr b'
  [ "${status}" -eq 0 ]
  [ "${output}" = "3" ]
}

@test "array_last_index: single occurrence returns that index" {
  run shellac_run 'include "array/contains"
    arr=(a b c)
    array_last_index arr c'
  [ "${status}" -eq 0 ]
  [ "${output}" = "2" ]
}

@test "array_last_index: element not found fails" {
  run shellac_run 'include "array/contains"
    arr=(a b c)
    array_last_index arr z'
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# array_find
# ---------------------------------------------------------------------------

@test "array_find: returns first matching element" {
  run shellac_run 'include "array/contains"
    arr=(apple banana cherry)
    array_find arr "b*"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "banana" ]
}

@test "array_find: no match fails" {
  run shellac_run 'include "array/contains"
    arr=(apple banana cherry)
    array_find arr "z*"'
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# array_find_last
# ---------------------------------------------------------------------------

@test "array_find_last: returns last matching element" {
  run shellac_run 'include "array/contains"
    arr=(apple banana cherry apricot)
    array_find_last arr "a*"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "apricot" ]
}

@test "array_find_last: no match fails" {
  run shellac_run 'include "array/contains"
    arr=(apple banana)
    array_find_last arr "z*"'
  [ "${status}" -ne 0 ]
}
