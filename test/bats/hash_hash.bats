#!/usr/bin/env bats
# Tests for hash_set, hash_get, hash_has, hash_del, hash_keys, hash_values,
# hash_each in lib/sh/hash/hash.sh

load 'helpers/setup'

# ---------------------------------------------------------------------------
# hash_set / hash_get
# ---------------------------------------------------------------------------

@test "hash_set + hash_get: set and retrieve a value" {
  run shellac_run 'include "hash/hash"
    declare -A h
    hash_set h name Alice
    hash_get h name'
  [ "${status}" -eq 0 ]
  [ "${output}" = "Alice" ]
}

@test "hash_set: overwrites an existing key" {
  run shellac_run 'include "hash/hash"
    declare -A h
    hash_set h x first
    hash_set h x second
    hash_get h x'
  [ "${status}" -eq 0 ]
  [ "${output}" = "second" ]
}

@test "hash_get: exits 1 for missing key" {
  run shellac_run 'include "hash/hash"
    declare -A h
    hash_get h nosuchkey'
  [ "${status}" -eq 1 ]
}

@test "hash_get: value may be empty string" {
  run shellac_run 'include "hash/hash"
    declare -A h
    hash_set h empty ""
    hash_get h empty'
  [ "${status}" -eq 0 ]
  [ "${output}" = "" ]
}

# ---------------------------------------------------------------------------
# hash_has
# ---------------------------------------------------------------------------

@test "hash_has: returns 0 for existing key" {
  run shellac_run 'include "hash/hash"
    declare -A h
    hash_set h foo bar
    hash_has h foo'
  [ "${status}" -eq 0 ]
}

@test "hash_has: returns 1 for missing key" {
  run shellac_run 'include "hash/hash"
    declare -A h
    hash_has h nosuchkey'
  [ "${status}" -eq 1 ]
}

@test "hash_has: returns 0 for key with empty value" {
  run shellac_run 'include "hash/hash"
    declare -A h
    hash_set h empty ""
    hash_has h empty'
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# hash_del
# ---------------------------------------------------------------------------

@test "hash_del: removes an existing key" {
  run shellac_run 'include "hash/hash"
    declare -A h
    hash_set h k v
    hash_del h k
    hash_has h k'
  [ "${status}" -eq 1 ]
}

@test "hash_del: no-op for missing key" {
  run shellac_run 'include "hash/hash"
    declare -A h
    hash_del h nosuchkey'
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# hash_keys
# ---------------------------------------------------------------------------

@test "hash_keys: prints all keys" {
  run shellac_run 'include "hash/hash"
    declare -A h
    hash_set h b 2
    hash_set h a 1
    hash_set h c 3
    hash_keys h | sort'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'a\nb\nc')" ]
}

@test "hash_keys: empty array prints nothing" {
  run shellac_run 'include "hash/hash"
    declare -A h
    hash_keys h'
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
}

# ---------------------------------------------------------------------------
# hash_values
# ---------------------------------------------------------------------------

@test "hash_values: prints all values" {
  run shellac_run 'include "hash/hash"
    declare -A h
    hash_set h a 1
    hash_set h b 2
    hash_set h c 3
    hash_values h | sort -n'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '1\n2\n3')" ]
}

@test "hash_values: empty array prints nothing" {
  run shellac_run 'include "hash/hash"
    declare -A h
    hash_values h'
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
}

# ---------------------------------------------------------------------------
# hash_each
# ---------------------------------------------------------------------------

@test "hash_each: calls function with each key and value" {
  run shellac_run 'include "hash/hash"
    declare -A h
    hash_set h a 1
    hash_set h b 2
    print_pair() { printf "%s=%s\n" "${1}" "${2}"; }
    hash_each h print_pair | sort'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'a=1\nb=2')" ]
}

@test "hash_each: empty array calls function zero times" {
  run shellac_run 'include "hash/hash"
    declare -A h
    count=0
    counter() { (( count++ )) || true; }
    hash_each h counter
    printf "%d\n" "${count}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "0" ]
}
