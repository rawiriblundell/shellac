#!/usr/bin/env bats
# Tests for str_hash in lib/sh/text/hash.sh

load 'helpers/setup'

@test "str_hash: md5 of a known string has correct length (32 hex chars)" {
  run shellac_run 'include "text/hash"; str_hash md5 "hello"'
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9a-f]{32}$ ]]
}

@test "str_hash: sha256 of a known string has correct length (64 hex chars)" {
  run shellac_run 'include "text/hash"; str_hash sha256 "hello"'
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9a-f]{64}$ ]]
}

@test "str_hash: sha1 of a known string has correct length (40 hex chars)" {
  run shellac_run 'include "text/hash"; str_hash sha1 "hello"'
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9a-f]{40}$ ]]
}

@test "str_hash: sha512 of a known string has correct length (128 hex chars)" {
  run shellac_run 'include "text/hash"; str_hash sha512 "hello"'
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9a-f]{128}$ ]]
}

@test "str_hash: default (no algo) falls back to md5 length" {
  run shellac_run 'include "text/hash"; str_hash "hello"'
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9a-f]{32}$ ]]
}

@test "str_hash: same input produces same digest" {
  run shellac_run 'include "text/hash"; a=$(str_hash md5 "hello"); b=$(str_hash md5 "hello"); [ "${a}" = "${b}" ]'
  [ "${status}" -eq 0 ]
}

@test "str_hash: different inputs produce different digests" {
  run shellac_run 'include "text/hash"; a=$(str_hash md5 "hello"); b=$(str_hash md5 "world"); [ "${a}" != "${b}" ]'
  [ "${status}" -eq 0 ]
}

@test "str_hash: stdin mode works" {
  run shellac_run 'include "text/hash"; printf "%s\n" "hello" | str_hash md5'
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9a-f]{32}$ ]]
}
