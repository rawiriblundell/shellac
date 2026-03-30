#!/usr/bin/env bats
# Tests for array_sort, array_sort_numeric, array_sort_natural, array_reverse,
# and array_shuffle in lib/sh/array/sort.sh

load 'helpers/setup'

# ---------------------------------------------------------------------------
# array_sort
# ---------------------------------------------------------------------------

@test "array_sort: sorts lexicographically" {
  run shellac_run 'include "array/sort"
    a=( banana apple cherry )
    array_sort a
    printf "%s\n" "${a[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'apple\nbanana\ncherry')" ]
}

@test "array_sort: already sorted is a no-op" {
  run shellac_run 'include "array/sort"
    a=( a b c )
    array_sort a
    printf "%s\n" "${a[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'a\nb\nc')" ]
}

@test "array_sort: single element" {
  run shellac_run 'include "array/sort"
    a=( only )
    array_sort a
    printf "%s\n" "${a[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "only" ]
}

# ---------------------------------------------------------------------------
# array_sort_numeric
# ---------------------------------------------------------------------------

@test "array_sort_numeric: sorts by numeric value" {
  run shellac_run 'include "array/sort"
    a=( 10 2 1 20 3 )
    array_sort_numeric a
    printf "%s\n" "${a[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '1\n2\n3\n10\n20')" ]
}

@test "array_sort_numeric: handles negative numbers" {
  run shellac_run 'include "array/sort"
    a=( 0 -5 3 -1 )
    array_sort_numeric a
    printf "%s\n" "${a[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf -- '-5\n-1\n0\n3')" ]
}

# ---------------------------------------------------------------------------
# array_sort_natural
# ---------------------------------------------------------------------------

@test "array_sort_natural: sorts embedded numbers naturally" {
  run shellac_run 'include "array/sort"
    a=( file10.txt file2.txt file1.txt )
    array_sort_natural a
    printf "%s\n" "${a[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'file1.txt\nfile2.txt\nfile10.txt')" ]
}

@test "array_sort_natural: sorts version strings naturally" {
  run shellac_run 'include "array/sort"
    a=( v1.10 v1.9 v1.2 v2.0 )
    array_sort_natural a
    printf "%s\n" "${a[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'v1.2\nv1.9\nv1.10\nv2.0')" ]
}

@test "array_sort_natural: single element" {
  run shellac_run 'include "array/sort"
    a=( only )
    array_sort_natural a
    printf "%s\n" "${a[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "only" ]
}

@test "array_sort_natural: lexicographic strings sort correctly" {
  run shellac_run 'include "array/sort"
    a=( cherry apple banana )
    array_sort_natural a
    printf "%s\n" "${a[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'apple\nbanana\ncherry')" ]
}

# ---------------------------------------------------------------------------
# array_reverse
# ---------------------------------------------------------------------------

@test "array_reverse: reverses order" {
  run shellac_run 'include "array/sort"
    a=( a b c d e )
    array_reverse a
    printf "%s\n" "${a[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'e\nd\nc\nb\na')" ]
}

@test "array_reverse: single element is unchanged" {
  run shellac_run 'include "array/sort"
    a=( only )
    array_reverse a
    printf "%s\n" "${a[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "only" ]
}

@test "array_reverse: two elements swap" {
  run shellac_run 'include "array/sort"
    a=( first second )
    array_reverse a
    printf "%s\n" "${a[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'second\nfirst')" ]
}

# ---------------------------------------------------------------------------
# array_shuffle
# ---------------------------------------------------------------------------

@test "array_shuffle: preserves all elements" {
  run shellac_run 'include "array/sort"
    a=( 1 2 3 4 5 )
    array_shuffle a
    printf "%s\n" "${a[@]}" | sort -n'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '1\n2\n3\n4\n5')" ]
}

@test "array_shuffle: preserves element count" {
  run shellac_run 'include "array/sort"
    a=( a b c d e f )
    array_shuffle a
    printf "%d\n" "${#a[@]}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "6" ]
}
