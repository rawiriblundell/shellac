#!/usr/bin/env bats
# Tests for crypto/uuid in lib/sh/crypto/uuid.sh

load 'helpers/setup'

setup() {
  :
}

teardown() {
  :
}

# ---------------------------------------------------------------------------
# uuid_nil
# ---------------------------------------------------------------------------

@test "uuid_nil: returns the all-zeros UUID" {
  run shellac_run 'include "crypto/uuid"; uuid_nil'
  [ "${status}" -eq 0 ]
  [ "${output}" = "00000000-0000-0000-0000-000000000000" ]
}

# ---------------------------------------------------------------------------
# validate_uuid
# ---------------------------------------------------------------------------

@test "validate_uuid: accepts the nil UUID" {
  run shellac_run 'include "crypto/uuid"; validate_uuid "00000000-0000-0000-0000-000000000000"'
  [ "${status}" -eq 0 ]
}

@test "validate_uuid: accepts a valid v4-style UUID" {
  run shellac_run 'include "crypto/uuid"; validate_uuid "550e8400-e29b-41d4-a716-446655440000"'
  [ "${status}" -eq 0 ]
}

@test "validate_uuid: rejects wrong structure (too short)" {
  run shellac_run 'include "crypto/uuid"; validate_uuid "550e8400-e29b-41d4-a716"'
  [ "${status}" -ne 0 ]
}

@test "validate_uuid: rejects non-hex characters" {
  run shellac_run 'include "crypto/uuid"; validate_uuid "gggggggg-e29b-41d4-a716-446655440000"'
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# uuid_v4
# ---------------------------------------------------------------------------

@test "uuid_v4: exits 0 and produces output" {
  run shellac_run 'include "crypto/uuid"; uuid_v4'
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]
}

@test "uuid_v4: output is 36 characters long" {
  run shellac_run 'include "crypto/uuid"; uuid_v4'
  [ "${status}" -eq 0 ]
  [ "${#output}" -eq 36 ]
}

@test "uuid_v4: output matches 8-4-4-4-12 structure" {
  run shellac_run 'include "crypto/uuid"; uuid_v4'
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]
}

@test "uuid_v4: two consecutive calls produce different UUIDs" {
  run shellac_run 'include "crypto/uuid"; uuid_v4; uuid_v4'
  [ "${status}" -eq 0 ]
  first=$(printf '%s\n' "${output}" | head -1)
  second=$(printf '%s\n' "${output}" | tail -1)
  [ "${first}" != "${second}" ]
}

# ---------------------------------------------------------------------------
# uuid_v1
# ---------------------------------------------------------------------------

@test "uuid_v1: exits 0 and produces 36-char output" {
  run shellac_run 'include "crypto/uuid"; uuid_v1'
  [ "${status}" -eq 0 ]
  [ "${#output}" -eq 36 ]
}

# ---------------------------------------------------------------------------
# uuid_v2
# ---------------------------------------------------------------------------

