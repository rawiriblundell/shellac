#!/usr/bin/env bats
# Tests for str_remove_prefix, str_remove_suffix, str_append_if_missing,
# str_prepend_if_missing, str_append, str_prepend, prepend
# in lib/sh/text/prefix_suffix.sh

load 'helpers/setup'

# ---------------------------------------------------------------------------
# str_remove_prefix
# ---------------------------------------------------------------------------

@test "str_remove_prefix: removes matching prefix" {
  run shellac_run 'include "text/prefix_suffix"; str_remove_prefix "foobar" "foo"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "bar" ]
}

@test "str_remove_prefix: no-op when prefix not present" {
  run shellac_run 'include "text/prefix_suffix"; str_remove_prefix "foobar" "baz"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "foobar" ]
}

# ---------------------------------------------------------------------------
# str_remove_suffix
# ---------------------------------------------------------------------------

@test "str_remove_suffix: removes matching suffix" {
  run shellac_run 'include "text/prefix_suffix"; str_remove_suffix "foobar" "bar"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "foo" ]
}

@test "str_remove_suffix: no-op when suffix not present" {
  run shellac_run 'include "text/prefix_suffix"; str_remove_suffix "foobar" "baz"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "foobar" ]
}

# ---------------------------------------------------------------------------
# str_append_if_missing
# ---------------------------------------------------------------------------

@test "str_append_if_missing: appends when suffix absent" {
  run shellac_run 'include "text/prefix_suffix"; str_append_if_missing "/etc/hosts" "/"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "/etc/hosts/" ]
}

@test "str_append_if_missing: no-op when suffix already present" {
  run shellac_run 'include "text/prefix_suffix"; str_append_if_missing "/etc/hosts/" "/"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "/etc/hosts/" ]
}

# ---------------------------------------------------------------------------
# str_prepend_if_missing
# ---------------------------------------------------------------------------

@test "str_prepend_if_missing: prepends when prefix absent" {
  run shellac_run 'include "text/prefix_suffix"; str_prepend_if_missing "etc/hosts" "/"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "/etc/hosts" ]
}

@test "str_prepend_if_missing: no-op when prefix already present" {
  run shellac_run 'include "text/prefix_suffix"; str_prepend_if_missing "/etc/hosts" "/"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "/etc/hosts" ]
}

# ---------------------------------------------------------------------------
# str_append
# ---------------------------------------------------------------------------

@test "str_append: appends with default space delimiter" {
  run shellac_run 'include "text/prefix_suffix"; str_append "foo" "bar"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "foo bar" ]
}

@test "str_append: appends with custom delimiter" {
  run shellac_run 'include "text/prefix_suffix"; str_append -d ":" "foo" "bar"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "foo:bar" ]
}

@test "append: alias for str_append" {
  run shellac_run 'include "text/prefix_suffix"; append "foo" "bar"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "foo bar" ]
}

# ---------------------------------------------------------------------------
# str_prepend
# ---------------------------------------------------------------------------

@test "str_prepend: prepends with default space delimiter" {
  run shellac_run 'include "text/prefix_suffix"; str_prepend "bar" "foo"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "bar foo" ]
}

@test "str_prepend: prepends with custom delimiter" {
  run shellac_run 'include "text/prefix_suffix"; str_prepend -d ":" "bar" "foo"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "bar:foo" ]
}

# ---------------------------------------------------------------------------
# prepend (stdin version)
# ---------------------------------------------------------------------------

@test "prepend: prepends string to each stdin line" {
  run shellac_run 'include "text/prefix_suffix"; printf "line1\nline2\n" | prepend "PREFIX"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'PREFIX line1\nPREFIX line2')" ]
}

@test "prepend: custom delimiter for stdin prepend" {
  run shellac_run 'include "text/prefix_suffix"; printf "line1\n" | prepend -d ":" "PRE"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "PRE:line1" ]
}