@test "uuid_v2: always returns exit code 1" {
  run shellac_run 'include "crypto/uuid"; uuid_v2'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# uuid_v3
# ---------------------------------------------------------------------------

@test "uuid_v3: produces a UUID for known namespace+name" {
  run shellac_run 'include "crypto/uuid"; uuid_v3 @dns "example.com"'
  [ "${status}" -eq 0 ]
  [ "${#output}" -eq 36 ]
}

@test "uuid_v3: same namespace+name always yields the same UUID" {
  run shellac_run 'include "crypto/uuid"; uuid_v3 @dns "example.com"; uuid_v3 @dns "example.com"'
  [ "${status}" -eq 0 ]
  first=$(printf '%s\n' "${output}" | head -1)
  second=$(printf '%s\n' "${output}" | tail -1)
  [ "${first}" = "${second}" ]
}

@test "uuid_v3: different names yield different UUIDs" {
  run shellac_run 'include "crypto/uuid"; uuid_v3 @dns "a.example.com"; uuid_v3 @dns "b.example.com"'
  [ "${status}" -eq 0 ]
  first=$(printf '%s\n' "${output}" | head -1)
  second=$(printf '%s\n' "${output}" | tail -1)
  [ "${first}" != "${second}" ]
}

# ---------------------------------------------------------------------------
# uuid_v5
# ---------------------------------------------------------------------------

@test "uuid_v5: produces a UUID for known namespace+name" {
  run shellac_run 'include "crypto/uuid"; uuid_v5 @url "https://example.com"'
  [ "${status}" -eq 0 ]
  [ "${#output}" -eq 36 ]
}

@test "uuid_v5: same namespace+name always yields the same UUID" {
  run shellac_run 'include "crypto/uuid"; uuid_v5 @url "https://example.com"; uuid_v5 @url "https://example.com"'
  [ "${status}" -eq 0 ]
  first=$(printf '%s\n' "${output}" | head -1)
  second=$(printf '%s\n' "${output}" | tail -1)
  [ "${first}" = "${second}" ]
}

# ---------------------------------------------------------------------------
# uuid_v6
# ---------------------------------------------------------------------------

@test "uuid_v6: exits 0 and produces 36-char output" {
  run shellac_run 'include "crypto/uuid"; uuid_v6'
  [ "${status}" -eq 0 ]
  [ "${#output}" -eq 36 ]
}

# ---------------------------------------------------------------------------
# uuid_v7
# ---------------------------------------------------------------------------

@test "uuid_v7: exits 0 and produces 36-char output" {
  run shellac_run 'include "crypto/uuid"; uuid_v7'
  [ "${status}" -eq 0 ]
  [ "${#output}" -eq 36 ]
}

# ---------------------------------------------------------------------------
# uuid_v8
# ---------------------------------------------------------------------------

@test "uuid_v8: exits 0 with no args and produces 36-char output" {
  run shellac_run 'include "crypto/uuid"; uuid_v8'
  [ "${status}" -eq 0 ]
  [ "${#output}" -eq 36 ]
}

@test "uuid_v8: rejects unknown option" {
  run shellac_run 'include "crypto/uuid"; uuid_v8 --bad-option foo'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# uuid_gen
# ---------------------------------------------------------------------------

@test "uuid_gen: default (no args) produces a v4 UUID" {
  run shellac_run 'include "crypto/uuid"; uuid_gen'
  [ "${status}" -eq 0 ]
  [ "${#output}" -eq 36 ]
}

@test "uuid_gen: -nil returns the nil UUID" {
  run shellac_run 'include "crypto/uuid"; uuid_gen -nil'
  [ "${status}" -eq 0 ]
  [ "${output}" = "00000000-0000-0000-0000-000000000000" ]
}

@test "uuid_gen: -4 returns a random UUID" {
  run shellac_run 'include "crypto/uuid"; uuid_gen -4'
  [ "${status}" -eq 0 ]
  [ "${#output}" -eq 36 ]
}

@test "uuid_gen: unknown flag returns exit 1" {
  run shellac_run 'include "crypto/uuid"; uuid_gen --no-such-flag'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# uuid_switch_endian
# ---------------------------------------------------------------------------

@test "uuid_switch_endian: swaps a known UUID and returns 36 chars" {
  run shellac_run 'include "crypto/uuid"; uuid_switch_endian "550e8400-e29b-41d4-a716-446655440000"'
  [ "${status}" -eq 0 ]
  [ "${#output}" -eq 36 ]
}

@test "uuid_switch_endian: rejects string that is too short" {
  run shellac_run 'include "crypto/uuid"; uuid_switch_endian "short"'
  [ "${status}" -eq 1 ]
}

@test "uuid_switch_endian: double swap returns original UUID" {
  run shellac_run '
    include "crypto/uuid"
    orig="550e8400-e29b-41d4-a716-446655440000"
    swapped=$(uuid_switch_endian "${orig}")
    uuid_switch_endian "${swapped}"
  '
  [ "${status}" -eq 0 ]
  [ "${output}" = "550e8400-e29b-41d4-a716-446655440000" ]
}

# ---------------------------------------------------------------------------
# uuid_pseudo
# ---------------------------------------------------------------------------

@test "uuid_pseudo: exits 0 and produces output" {
  run shellac_run 'include "crypto/uuid"; uuid_pseudo'
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]
}
